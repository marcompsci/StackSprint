import SwiftUI

// MARK: - What's new
//
// After an update, returning learners had no way to know Practice works offline,
// lessons forgive curly quotes, or backups exist. This sheet shows once per
// revision of the list, never on a first install.

enum WhatsNew {
    /// Bump when the list below changes.
    static let revision = 5
    static let seenKey = "whatsnew.seenRevision"

    struct Item: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    static let items: [Item] = [
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
        Item(icon: "forward.end.circle.fill", title: "Placement check",
             detail: "Already know some of a track? Take a short check and skip what you know."),
        Item(icon: "character.book.closed.fill", title: "My terms and notes export",
             detail: "Practice → My terms lists every term you've learned, with how well you remember it. Export your notes as a Markdown file."),
        Item(icon: "list.bullet.clipboard", title: "Review every answer",
             detail: "After a quiz, see each question, your answer and how sure you were. Tap the speaker to hear questions read aloud."),
        Item(icon: "target", title: "Smarter Memory",
             detail: "See how often your Sure answers are right, fix mistakes you were sure about, and drill your weakest question type."),
        Item(icon: "timer", title: "Two-minute review and focus timer",
             detail: "A 3-question review for busy days (also in Siri: \"Quick review in StackSprint\"), plus a 10, 15 or 25-minute focus timer."),
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
