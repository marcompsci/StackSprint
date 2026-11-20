import SwiftUI

// MARK: - What's new
//
// After an update, returning learners had no way to know Practice works offline,
// lessons forgive curly quotes, or backups exist. This sheet shows once per
// revision of the list, never on a first install.

enum WhatsNew {
    /// Bump when the list below changes.
    static let revision = 3
    static let seenKey = "whatsnew.seenRevision"

    struct Item: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    static let items: [Item] = [
        Item(icon: "gauge.with.needle", title: "How sure are you?",
             detail: "Quizzes ask how confident you are. Guesses and confident mistakes bring a lesson back sooner."),
        Item(icon: "text.bubble.fill", title: "Explain it back",
             detail: "Write a lesson in your own words and see which key ideas you covered."),
        Item(icon: "shuffle", title: "Mixed review and retests",
             detail: "Practice → Mixed review blends lessons together, and Learn suggests a quick retest a day later."),
        Item(icon: "rosette", title: "Study plans and certificates",
             detail: "Stats → Study plan sets a finish date. Finish a track with strong quiz scores to earn a certificate."),
        Item(icon: "ant.fill", title: "Practice lab",
             detail: "Prompt builder, Check the AI and Bug hunt drills, plus a free sample lesson for each paid track."),
        Item(icon: "checkmark.circle.fill", title: "A quiz after every lesson",
             detail: "Five questions on what matters most. Your score sets when the lesson comes back for review."),
        Item(icon: "brain.head.profile", title: "See what you remember",
             detail: "Stats → Memory shows what's strong, what's fading, and your quiz accuracy week by week."),
        Item(icon: "bell.badge", title: "Reminders that fit your day",
             detail: "Reminders come at the time you usually study and tell you when lessons start to fade."),
        Item(icon: "sparkles", title: "AI Skills and Professional Practice",
             detail: "New tracks on prompting AI safely and on how developers work. Look for them on the Learn tab."),
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
