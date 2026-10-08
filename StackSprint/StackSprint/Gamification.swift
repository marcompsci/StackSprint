import Combine
import SwiftUI

// MARK: - XP Level

struct XPLevel: Equatable, Identifiable {
    var id: Int { number }
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
