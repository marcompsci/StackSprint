import Combine
import SwiftUI

// MARK: - XP Level

struct XPLevel: Equatable {
    let number: Int
    let name: String
    let icon: String
    let minXP: Int
    let color: Color

    static let all: [XPLevel] = [
        XPLevel(number: 1, name: "Spark",     icon: "bolt.fill",            minXP: 0,    color: .gray),
        XPLevel(number: 2, name: "Coder",     icon: "curlybraces",          minXP: 50,   color: .mint),
        XPLevel(number: 3, name: "Builder",   icon: "hammer.fill",          minXP: 150,  color: .blue),
        XPLevel(number: 4, name: "Hacker",    icon: "terminal.fill",        minXP: 300,  color: .purple),
        XPLevel(number: 5, name: "Architect", icon: "square.3.layers.3d",   minXP: 500,  color: .orange),
        XPLevel(number: 6, name: "Wizard",    icon: "sparkles",             minXP: 800,  color: .yellow),
        XPLevel(number: 7, name: "Legend",    icon: "crown.fill",           minXP: 1200, color: .pink),
    ]

    static func current(xp: Int) -> XPLevel {
        all.last(where: { xp >= $0.minXP }) ?? all[0]
    }

    static func next(xp: Int) -> XPLevel? {
        all.first(where: { xp < $0.minXP })
    }

    var nextMinXP: Int {
        XPLevel.next(xp: minXP)?.minXP ?? minXP + 400
    }
}

// MARK: - Badge

struct Badge: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: Color
    let check: @Sendable (LearningStore, SocialAuthManager) -> Bool

    func isEarned(store: LearningStore, socialAuth: SocialAuthManager) -> Bool {
        check(store, socialAuth)
    }

    static let all: [Badge] = [
        Badge(id: "first_spark",   name: "First Spark",   description: "Complete your first lesson",        icon: "bolt.fill",                            color: .yellow) { s, _ in !s.completed.isEmpty },
        Badge(id: "on_fire",       name: "On Fire",        description: "Reach a 7-day streak",              icon: "flame.fill",                           color: .orange) { s, _ in s.currentStreak >= 7 },
        Badge(id: "month_strong",  name: "Month Strong",   description: "Reach a 30-day streak",             icon: "trophy.fill",                          color: .yellow) { s, _ in s.currentStreak >= 30 },
        Badge(id: "github_pusher", name: "GitHub Pusher",  description: "Connect your GitHub account",       icon: "chevron.left.forwardslash.chevron.right", color: .white) { _, a in a.authProvider == .github },
        Badge(id: "web_wizard",    name: "Web Wizard",     description: "Complete all Web Dev lessons",      icon: "globe",                                color: .blue)   { s, _ in Badge.allDone(s, "Web development") },
        Badge(id: "python_pro",    name: "Python Pro",     description: "Complete all Python lessons",       icon: "ladybug.fill",                         color: .green)  { s, _ in Badge.allDone(s, "Python") },
        Badge(id: "sec_scout",     name: "Security Scout", description: "Complete all Cybersecurity lessons",icon: "lock.shield.fill",                     color: .red)    { s, _ in Badge.allDone(s, "Cybersecurity") },
        Badge(id: "ts_tinkerer",   name: "TS Tinkerer",    description: "Complete all TypeScript lessons",   icon: "t.square.fill",                        color: .blue)   { s, _ in Badge.allDone(s, "TypeScript") },
        Badge(id: "react_ranger",  name: "React Ranger",   description: "Complete all React lessons",        icon: "atom",                                 color: .cyan)   { s, _ in Badge.allDone(s, "React") },
        Badge(id: "swift_starter", name: "Swift Starter",  description: "Complete all Swift lessons",        icon: "swift",                                color: .orange) { s, _ in Badge.allDone(s, "Swift") },
        Badge(id: "half_stack",    name: "Half Stack",     description: "Complete 50% of all lessons",       icon: "chart.pie.fill",                       color: .mint)   { s, _ in
            guard let t = s.curriculum?.lessons.count, t > 0 else { return false }
            return s.completed.count * 2 >= t
        },
        Badge(id: "full_sprint",   name: "Full Sprint",    description: "Complete every single lesson",      icon: "checkmark.seal.fill",                  color: .pink)   { s, _ in
            guard let t = s.curriculum?.lessons.count, t > 0 else { return false }
            return s.completed.count >= t
        },
    ]

    private static func allDone(_ store: LearningStore, _ category: String) -> Bool {
        let ids = store.curriculum?.lessons.filter { $0.category == category }.map(\.id) ?? []
        return !ids.isEmpty && ids.allSatisfy { store.completed.contains($0) }
    }
}

// MARK: - Gamification Header (embed in AccountView or LearnView)

struct GamificationHeader: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var socialAuth: SocialAuthManager

    var body: some View {
        let xp = store.practiceXP
        let level = XPLevel.current(xp: xp)
        let nextLevel = XPLevel.next(xp: xp)
        let progress: Double = {
            guard let next = nextLevel else { return 1.0 }
            let span = Double(next.minXP - level.minXP)
            let done = Double(xp - level.minXP)
            return span > 0 ? min(done / span, 1.0) : 1.0
        }()

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(level.color.opacity(0.15)).frame(width: 52, height: 52)
                    Image(systemName: level.icon).font(.title2).foregroundStyle(level.color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Lv \(level.number)").font(.caption.bold().monospaced()).foregroundStyle(level.color)
                        Text(level.name).font(.headline)
                    }
                    Text("\(xp) XP").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if let next = nextLevel {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Next: \(next.name)").font(.caption.bold()).foregroundStyle(.secondary)
                        Text("\(next.minXP - xp) XP to go").font(.caption2).foregroundStyle(.secondary)
                    }
                } else {
                    Label("MAX", systemImage: "crown.fill").font(.caption.bold()).foregroundStyle(.yellow)
                }
            }

            ProgressView(value: progress)
                .tint(level.color)
                .animation(.easeOut(duration: 0.5), value: progress)
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(level.color.opacity(0.25)))
    }
}

// MARK: - Badge Grid

struct BadgeGridSection: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var socialAuth: SocialAuthManager
    @State private var expanded = false

    private var earned: [Badge] { Badge.all.filter { $0.isEarned(store: store, socialAuth: socialAuth) } }
    private var locked: [Badge] { Badge.all.filter { !$0.isEarned(store: store, socialAuth: socialAuth) } }

    var body: some View {
        Section {
            GamificationHeader()
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
        } header: {
            Text("Your rank")
        }

        Section {
            if earned.isEmpty {
                Text("Complete lessons and build streaks to earn badges.")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
                    ForEach(earned) { badge in BadgeCell(badge: badge, earned: true) }
                    if expanded {
                        ForEach(locked) { badge in BadgeCell(badge: badge, earned: false) }
                    }
                }
                .padding(.vertical, 8)

                Button(expanded ? "Hide locked badges" : "Show \(locked.count) locked badges") {
                    withAnimation(.easeOut(duration: 0.2)) { expanded.toggle() }
                }
                .font(.subheadline)
            }
        } header: {
            HStack {
                Text("Badges")
                Spacer()
                Text("\(earned.count) / \(Badge.all.count)").font(.caption.bold()).foregroundStyle(.secondary)
            }
        }
    }
}

private struct BadgeCell: View {
    let badge: Badge
    let earned: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(earned ? badge.color.opacity(0.15) : Color.secondary.opacity(0.08))
                    .frame(width: 48, height: 48)
                Image(systemName: badge.icon)
                    .font(.title3)
                    .foregroundStyle(earned ? badge.color : Color.secondary.opacity(0.4))
            }
            Text(badge.name)
                .font(.caption2.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(earned ? .primary : .secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(earned ? badge.color.opacity(0.06) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(
            earned ? badge.color.opacity(0.25) : Color.secondary.opacity(0.12)))
        .help(badge.description)
    }
}

// MARK: - XP Breakdown (shown in AccountView)

struct XPBreakdownRow: View {
    @EnvironmentObject var store: LearningStore

    var body: some View {
        HStack(spacing: 20) {
            xpPill(value: store.completed.count * 10, label: "lessons", icon: "book.fill", color: .mint)
            xpPill(value: store.correctRecallAnswers.count * 5, label: "recall", icon: "brain.head.profile", color: .purple)
            xpPill(value: store.currentStreak * 2, label: "streak", icon: "flame.fill", color: .orange)
            Spacer()
        }
    }

    private func xpPill(value: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Label("\(value)", systemImage: icon).font(.caption.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
