import AppIntents
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

    func perform() async throws -> some IntentResult {
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
            uniqueIdentifier: "stacksprint.lesson.\(lesson.id)",
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
