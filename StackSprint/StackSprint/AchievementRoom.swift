import Combine
import SwiftUI

// MARK: - Achievement Model

enum AchievementRarity: String, Codable, Comparable {
    case bronze, silver, gold, diamond

    static func < (lhs: AchievementRarity, rhs: AchievementRarity) -> Bool {
        let order: [AchievementRarity] = [.bronze, .silver, .gold, .diamond]
        return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
    }

    var color: Color {
        switch self {
        case .bronze:  return Color(red: 0.80, green: 0.50, blue: 0.20)
        case .silver:  return Color(red: 0.75, green: 0.75, blue: 0.80)
        case .gold:    return Color(red: 1.00, green: 0.84, blue: 0.20)
        case .diamond: return Color(red: 0.60, green: 0.90, blue: 1.00)
        }
    }

    var label: String { rawValue.capitalized }
    var xpReward: Int {
        switch self { case .bronze: return 50; case .silver: return 150; case .gold: return 400; case .diamond: return 1000 }
    }
}

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let rarity: AchievementRarity
    var isUnlocked: Bool = false
    var unlockedDate: Date?
}

// MARK: - Achievement Context

struct AchievementContext {
    var completedLessons: Int
    var streak: Int
    var correctRecalls: Int
    var practiceXP: Int
    var seasonTier: Int
    var customLessonsCount: Int
    var curriculum: Curriculum?
    var hourOfDay: Int
}

// MARK: - Achievement Store

@MainActor final class AchievementStore: ObservableObject {
    static let shared = AchievementStore()

    @Published private(set) var achievements: [Achievement] = allAchievements
    @Published var latestUnlock: Achievement?

    private static let key = "ss.achievements"

    init() { load() }

    var unlocked: [Achievement] { achievements.filter(\.isUnlocked) }
    var locked:   [Achievement] { achievements.filter { !$0.isUnlocked } }
    var totalXPEarned: Int { unlocked.reduce(0) { $0 + $1.rarity.xpReward } }

    // MARK: Check conditions against current app state

    func check(context: AchievementContext) {
        var updated = false
        for i in achievements.indices {
            guard !achievements[i].isUnlocked else { continue }
            if Self.condition(for: achievements[i].id, context: context) {
                achievements[i].isUnlocked = true
                achievements[i].unlockedDate = .now
                latestUnlock = achievements[i]
                updated = true
                HapticManager.shared.notification(.success)
            }
        }
        if updated { save() }
    }

    // MARK: - Condition Evaluator

    private static func condition(for id: String, context: AchievementContext) -> Bool {
        let c = context
        switch id {
        // Learner
        case "first-spark":        return c.completedLessons >= 1
        case "on-a-roll":          return c.completedLessons >= 10
        case "halfway-sprint":     return c.completedLessons >= 25
        case "code-veteran":       return c.completedLessons >= 50
        case "century-club":       return c.completedLessons >= 100
        case "sprint-master":      return completedAll(context: c)
        // Streak
        case "keep-it-up":         return c.streak >= 3
        case "week-warrior":       return c.streak >= 7
        case "fortnight-fire":     return c.streak >= 14
        case "month-master":       return c.streak >= 30
        case "centurion-streak":   return c.streak >= 100
        // Recall
        case "memory-test":        return c.correctRecalls >= 1
        case "sharp-mind":         return c.correctRecalls >= 10
        case "recall-pro":         return c.correctRecalls >= 50
        case "photographic":       return c.correctRecalls >= 100
        // XP
        case "thousand-xp":        return c.practiceXP >= 1_000
        case "five-thousand-xp":   return c.practiceXP >= 5_000
        // AI
        case "ai-apprentice":      return c.customLessonsCount >= 1
        case "ai-scholar":         return c.customLessonsCount >= 5
        // Season
        case "season-pioneer":     return c.seasonTier >= 5
        case "season-champion":    return c.seasonTier >= 10
        // Time-based
        case "night-owl":          return c.hourOfDay >= 22 && c.completedLessons >= 1
        case "early-bird":         return c.hourOfDay < 7 && c.completedLessons >= 1
        // Misc
        case "xp-rich":            return c.practiceXP >= 10_000
        default:                   return false
        }
    }

    private static func completedAll(context: AchievementContext) -> Bool {
        guard let curriculum = context.curriculum, !curriculum.lessons.isEmpty else { return false }
        return context.completedLessons >= curriculum.lessons.count
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.key),
              let saved = try? JSONDecoder().decode([Achievement].self, from: data)
        else { return }
        var base = Self.allAchievements
        for saved in saved where saved.isUnlocked {
            if let i = base.firstIndex(where: { $0.id == saved.id }) {
                base[i].isUnlocked = true
                base[i].unlockedDate = saved.unlockedDate
            }
        }
        achievements = base
    }

    private func save() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    // MARK: - Achievement Catalog

    static let allAchievements: [Achievement] = [
        // Learner
        Achievement(id: "first-spark",      title: "First Spark",      description: "Complete your first lesson",               icon: "⚡️", rarity: .bronze),
        Achievement(id: "on-a-roll",        title: "On a Roll",        description: "Complete 10 lessons",                      icon: "🔥", rarity: .bronze),
        Achievement(id: "halfway-sprint",   title: "Halfway Sprint",   description: "Complete 25 lessons",                      icon: "🏃", rarity: .silver),
        Achievement(id: "code-veteran",     title: "Code Veteran",     description: "Complete 50 lessons",                      icon: "🎖️", rarity: .silver),
        Achievement(id: "century-club",     title: "Century Club",     description: "Complete 100 lessons",                     icon: "💯", rarity: .gold),
        Achievement(id: "sprint-master",    title: "Sprint Master",    description: "Complete every lesson in the curriculum",  icon: "🏆", rarity: .diamond),
        // Streak
        Achievement(id: "keep-it-up",       title: "Keep It Up",       description: "Build a 3-day streak",                     icon: "📅", rarity: .bronze),
        Achievement(id: "week-warrior",     title: "Week Warrior",     description: "Build a 7-day streak",                     icon: "📆", rarity: .silver),
        Achievement(id: "fortnight-fire",   title: "Fortnight Fire",   description: "Build a 14-day streak",                    icon: "🌋", rarity: .silver),
        Achievement(id: "month-master",     title: "Month Master",     description: "Build a 30-day streak",                    icon: "🌙", rarity: .gold),
        Achievement(id: "centurion-streak", title: "Centurion",        description: "Build a 100-day streak",                   icon: "👑", rarity: .diamond),
        // Recall
        Achievement(id: "memory-test",      title: "Memory Test",      description: "Get your first correct recall",            icon: "🧠", rarity: .bronze),
        Achievement(id: "sharp-mind",       title: "Sharp Mind",       description: "Get 10 correct recall answers",            icon: "🎯", rarity: .bronze),
        Achievement(id: "recall-pro",       title: "Recall Pro",       description: "Get 50 correct recall answers",            icon: "💡", rarity: .silver),
        Achievement(id: "photographic",     title: "Photographic",     description: "Get 100 correct recall answers",           icon: "📸", rarity: .gold),
        // XP
        Achievement(id: "thousand-xp",      title: "1K Club",          description: "Earn 1,000 XP",                            icon: "🪙", rarity: .bronze),
        Achievement(id: "five-thousand-xp", title: "5K Grinder",       description: "Earn 5,000 XP",                            icon: "💎", rarity: .silver),
        Achievement(id: "xp-rich",          title: "XP Rich",          description: "Earn 10,000 total XP",                     icon: "💰", rarity: .gold),
        // AI
        Achievement(id: "ai-apprentice",    title: "AI Apprentice",    description: "Generate your first AI lesson",            icon: "✨", rarity: .bronze),
        Achievement(id: "ai-scholar",       title: "AI Scholar",       description: "Generate 5 AI-powered lessons",            icon: "🤖", rarity: .silver),
        // Season
        Achievement(id: "season-pioneer",   title: "Season Pioneer",   description: "Reach Season Tier 5",                      icon: "🌟", rarity: .gold),
        Achievement(id: "season-champion",  title: "Season Champion",  description: "Max out the Season Battle Pass (Tier 10)", icon: "🎖️", rarity: .diamond),
        // Time-based
        Achievement(id: "night-owl",        title: "Night Owl",        description: "Practice after 10 PM",                     icon: "🦉", rarity: .bronze),
        Achievement(id: "early-bird",       title: "Early Bird",       description: "Practice before 7 AM",                     icon: "🐦", rarity: .bronze),
    ]
}

// MARK: - Trophy Room View

struct TrophyRoomView: View {
    @ObservedObject var store = AchievementStore.shared
    @State private var filterRarity: AchievementRarity? = nil

    private var filtered: [Achievement] {
        guard let r = filterRarity else { return store.achievements }
        return store.achievements.filter { $0.rarity == r }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                statsHeader
                rarityFilter
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                    ForEach(filtered) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Trophy Room")
        .navigationBarTitleDisplayMode(.inline)
        .modifier(SprintTheme())
    }

    private var statsHeader: some View {
        HStack(spacing: 0) {
            statBlock("\(store.unlocked.count)/\(store.achievements.count)", label: "Unlocked")
            Divider().padding(.vertical, 12)
            statBlock("\(store.totalXPEarned)", label: "Bonus XP")
            Divider().padding(.vertical, 12)
            statBlock(topRarityLabel, label: "Top Rarity")
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private func statBlock(_ value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var topRarityLabel: String {
        store.unlocked.max(by: { $0.rarity < $1.rarity })?.rarity.label ?? "—"
    }

    private var rarityFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", color: .mint, isSelected: filterRarity == nil) { filterRarity = nil }
                ForEach([AchievementRarity.bronze, .silver, .gold, .diamond], id: \.self) { r in
                    FilterChip(label: r.label, color: r.color, isSelected: filterRarity == r) { filterRarity = r }
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

private struct FilterChip: View {
    let label: String; let color: Color; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.subheadline.bold())
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(isSelected ? color.opacity(0.2) : SprintPalette.card, in: Capsule())
                .foregroundStyle(isSelected ? color : .secondary)
                .overlay(Capsule().strokeBorder(isSelected ? color.opacity(0.5) : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement
    @State private var glowing = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                if achievement.isUnlocked {
                    Circle().fill(achievement.rarity.color.opacity(0.15)).frame(width: 60, height: 60)
                    if glowing {
                        Circle().stroke(achievement.rarity.color.opacity(0.4), lineWidth: 2)
                            .frame(width: 66, height: 66)
                            .scaleEffect(glowing ? 1.1 : 1)
                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glowing)
                    }
                } else {
                    Circle().fill(Color.white.opacity(0.05)).frame(width: 60, height: 60)
                }
                Text(achievement.icon).font(.system(size: 28))
                    .opacity(achievement.isUnlocked ? 1 : 0.25)
            }
            VStack(spacing: 3) {
                Text(achievement.title).font(.subheadline.bold())
                    .multilineTextAlignment(.center).lineLimit(2)
                    .foregroundStyle(achievement.isUnlocked ? .primary : .tertiary)
                Text(achievement.rarity.label).font(.caption2.bold())
                    .foregroundStyle(achievement.isUnlocked ? achievement.rarity.color : Color.white.opacity(0.2))
                if !achievement.isUnlocked {
                    Text(achievement.description).font(.caption2).foregroundStyle(Color.white.opacity(0.2))
                        .multilineTextAlignment(.center).lineLimit(2)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            SprintPalette.card,
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    achievement.isUnlocked ? achievement.rarity.color.opacity(0.35) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .onAppear { if achievement.isUnlocked { glowing = true } }
        .accessibilityLabel("\(achievement.title), \(achievement.rarity.label). \(achievement.isUnlocked ? "Unlocked" : "Locked: \(achievement.description)")")
    }
}

// MARK: - Achievement Unlock Overlay

struct AchievementUnlockOverlay: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 20) {
                Text("Achievement Unlocked!").font(.caption.bold()).tracking(2)
                    .foregroundStyle(achievement.rarity.color)

                ZStack {
                    Circle().fill(achievement.rarity.color.opacity(0.2)).frame(width: 100, height: 100)
                    Text(achievement.icon).font(.system(size: 52))
                }

                VStack(spacing: 6) {
                    Text(achievement.title).font(.title2.bold())
                    Text(achievement.description).font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Text("+\(achievement.rarity.xpReward) XP").font(.headline.bold())
                        .foregroundStyle(achievement.rarity.color)
                        .padding(.horizontal, 18).padding(.vertical, 6)
                        .background(achievement.rarity.color.opacity(0.15), in: Capsule())
                }

                Button("Awesome!") { dismiss() }
                    .buttonStyle(.borderedProminent).tint(achievement.rarity.color)
            }
            .padding(30)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
            .padding(32)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    scale = 1; opacity = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) { dismiss() }
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) { opacity = 0; scale = 0.8 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onDismiss() }
    }
}
