import SwiftUI

// MARK: - What's new
//
// After an update, returning learners had no way to know Practice works offline,
// lessons forgive curly quotes, or backups exist. This sheet shows once per
// revision of the list, never on a first install.

enum WhatsNew {
    /// Bump when the list below changes.
    static let revision = 6
    static let seenKey = "whatsnew.seenRevision"

    struct Item: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    static let items: [Item] = [
        Item(icon: "line.3.horizontal", title: "Cleaner top bar",
             detail: "The buttons at the top of Learn are now one tidy menu: courses, Bite, lesson generator and light or dark mode."),
        Item(icon: "gamecontroller.fill", title: "Arcade",
             detail: "Practice → Arcade: predict what code prints, decode error messages, match pairs and a 60-second speed round."),
        Item(icon: "hammer.fill", title: "Mini projects",
             detail: "Five small builds that pull several lessons together, from a profile page to securing your own accounts."),
        Item(icon: "heart.text.square.fill", title: "Your why",
             detail: "Stats → Study plan asks why you're learning. Your reason shows up in reminders, with a suggested place to start."),
        Item(icon: "person.2.fill", title: "Study buddy and exports",
             detail: "Share your week with a friend who'll check in, and export your quiz history as a spreadsheet."),
        Item(icon: "curlybraces.square.fill", title: "Complete the code",
             detail: "Lessons with an example now ask you to fill in a missing word from memory."),
        Item(icon: "point.3.connected.trianglepath.dotted", title: "Connected lessons",
             detail: "Each lesson shows related ones, and \"Teach a friend\" shares a picture card of it."),
        Item(icon: "book.closed.fill", title: "Daily reflection and lesson of the day",
             detail: "One quick question after you study, and a daily flashcard from lessons you've finished."),
        Item(icon: "calendar", title: "Review forecast and tough lessons",
             detail: "Memory shows reviews coming up over two weeks and gives a new approach for lessons that keep slipping."),
        Item(icon: "sparkles", title: "More AI Skills and Professional lessons",
             detail: "AI agents, sources, deepfakes, AI at work and more, plus documentation, dependencies, estimating and incident response."),
    ]

    static func shouldShow(onboarded: Bool, defaults: UserDefaults = .standard) -> Bool {
        onboarded && defaults.integer(forKey: seenKey) < revision
    }

    static func markSeen(defaults: UserDefaults = .standard) { defaults.set(revision, forKey: seenKey) }
}

struct WhatsNewSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(WhatsNew.items) { item in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: item.icon).font(.title3).foregroundStyle(.mint).frame(width: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title).font(.headline)
                            Text(item.detail).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }
            }
            .navigationTitle("What's new")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Continue") { dismiss() } } }
        }
        .onDisappear { WhatsNew.markSeen() }
    }
}
