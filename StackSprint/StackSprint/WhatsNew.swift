import SwiftUI

// MARK: - What's new
//
// After an update, returning learners had no way to know Practice works offline,
// lessons forgive curly quotes, or backups exist. This sheet shows once per
// revision of the list, never on a first install.

enum WhatsNew {
    /// Bump when the list below changes.
    static let revision = 1
    static let seenKey = "whatsnew.seenRevision"

    struct Item: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    static let items: [Item] = [
        Item(icon: "brain.head.profile", title: "Practice without AI",
             detail: "Review due lessons, a quick round, and a quiz for every track. Works on every device."),
        Item(icon: "checkmark.circle", title: "Fairer lesson checks",
             detail: "Curly quotes and stray spaces don't count, and the hint shows the line that's different."),
        Item(icon: "snowflake", title: "Streak freezes",
             detail: "Every 7 days in a row earns a freeze that covers one missed day."),
        Item(icon: "arrow.clockwise", title: "Review sessions",
             detail: "Go through every lesson that's due, one after another."),
        Item(icon: "person.2.fill", title: "Real friend challenges",
             detail: "Challenges and Study Room races use real questions, the same for both players."),
        Item(icon: "square.and.arrow.down", title: "Back up your progress",
             detail: "Account → Your progress saves a file you can restore on a new phone."),
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
