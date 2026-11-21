import SwiftUI

// MARK: - What's new
//
// After an update, returning learners had no way to know Practice works offline,
// lessons forgive curly quotes, or backups exist. This sheet shows once per
// revision of the list, never on a first install.

enum WhatsNew {
    /// Bump when the list below changes.
    static let revision = 8
    static let seenKey = "whatsnew.seenRevision"

    struct Item: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    static let items: [Item] = [
        Item(icon: "brain.head.profile", title: "Brain dump",
             detail: "Write down everything you remember about a track, then see what you recalled and what to review."),
        Item(icon: "checkmark.shield.fill", title: "Solid lessons",
             detail: "A lesson becomes solid after strong quiz scores on 3 different days. Memory shows how many you have."),
        Item(icon: "calendar.badge.checkmark", title: "Week in review",
             detail: "A 10-question quiz on everything you studied this week, plus a nudge when a certificate is close."),
        Item(icon: "tray.full.fill", title: "My prompts and review drills",
             detail: "Save prompts you build, and practise code review comments and commit messages."),
        Item(icon: "circle.lefthalf.filled", title: "Match system appearance",
             detail: "The menu now offers Light, Dark or Match system."),
        Item(icon: "graduationcap.fill", title: "Checkpoints and final exams",
             detail: "Practice → Study tools: test four lessons at a time, then the whole track. Pass at 80%."),
        Item(icon: "lightbulb.fill", title: "Hints",
             detail: "Stuck on a quiz question? Ask for a hint. A hinted answer brings the lesson back a little sooner."),
        Item(icon: "doc.text.fill", title: "Cheat sheets and a bookmarks quiz",
             detail: "Turn a track into a one-page PDF, and quiz yourself on the lessons you bookmarked."),
        Item(icon: "leaf.fill", title: "Calm mode and colour-blind colours",
             detail: "Hide XP and streak counts after quizzes, or show right and wrong in blue and orange."),
        Item(icon: "cup.and.saucer.fill", title: "Break reminders and more lessons",
             detail: "A nudge to rest after 25 minutes, plus 8 new paid lessons, 10 more code puzzles and 2 new mini projects."),
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
