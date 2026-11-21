import SwiftUI

// MARK: - What's new
//
// After an update, returning learners had no way to know Practice works offline,
// lessons forgive curly quotes, or backups exist. This sheet shows once per
// revision of the list, never on a first install.

enum WhatsNew {
    /// Bump when the list below changes.
    static let revision = 9
    static let seenKey = "whatsnew.seenRevision"

    struct Item: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    static let items: [Item] = [
        Item(icon: "cylinder.split.1x2", title: "New free track: SQL & Data",
             detail: "Ten lessons on tables, SELECT, WHERE, JOIN, GROUP BY and writing safe queries."),
        Item(icon: "headphones", title: "Listen & recall",
             detail: "Hands-free review: hear a clue, answer in your head, then hear the answer. Great for walks."),
        Item(icon: "tortoise.fill", title: "How did it feel?",
             detail: "Rate each lesson Easy, OK or Hard. Hard ones come back tomorrow and go first in reviews."),
        Item(icon: "map.fill", title: "Your first week",
             detail: "New learners get a short checklist of the habits that help most in the first days."),
        Item(icon: "clock.fill", title: "Your best study time",
             detail: "Memory shows the part of the day when your quiz scores are highest."),
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
