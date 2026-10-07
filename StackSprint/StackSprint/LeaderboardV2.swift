import Combine
import SwiftUI

// MARK: - Weekly XP Store

@MainActor final class WeeklyXPStore: ObservableObject {
    static let shared = WeeklyXPStore()

    @Published private(set) var weeklyXP: Int = 0
    @Published private(set) var weekStart: Date = Date()
    @Published private(set) var previousWeekXP: Int = 0
    @Published private(set) var previousRank: Int = 0
    @Published private(set) var currentRank: Int = 0
    @Published var showRankUpBanner = false

    private enum Keys {
        static let weeklyXP      = "weekly.xp"
        static let weekStart     = "weekly.start"
        static let prevXP        = "weekly.prevXP"
        static let prevRank      = "weekly.prevRank"
    }

    static let decayPercent: Double = 0.05  // 5% daily decay if no practice

    init() { load(); checkWeekReset() }

    // MARK: Record XP earned this week

    func recordXP(_ xp: Int) {
        weeklyXP += xp
        let newRank = estimatedRank(xp: weeklyXP)
        if newRank < currentRank && currentRank > 0 {
            showRankUpBanner = true
            HapticManager.shared.notification(.success)
        }
        currentRank = newRank
        save()
    }

    // MARK: Apply daily decay (call once per day when app opens)

    func applyDecayIfNeeded(lastPracticed: Date) {
        let daysSinceLastPractice = Calendar.current.dateComponents([.day], from: lastPracticed, to: .now).day ?? 0
        guard daysSinceLastPractice >= 1 else { return }
        let decayFactor = pow(1.0 - Self.decayPercent, Double(daysSinceLastPractice))
        weeklyXP = max(0, Int(Double(weeklyXP) * decayFactor))
        currentRank = estimatedRank(xp: weeklyXP)
        save()
    }

    // MARK: "Top X%" calculation

    func topPercentLabel(totalXP: Int) -> String {
        let p = estimatedTopPercent(xp: weeklyXP)
        if p <= 1 { return "Top 1%" }
        if p <= 5 { return "Top 5%" }
        if p <= 10 { return "Top 10%" }
        if p <= 25 { return "Top 25%" }
        return "Top 50%"
    }

    var daysUntilReset: Int {
        let cal = Calendar.current
        let nextMonday = cal.nextDate(after: Date(), matching: DateComponents(weekday: 2), matchingPolicy: .nextTime) ?? Date()
        return cal.dateComponents([.day], from: .now, to: nextMonday).day ?? 7
    }

    // MARK: - Helpers (simulate a global distribution)

    private func estimatedRank(xp: Int) -> Int {
        // Rough global simulation: rank 1 ≈ 5000+ weekly XP
        let base = max(xp, 0)
        return max(1, Int(5000.0 / Double(base + 1)))
    }

    private func estimatedTopPercent(xp: Int) -> Int {
        switch xp {
        case 5000...: return 1
        case 2000...: return 5
        case 1000...: return 10
        case 500...:  return 25
        default:      return 50
        }
    }

    // MARK: - Reset logic

    private func checkWeekReset() {
        let cal = Calendar.current
        let storedWeekStart = weekStart
        let currentWeekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)) ?? .now
        guard currentWeekStart > storedWeekStart else { return }
        // New week — archive last week's XP
        previousWeekXP = weeklyXP
        previousRank = currentRank
        weeklyXP = 0
        weekStart = currentWeekStart
        currentRank = 0
        save()
    }

    // MARK: Persistence

    private func load() {
        let ud = UserDefaults.standard
        weeklyXP     = ud.integer(forKey: Keys.weeklyXP)
        previousWeekXP = ud.integer(forKey: Keys.prevXP)
        previousRank = ud.integer(forKey: Keys.prevRank)
        if let d = ud.object(forKey: Keys.weekStart) as? Date { weekStart = d }
        currentRank = estimatedRank(xp: weeklyXP)
    }

    private func save() {
        let ud = UserDefaults.standard
        ud.set(weeklyXP,        forKey: Keys.weeklyXP)
        ud.set(weekStart,       forKey: Keys.weekStart)
        ud.set(previousWeekXP,  forKey: Keys.prevXP)
        ud.set(previousRank,    forKey: Keys.prevRank)
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
                rankUpBanner
                leaderboardTabs
            }
            .padding(20)
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .modifier(SprintTheme())
        .overlay(alignment: .top) {
            if weekly.showRankUpBanner {
                RankUpBanner { weekly.showRankUpBanner = false }
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: weekly.showRankUpBanner)
    }

    // MARK: Weekly Header Card

    private var weeklyHeader: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("THIS WEEK").font(.caption.bold()).tracking(1.2).foregroundStyle(.secondary)
                    Text("\(weekly.weeklyXP) XP earned").font(.title2.bold())
                    Text("\(weekly.daysUntilReset) day\(weekly.daysUntilReset == 1 ? "" : "s") until reset")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    let topLabel = weekly.topPercentLabel(totalXP: store.practiceXP)
                    Text(topLabel).font(.title3.bold()).foregroundStyle(.yellow)
                    Text("this week").font(.caption).foregroundStyle(.secondary)
                }
            }
            // Weekly XP progress bar (toward weekly goal of 500 XP)
            let weeklyGoal = 500
            let pct = min(1, Double(weekly.weeklyXP) / Double(weeklyGoal))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08)).frame(height: 8)
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
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: Rank Banner

    @ViewBuilder private var rankUpBanner: some View {
        if weekly.previousRank > 0 && weekly.currentRank < weekly.previousRank {
            HStack(spacing: 10) {
                Image(systemName: "arrow.up.circle.fill").foregroundStyle(.mint)
                VStack(alignment: .leading, spacing: 1) {
                    Text("You climbed the rankings!").font(.subheadline.bold())
                    Text("From #\(weekly.previousRank) → #\(weekly.currentRank) this week").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.mint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: Tab

    private var leaderboardTabs: some View {
        VStack(spacing: 14) {
            Picker("", selection: $tab) {
                Text("Global").tag(0)
                Text("Friends").tag(1)
            }.pickerStyle(.segmented)

            let entries = tab == 0
                ? LeaderboardStore.globalEntries(playerXP: store.practiceXP)
                : LeaderboardStore.friendEntries(playerXP: store.practiceXP)

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
                Text("#\(entry.rank)").font(.system(size: 13, weight: .bold, design: .rounded))
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
                    in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(entry.isYou ? Color.mint.opacity(0.3) : Color.clear, lineWidth: 1))
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
            Text("You climbed the leaderboard! 🎉").font(.subheadline.bold())
            Spacer()
            Button("✕") { onDismiss() }.font(.caption.bold()).foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
        .offset(y: offset)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { offset = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { onDismiss() }
        }
    }
}
