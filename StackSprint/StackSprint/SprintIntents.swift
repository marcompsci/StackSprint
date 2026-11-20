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

struct QuickReviewIntent: AppIntent {
    static let title: LocalizedStringResource = "Two-Minute Review"
    static let description = IntentDescription(
        "Open StackSprint for a 3-question review of your due and recent lessons.",
        categoryName: "Learning"
    )
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        LessonRouter.shared.openQuickReview()
        return .result()
    }
}

/// The two-minute review opened from Siri or Shortcuts.
struct QuickReviewSheet: View {
    let locked: Set<String>
    @EnvironmentObject var store: LearningStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let questions = QuickReviewBuilder.questions(store: store, locked: locked)
        if questions.isEmpty {
            NavigationStack {
                ContentUnavailableView("Nothing to review yet", systemImage: "checkmark.seal",
                                       description: Text("Finish a couple of lessons first, then quick reviews will be ready."))
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            }
        } else {
            LessonQuizView(lesson: nil, questions: questions, title: "Two-minute review") { result in
                for missed in result.missed { AdaptiveEngine.shared.recordWrong(missed.id) }
                store.recordPractice()
            }
        }
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
        AppShortcut(
            intent: QuickReviewIntent(),
            phrases: [
                "Quick review in \(.applicationName)",
                "Start a two-minute review in \(.applicationName)"
            ],
            shortTitle: "Two-Minute Review",
            systemImageName: "timer"
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

/// Indexing all lessons on every launch was wasted work; only redo it when the lessons change.
@MainActor func indexLessonsInSpotlightIfChanged(_ lessons: [Lesson]) {
    let signature = SpotlightSignature.of(lessons)
    let key = "spotlight.signature"
    guard UserDefaults.standard.string(forKey: key) != signature else { return }
    indexLessonsInSpotlight(lessons)
    UserDefaults.standard.set(signature, forKey: key)
}

enum SpotlightSignature {
    /// A stable fingerprint of what Spotlight shows for each lesson.
    static func of(_ lessons: [Lesson]) -> String {
        var hash: UInt64 = 0xcbf29ce484222325
        for lesson in lessons {
            for byte in "\(lesson.id)|\(lesson.term)|\(lesson.definition)|\(lesson.category)\n".utf8 {
                hash = (hash ^ UInt64(byte)) &* 0x100000001b3
            }
        }
        return "\(lessons.count)-\(String(hash, radix: 16))"
    }
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
        case quickReview
        var id: String {
            switch self {
            case .lesson(let id): return "lesson-\(id)"
            case .continueLearning: return "continue"
            case .quickReview: return "quick-review"
            }
        }
    }

    @Published var request: Request?

    func openContinue() { request = .continueLearning }
    func openQuickReview() { request = .quickReview }

    func open(spotlightIdentifier: String) {
        guard spotlightIdentifier.hasPrefix(Self.spotlightPrefix) else { return }
        request = .lesson(String(spotlightIdentifier.dropFirst(Self.spotlightPrefix.count)))
    }
}

struct RoutedLessonSheet: View {
    let request: LessonRouter.Request
    let locked: Set<String>
    let preferredTrack: String
    @EnvironmentObject var store: LearningStore
    @Environment(\.dismiss) private var dismiss

    private var lessons: [Lesson] { store.curriculum?.lessons ?? [] }
    private var lesson: Lesson? {
        switch request {
        case .lesson(let id): return lessons.first { $0.id == id }
        case .quickReview:
            return nil
        case .continueLearning:
            let due = SM2Engine.shared.dueCards(in: lessons).first { !locked.contains($0.category) }
            return due ?? LessonFlow.continueLesson(in: lessons, completed: store.completed,
                                                    preferredTrack: preferredTrack, locked: locked,
                                                    known: PlacementStore.shared.known)
        }
    }

    var body: some View {
        if request == .quickReview {
            QuickReviewSheet(locked: locked)
        } else if let lesson, locked.contains(lesson.category) {
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
