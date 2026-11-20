import SwiftUI

// MARK: - What's new
//
// After an update, returning learners had no way to know Practice works offline,
// lessons forgive curly quotes, or backups exist. This sheet shows once per
// revision of the list, never on a first install.

enum WhatsNew {
    /// Bump when the list below changes.
    static let revision = 4
    static let seenKey = "whatsnew.seenRevision"

    struct Item: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    static let items: [Item] = [
        Item(icon: "forward.end.circle.fill", title: "Placement check",
             detail: "Already know some of a track? Take a short check and skip what you know."),
        Item(icon: "character.book.closed.fill", title: "Glossary and notes export",
             detail: "Practice → Glossary lists every term you've learned. Export your notes as a Markdown file."),
        Item(icon: "list.bullet.clipboard", title: "Review every answer",
             detail: "After a quiz, see each question, your answer and how sure you were. Tap the speaker to hear questions read aloud."),
        Item(icon: "target", title: "Smarter Memory",
             detail: "See how often your Sure answers are right, fix mistakes you were sure about, and drill your weakest question type."),
        Item(icon: "timer", title: "Two-minute review and focus timer",
             detail: "A 3-question review for busy days (also in Siri: \"Quick review in StackSprint\"), plus a 10, 15 or 25-minute focus timer."),
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
