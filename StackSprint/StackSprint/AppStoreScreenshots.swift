import SwiftUI

// MARK: - App Store Metadata
// This file centralizes App Store submission assets.
// Run each ScreenshotPreview in an Xcode Preview at the target device size,
// then use Simulator → File → Save Screen to capture the screenshot.

// MARK: App Store Copy

enum AppStoreCopy {
    static let name = "StackSprint"
    static let subtitle = "Code. Sprint. Level up."
    static let description = """
    StackSprint turns coding education into a daily habit. \
    Practice bite-sized lessons in Python, Swift, TypeScript, React, Go, Rust, \
    and Interview Prep — then test your recall with an adaptive quiz engine \
    that focuses on your weak spots.

    LEARN YOUR WAY
    • 104 bite-sized lessons across 9 programming tracks
    • Flip-card review with spaced repetition (SM-2 algorithm)
    • Interactive code editor with live run for JS and Python
    • AI Tutor (Bit) powered by on-device FoundationModels

    STAY MOTIVATED
    • Daily streaks and XP leaderboard
    • Weekly challenges with XP Weekend double-boost events
    • Celebration animations for milestones and streak records
    • Home screen widgets: streak counter and next lesson

    GO PRO
    • Unlock Go, Rust, and Interview Prep tracks
    • Unlimited AI Tutor sessions
    • Pro crown on the global leaderboard

    SEAMLESS & PRIVATE
    • iCloud sync across all your devices
    • Full offline support — all content on device
    • No ads, no tracking, no account required to start
    • VoiceOver, Dynamic Type, and Reduce Motion supported
    """

    static let keywords = [
        "coding", "programming", "learn swift", "python tutorial",
        "typescript", "react", "developer", "code practice",
        "flashcard", "spaced repetition", "interview prep",
        "go lang", "rust programming", "daily streak", "xp"
    ].joined(separator: ", ")

    static let promotionalText = "New: Go & Rust tracks, AI Tutor, and spaced repetition!"

    static let supportURL = "https://stacksprint.app/support"
    static let privacyURL = "https://stacksprint.app/privacy"
    static let marketingURL = "https://stacksprint.app"
}

// MARK: - Screenshot Preview Views
// Each struct renders a self-contained "screenshot frame" ready for App Store submission.

struct ScreenshotHero: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.12, blue: 0.22), Color(red: 0.03, green: 0.07, blue: 0.15)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()
                VStack(spacing: 16) {
                    Text("STACKSPRINT")
                        .font(.system(.caption, design: .monospaced, weight: .heavy))
                        .tracking(6).foregroundStyle(.mint)
                    Text("Code.\nSprint.\nLevel up.")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                    Text("104 lessons · 9 tracks · AI Tutor on-device")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.7))
                }
                ScreenshotMockLessonCard()
                Spacer()
                Text("No tracking. No ads. No account required.")
                    .font(.caption).foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 32)
        }
    }
}

private struct ScreenshotMockLessonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("SWIFT", systemImage: "swift").font(.caption.bold()).foregroundStyle(.orange)
                Spacer()
                Text("Beginner").font(.caption2).padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.orange.opacity(0.15), in: Capsule())
                    .foregroundStyle(.orange)
            }
            Text("Optional").font(.title2.bold())
            Text("A type that represents either a wrapped value or nil.")
                .font(.subheadline).foregroundStyle(.secondary)
            Text("var name: String? = nil").font(.system(.body, design: .monospaced))
                .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(20)
        .background(Color(red: 0.09, green: 0.14, blue: 0.24), in: RoundedRectangle(cornerRadius: 22))
    }
}

struct ScreenshotLeaderboard: View {
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.12, blue: 0.22).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Global Leaderboard").font(.title2.bold()).foregroundStyle(.white)
                    .padding(.top, 40)
                ForEach(mockLeaders, id: \.name) { entry in
                    ScreenshotLeaderRow(rank: entry.rank, name: entry.name, xp: entry.xp, isYou: entry.isYou)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }

    private struct Leader { let rank: Int; let name: String; let xp: Int; let isYou: Bool }
    private let mockLeaders = [
        Leader(rank: 1, name: "CodeNinja", xp: 4200, isYou: false),
        Leader(rank: 2, name: "Swiftly", xp: 3850, isYou: false),
        Leader(rank: 3, name: "You", xp: 3510, isYou: true),
        Leader(rank: 4, name: "PyDev", xp: 3290, isYou: false),
        Leader(rank: 5, name: "ByteMe", xp: 2980, isYou: false),
    ]
}

private struct ScreenshotLeaderRow: View {
    let rank: Int; let name: String; let xp: Int; let isYou: Bool
    var body: some View {
        HStack {
            Text("#\(rank)").font(.headline.bold()).frame(width: 40)
                .foregroundStyle(rank <= 3 ? Color.yellow : .secondary)
            Text(name).font(.headline).foregroundStyle(isYou ? .mint : .white)
            if isYou { Text("← You").font(.caption.bold()).foregroundStyle(.mint) }
            Spacer()
            Text("\(xp) XP").font(.subheadline.bold()).foregroundStyle(.secondary)
        }
        .padding(14)
        .background(isYou ? Color.mint.opacity(0.1) : Color.white.opacity(0.04),
                    in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Screenshot Previews

#Preview("Screenshot 1 – Hero") {
    ScreenshotHero()
}

#Preview("Screenshot 2 – Leaderboard") {
    ScreenshotLeaderboard()
}
