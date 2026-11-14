import Combine
import SwiftUI

// MARK: - Weekly XP Store

@MainActor final class WeeklyXPStore: ObservableObject {
    static let shared = WeeklyXPStore()

    /// XP actually earned since the week began: 10 per lesson, 5 per quiz answer.
    /// (It used to shrink 5% every time the app opened after a day off, and showed
    /// made-up global rankings.)
    @Published private(set) var weeklyXP: Int = 0
    @Published private(set) var weekStart: Date = .distantPast
    @Published private(set) var previousWeekXP: Int = 0

    private enum Keys {
        static let weeklyXP = "weekly.xp"
        static let weekStart = "weekly.start"
        static let prevXP = "weekly.prevXP"
    }

    init() { load(); checkWeekReset() }

    func recordXP(_ xp: Int) {
        checkWeekReset()
        weeklyXP += max(xp, 0)
        save()
    }

    var daysUntilReset: Int {
        let cal = Calendar.current
        guard let end = cal.dateInterval(of: .weekOfYear, for: Date())?.end else { return 7 }
        return max(1, cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: end).day ?? 7)
    }

    /// Archives last week and starts a new one when the calendar week has changed.
    func checkWeekReset(now: Date = Date()) {
        guard let currentWeekStart = Calendar.current.dateInterval(of: .weekOfYear, for: now)?.start,
              currentWeekStart > weekStart else { return }
        // Only last week's total counts as "last week"; an older total is stale.
        let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)
        previousWeekXP = weekStart == lastWeek ? weeklyXP : 0
        weeklyXP = 0
        weekStart = currentWeekStart
        save()
    }

    private func load() {
        let ud = UserDefaults.standard
        weeklyXP = ud.integer(forKey: Keys.weeklyXP)
        previousWeekXP = ud.integer(forKey: Keys.prevXP)
        if let d = ud.object(forKey: Keys.weekStart) as? Date { weekStart = d }
    }

    private func save() {
        let ud = UserDefaults.standard
        ud.set(weeklyXP, forKey: Keys.weeklyXP)
        ud.set(weekStart, forKey: Keys.weekStart)
        ud.set(previousWeekXP, forKey: Keys.prevXP)
    }
}

// MARK: - Weekly Leaderboard View

struct WeeklyLeaderboardView: View {
    @EnvironmentObject var store: LearningStore
    @ObservedObject var weekly = WeeklyXPStore.shared
    @State private var tab = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                weeklyHeader
                leaderboardTabs
            }
            .padding(20)
        }
        .navigationTitle("This week")
        .navigationBarTitleDisplayMode(.inline)
        .modifier(SprintTheme())
    }

    // MARK: Weekly Header Card

    private var weeklyHeader: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This week").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                    Text("\(weekly.weeklyXP) XP earned").font(.title2.bold())
                    Text("\(weekly.daysUntilReset) day\(weekly.daysUntilReset == 1 ? "" : "s") until reset")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(min(100, weekly.weeklyXP * 100 / 500))%").font(.title3.bold()).foregroundStyle(.yellow)
                    Text("of goal").font(.caption).foregroundStyle(.secondary)
                }
            }
            // Weekly XP progress bar (toward weekly goal of 500 XP)
            let weeklyGoal = 500
            let pct = min(1, Double(weekly.weeklyXP) / Double(weeklyGoal))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08)).frame(height: 8)
                    Capsule().fill(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * pct, height: 8)
                }
            }.frame(height: 8)
            HStack {
                Text("Weekly goal: 500 XP").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(pct * 100))%").font(.caption2.bold()).foregroundStyle(.yellow)
            }
            if weekly.previousWeekXP > 0 {
                HStack(spacing: 6) {
                    Image(systemName: weekly.weeklyXP >= weekly.previousWeekXP ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundStyle(weekly.weeklyXP >= weekly.previousWeekXP ? .mint : .orange)
                    Text("Last week: \(weekly.previousWeekXP) XP")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(18)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Tab

    private var leaderboardTabs: some View {
        VStack(spacing: 14) {
            Label(LeaderboardStore.disclosure, systemImage: "info.circle")
                .font(.caption).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            let entries = LeaderboardStore.globalEntries(playerXP: weekly.weeklyXP)

            ForEach(entries) { entry in
                WeeklyLeaderRow(entry: entry)
            }
        }
    }
}

// MARK: - Weekly Leader Row

private struct WeeklyLeaderRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 14) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor(entry.rank).opacity(0.15))
                    .frame(width: 38, height: 38)
                Text("#\(entry.rank)").font(.system(.footnote, design: .rounded, weight: .bold))
                    .foregroundStyle(rankColor(entry.rank))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.name).font(.subheadline.bold())
                        .foregroundStyle(entry.isYou ? .mint : .primary)
                    if entry.isYou { Text("← You").font(.caption2.bold()).foregroundStyle(.mint) }
                }
                Text("Lv \(entry.level.number) · \(entry.xp) XP").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            // Trending arrow (simulate with rank)
            Image(systemName: entry.rank <= 3 ? "flame.fill" : "arrow.up.right")
                .font(.caption).foregroundStyle(entry.rank <= 3 ? .orange : .secondary)
        }
        .padding(14)
        .background(entry.isYou ? Color.mint.opacity(0.08) : SprintPalette.card,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(entry.isYou ? Color.mint.opacity(0.3) : Color.clear, lineWidth: 1))
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank { case 1: return .yellow; case 2: return .gray; case 3: return Color(red: 0.8, green: 0.5, blue: 0.2); default: return .secondary }
    }
}

// MARK: - Rank Up Banner (animated overlay)

struct RankUpBanner: View {
    let onDismiss: () -> Void
    @State private var offset: CGFloat = -60

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.up.circle.fill").foregroundStyle(.yellow).font(.title3)
            Text("You moved up the leaderboard").font(.subheadline.bold())
            Spacer()
            Button { onDismiss() } label: { Image(systemName: "xmark") }.font(.caption.bold()).foregroundStyle(.secondary).accessibilityLabel("Dismiss")
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .offset(y: offset)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 1)) { offset = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { onDismiss() }
        }
    }
}
