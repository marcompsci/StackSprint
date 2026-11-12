import SwiftUI

// MARK: - Leaderboard Entry

struct LeaderboardEntry: Identifiable {
    let id: String
    let name: String
    let xp: Int
    let isYou: Bool
    var rank: Int = 0
    var level: XPLevel { XPLevel.current(xp: xp) }
}

// MARK: - Pacers
//
// There is no online leaderboard yet. Instead of inventing players, the board
// shows computer "pacers": XP marks set around your own level, clearly labelled
// as not real people.

enum LeaderboardStore {
    static let disclosure = "Pacers are computer-set XP marks around your level. They aren’t real players."
    private static let globalNames = (1...15).map { "Pacer \($0)" }

    static func globalEntries(playerXP: Int) -> [LeaderboardEntry] {
        let base = max(playerXP, 20)
        var entries = globalNames.enumerated().map { i, name in
            let offset = (i * 23 + 7) % 180 - 60
            return LeaderboardEntry(id: "g-\(i)", name: name, xp: max(0, base + offset), isYou: false)
        }
        entries.append(LeaderboardEntry(id: "you", name: "You", xp: playerXP, isYou: true))
        return ranked(entries)
    }

    private static func ranked(_ entries: [LeaderboardEntry]) -> [LeaderboardEntry] {
        entries.sorted { $0.xp > $1.xp }.enumerated().map { idx, e in
            var e = e; e.rank = idx + 1; return e
        }
    }
}

// MARK: - Leaderboard View

struct LeaderboardView: View {
    @EnvironmentObject var store: LearningStore

    var body: some View {
        let xp = store.practiceXP
        let entries = LeaderboardStore.globalEntries(playerXP: xp)
        let myRank = entries.first(where: \.isYou)?.rank ?? 0

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                leaderboardHeader(xp: xp, rank: myRank)


                if entries.count >= 3 {
                    podiumView(Array(entries.prefix(3)))
                }

                VStack(spacing: 8) {
                    ForEach(entries.dropFirst(3)) { entry in
                        LeaderboardRow(entry: entry)
                    }
                }

                ShareLink(item: "I\u{2019}ve earned \(xp) XP in StackSprint. Want to race me?") {
                    Label("Challenge a friend", systemImage: "person.badge.plus")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent).tint(.mint)
            }
            .padding(20)
        }
        .navigationTitle("Pacers")
        .modifier(SprintTheme())
    }

    private func leaderboardHeader(xp: Int, rank: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pacers").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            Text("Race the pacers").font(.title2.bold())
            if rank > 0 {
                Text("You\u{2019}re #\(rank) of 16 with \(xp) XP").font(.subheadline).foregroundStyle(.secondary)
            }
            Label(LeaderboardStore.disclosure, systemImage: "info.circle")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func podiumView(_ top: [LeaderboardEntry]) -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            PodiumColumn(entry: top[1], medal: "2", barHeight: 68)
            PodiumColumn(entry: top[0], medal: "1", barHeight: 92)
            PodiumColumn(entry: top[2], medal: "3", barHeight: 52)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Podium Column

private struct PodiumColumn: View {
    let entry: LeaderboardEntry
    let medal: String
    let barHeight: CGFloat

    var body: some View {
        VStack(spacing: 6) {
            Text(medal).font(.headline.monospacedDigit()).frame(width: 30, height: 30).background(.tint.opacity(0.18), in: Circle())
            Text(entry.name)
                .font(.caption.bold()).multilineTextAlignment(.center).lineLimit(2)
                .foregroundStyle(entry.isYou ? .mint : .primary)
            Text("\(entry.xp) XP").font(.caption2.monospaced()).foregroundStyle(.secondary)
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(entry.isYou ? Color.mint.opacity(0.2) : SprintPalette.card)
                    .frame(height: barHeight)
                Image(systemName: entry.level.icon)
                    .foregroundStyle(entry.level.color).font(.body.bold())
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Leaderboard Row

private struct LeaderboardRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 12) {
            Text("#\(entry.rank)")
                .font(.system(.caption, design: .monospaced).bold())
                .frame(width: 32, alignment: .trailing).foregroundStyle(.secondary)
            ZStack {
                Circle().fill(entry.level.color.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: entry.level.icon).font(.caption.bold()).foregroundStyle(entry.level.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name).font(.subheadline.bold())
                    .foregroundStyle(entry.isYou ? .mint : .primary)
                Text("Lv \(entry.level.number) \u{B7} \(entry.xp) XP").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if entry.isYou {
                Text("You").font(.caption.bold()).foregroundStyle(.mint)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.mint.opacity(0.12), in: Capsule())
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(entry.isYou ? Color.mint.opacity(0.07) : SprintPalette.card,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(entry.isYou ? Color.mint.opacity(0.25) : Color.clear))
    }
}
