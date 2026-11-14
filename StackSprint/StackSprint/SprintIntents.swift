import AppIntents
import Combine
import CoreSpotlight
import SwiftUI

// MARK: - App Intents (Siri Shortcuts)

struct StartDailySprintIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Daily Sprint"
    static let description = IntentDescription(
        "Open StackSprint and begin today's coding sprint.",
        categoryName: "Learning"
    )
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        LessonRouter.shared.openContinue()
        return .result()
    }
}

struct StackSprintShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartDailySprintIntent(),
            phrases: [
                "Start my \(.applicationName) sprint",
                "Open \(.applicationName)",
                "Begin my \(.applicationName) practice"
            ],
            shortTitle: "Daily Sprint",
            systemImageName: "bolt.fill"
        )
    }
}

// MARK: - Spotlight Indexing

func indexLessonsInSpotlight(_ lessons: [Lesson]) {
    let items: [CSSearchableItem] = lessons.map { lesson in
        let attrs = CSSearchableItemAttributeSet(contentType: .text)
        attrs.title = lesson.term
        attrs.contentDescription = lesson.definition
        attrs.keywords = [lesson.category, "coding", "programming", "learn", "StackSprint", lesson.clue]
        let item = CSSearchableItem(
            uniqueIdentifier: LessonRouter.spotlightPrefix + lesson.id,
            domainIdentifier: "com.stacksprint.lessons",
            attributeSet: attrs
        )
        item.expirationDate = .distantFuture
        return item
    }
    CSSearchableIndex.default().indexSearchableItems(items) { _ in }
}

func deindexAllLessons() {
    CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: ["com.stacksprint.lessons"]) { _ in }
}

// MARK: - Opening a lesson from outside the app

/// Spotlight results and the Daily Sprint shortcut land here; RootView presents the lesson.
@MainActor final class LessonRouter: ObservableObject {
    static let shared = LessonRouter()
    static let spotlightPrefix = "stacksprint.lesson."

    enum Request: Identifiable, Equatable {
        case lesson(String)
        case continueLearning
        var id: String {
            switch self {
            case .lesson(let id): return "lesson-\(id)"
            case .continueLearning: return "continue"
            }
        }
    }

    @Published var request: Request?

    func openContinue() { request = .continueLearning }

    func open(spotlightIdentifier: String) {
        guard spotlightIdentifier.hasPrefix(Self.spotlightPrefix) else { return }
        request = .lesson(String(spotlightIdentifier.dropFirst(Self.spotlightPrefix.count)))
    }
}

struct RoutedLessonSheet: View {
    let request: LessonRouter.Request
    let isPro: Bool
    let preferredTrack: String
    @EnvironmentObject var store: LearningStore
    @Environment(\.dismiss) private var dismiss

    private var lessons: [Lesson] { store.curriculum?.lessons ?? [] }
    private var locked: Set<String> { isPro ? [] : PremiumStore.proTracks }
    private var lesson: Lesson? {
        switch request {
        case .lesson(let id): return lessons.first { $0.id == id }
        case .continueLearning:
            let due = SM2Engine.shared.dueCards(in: lessons).first { !locked.contains($0.category) }
            return due ?? LessonFlow.continueLesson(in: lessons, completed: store.completed,
                                                    preferredTrack: preferredTrack, locked: locked)
        }
    }

    var body: some View {
        if let lesson, locked.contains(lesson.category) {
            ProPaywallView()
        } else {
            NavigationStack {
                Group {
                    if let lesson {
                        LessonView(lesson: lesson)
                    } else {
                        ContentUnavailableView("You're all caught up", systemImage: "checkmark.seal",
                                               description: Text("Every lesson you can open is finished and nothing is due for review."))
                    }
                }
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            }
        }
    }
}
