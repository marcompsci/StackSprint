import Combine
import SwiftUI

// MARK: - Confetti Particle

private struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var angle: Double
    var speed: CGFloat
    var size: CGFloat
    var color: Color
    var rotation: Double
    var rotationSpeed: Double
    var opacity: Double = 1
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [Particle] = []
    @State private var running = false

    private let colors: [Color] = [.mint, .orange, .yellow, .pink, .blue, .purple, .green]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60)) { timeline in
            Canvas { ctx, size in
                for p in particles {
                    let rect = CGRect(x: p.x - p.size / 2, y: p.y - p.size / 2,
                                      width: p.size, height: p.size * 1.6)
                    ctx.opacity = p.opacity
                    ctx.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(p.color))
                }
            }
            .onChange(of: timeline.date) { _, _ in step() }
        }
        .allowsHitTesting(false)
        .onAppear { burst() }
    }

    private func burst() {
        particles = (0..<80).map { _ in
            Particle(
                x: CGFloat.random(in: 0.2...0.8) * UIScreen.main.bounds.width,
                y: -20,
                angle: Double.random(in: 60...120),
                speed: CGFloat.random(in: 3...8),
                size: CGFloat.random(in: 6...12),
                color: colors.randomElement() ?? .mint,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -6...6)
            )
        }
        running = true
    }

    private func step() {
        guard running else { return }
        particles = particles.compactMap { p in
            var p = p
            let rad = p.angle * .pi / 180
            p.x += cos(rad) * p.speed
            p.y += sin(rad) * p.speed + 1.2   // gravity
            p.rotation += p.rotationSpeed
            p.opacity -= 0.008
            return p.opacity > 0 ? p : nil
        }
        if particles.isEmpty { running = false }
    }
}

// MARK: - Level Up Sheet

struct LevelUpSheet: View {
    let newLevel: XPLevel
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            SprintPalette.navy.ignoresSafeArea()
            ConfettiView().ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(newLevel.color.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: newLevel.icon)
                        .font(.system(size: 52))
                        .foregroundStyle(newLevel.color)
                }

                VStack(spacing: 10) {
                    Text("LEVEL UP!").font(.caption.bold()).tracking(2).foregroundStyle(newLevel.color)
                    Text(newLevel.name).font(.system(size: 44, weight: .bold, design: .rounded))
                    Text("You reached level \(newLevel.number). Keep building.")
                        .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }

                Button(action: onDismiss) {
                    Text("Let\u{2019}s keep going \u{2192}")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .padding(.horizontal, 32)
                }
                .buttonStyle(.borderedProminent).tint(newLevel.color)
                .padding(.horizontal, 40)

                Spacer()
            }
        }
    }
}

// MARK: - Track Complete Card (sharable)

struct TrackCompleteCard: View {
    let category: String
    let completedCount: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(
                    colors: [SprintPalette.navy, catColor.opacity(0.4)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            VStack(spacing: 16) {
                Image(systemName: catIcon)
                    .font(.system(size: 44))
                    .foregroundStyle(catColor)
                Text(category).font(.system(.title, design: .rounded, weight: .bold))
                Text("All \(completedCount) lessons complete").font(.subheadline).foregroundStyle(.secondary)
                Label("StackSprint", systemImage: "bolt.fill")
                    .font(.caption.bold()).foregroundStyle(.mint)
            }
            .padding(28)
        }
        .frame(width: 280, height: 200)
    }

    private var catColor: Color {
        switch category {
        case "Web development": return .blue
        case "Python":          return .green
        case "Cybersecurity":   return .red
        case "TypeScript":      return .cyan
        case "React":           return .teal
        case "Swift":           return .orange
        default:                return .mint
        }
    }

    private var catIcon: String {
        switch category {
        case "Web development": return "globe"
        case "Python":          return "ladybug.fill"
        case "Cybersecurity":   return "lock.shield.fill"
        case "TypeScript":      return "t.square.fill"
        case "React":           return "atom"
        case "Swift":           return "swift"
        default:                return "checkmark.seal.fill"
        }
    }
}

// MARK: - Track Complete Sheet

struct TrackCompleteSheet: View {
    let category: String
    let completedCount: Int
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            SprintPalette.navy.ignoresSafeArea()
            ConfettiView().ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                TrackCompleteCard(category: category, completedCount: completedCount)

                Text("\(category) complete!")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Every lesson in this track is done. You know this material.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 12) {
                    ShareLink(item: "I just completed all \(completedCount) \(category) lessons in StackSprint! \u{1F3C6}") {
                        Label("Share achievement", systemImage: "square.and.arrow.up")
                            .font(.subheadline.bold())
                    }
                    .buttonStyle(.bordered)

                    Button("Continue", action: onDismiss).buttonStyle(.borderedProminent).tint(.mint)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Streak Record Alert

struct StreakRecordBanner: View {
    let currentStreak: Int
    let previousRecord: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill").font(.title2).foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("New streak record!").font(.headline)
                Text("\(currentStreak) days — your previous best was \(previousRecord).")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            ShareLink(item: "I just hit a \(currentStreak)-day coding streak in StackSprint — my personal record! \u{1F525}") {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .padding(14)
        .background(Color.yellow.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.yellow.opacity(0.3)))
    }
}

// MARK: - Celebration Manager (ObservableObject)

@MainActor final class CelebrationManager: ObservableObject {
    @Published var levelUpSheet: XPLevel?
    @Published var trackCompleteCategory: String?
    @Published var trackCompleteCount: Int = 0
    @Published var showStreakRecord = false
    @Published var streakRecordCount = 0

    private var prevXP = 0
    private var bestStreakKey = "stats.bestStreak"

    func check(store: LearningStore) {
        let xp = store.practiceXP
        let prevLevel = XPLevel.current(xp: prevXP)
        let newLevel  = XPLevel.current(xp: xp)
        if newLevel.number > prevLevel.number && prevXP > 0 {
            levelUpSheet = newLevel
        }
        prevXP = xp

        // Track completion
        let lessons = store.curriculum?.lessons ?? []
        let cats = Set(lessons.map(\.category))
        for cat in cats {
            let ids = lessons.filter { $0.category == cat }.map(\.id)
            if !ids.isEmpty && ids.allSatisfy({ store.completed.contains($0) }) {
                let key = "celebrated.track.\(cat)"
                if !UserDefaults.standard.bool(forKey: key) {
                    UserDefaults.standard.set(true, forKey: key)
                    trackCompleteCategory = cat
                    trackCompleteCount = ids.count
                }
            }
        }

        // Streak record
        let streak = store.currentStreak
        let best   = UserDefaults.standard.integer(forKey: bestStreakKey)
        if streak > best && streak > 0 {
            UserDefaults.standard.set(streak, forKey: bestStreakKey)
            if best > 0 {
                streakRecordCount = streak
                showStreakRecord   = true
            }
        }
    }
}
