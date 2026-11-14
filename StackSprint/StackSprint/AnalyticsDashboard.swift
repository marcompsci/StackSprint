import Charts
import Combine
import SwiftUI

// MARK: - Analytics Dashboard

struct AnalyticsDashboardView: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var seasonStore: SeasonStore
    @EnvironmentObject var premiumStore: PremiumStore

    @State private var refreshID = UUID()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                if store.practicedDays.isEmpty { EmptyStatsState() }
                else {
                    streakStatsCard
                    heatmapSection
                    categoryProgressSection
                    xpBreakdownChart
                }
                leaderboardLink
                weeklyLeaderboardLink
                trophyRoomLink
                weeklyInsightsLink
                seasonLink
                portfolioLink
            }
            .id(refreshID)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: 680)
        }
        .refreshable { refreshID = UUID() }
        .navigationTitle("Analytics")
        .modifier(SprintTheme())
    }

    // MARK: – Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Stats").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            Text("How you practice").font(.system(.title, design: .rounded, weight: .bold))
            Text("\(store.practicedDays.count) active days · \(store.completed.count) lessons done")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    // MARK: – Streak stats

    private var streakStatsCard: some View {
        let best = store.bestStreak
        return HStack(spacing: 0) {
            statBlock(value: store.currentStreak, label: "Current streak", icon: "flame.fill", color: .orange)
            Divider().padding(.vertical, 12)
            statBlock(value: best, label: "Best streak", icon: "trophy.fill", color: .yellow)
            Divider().padding(.vertical, 12)
            statBlock(value: store.practicedDays.count, label: "Total days", icon: "calendar", color: .mint)
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func statBlock(value: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
            Text("\(value)").font(.system(.title, design: .rounded, weight: .bold))
            Text(label).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: – Practice Heatmap (12 weeks)

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("PRACTICE HEATMAP · 12 WEEKS", systemImage: "calendar.badge.checkmark")
                .font(.caption.bold()).foregroundStyle(.mint)
            PracticeHeatmap(practicedDays: store.practicedDays)
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: – Category progress

    private var categoryProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("PROGRESS BY TRACK", systemImage: "chart.bar.fill")
                .font(.caption.bold()).foregroundStyle(.mint)

            let lessons = store.curriculum?.lessons ?? []
            let cats: [String] = {
                var seen = Set<String>(); return lessons.compactMap { seen.insert($0.category).inserted ? $0.category : nil }
            }()

            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(cats, id: \.self) { cat in
                        let total = lessons.filter { $0.category == cat }.count
                        let done  = lessons.filter { $0.category == cat && store.completed.contains($0.id) }.count
                        BarMark(
                            x: .value("Done", done),
                            y: .value("Track", shortCat(cat))
                        )
                        .foregroundStyle(catColor(cat).gradient)
                        .annotation(position: .trailing) {
                            Text("\(done)/\(total)").font(.caption2.monospaced()).foregroundStyle(.secondary)
                        }
                        BarMark(
                            x: .value("Remaining", total - done),
                            y: .value("Track", shortCat(cat))
                        )
                        .foregroundStyle(Color.secondary.opacity(0.15))
                    }
                }
                .frame(height: CGFloat(cats.count) * 44)
                .chartXAxis(.hidden)
            } else {
                ForEach(cats, id: \.self) { cat in
                    let total = lessons.filter { $0.category == cat }.count
                    let done  = lessons.filter { $0.category == cat && store.completed.contains($0.id) }.count
                    let pct   = total > 0 ? Double(done) / Double(total) : 0
                    VStack(alignment: .leading, spacing: 4) {
                        HStack { Text(shortCat(cat)).font(.caption.bold()); Spacer(); Text("\(done)/\(total)").font(.caption2.monospaced()).foregroundStyle(.secondary) }
                        ProgressView(value: pct).tint(catColor(cat))
                    }
                }
            }
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: – XP Breakdown chart

    /// The parts always add up to the total: XP comes only from lessons (10 each)
    /// and correct quiz answers (5 each). The streak used to appear here as XP it never gave.
    private var xpBreakdownChart: some View {
        let lessonXP = store.completed.count * 10
        let quizXP   = store.correctRecallAnswers.count * 5
        let data: [(String, Int, Color)] = [("Lessons", lessonXP, .mint), ("Quiz answers", quizXP, .purple)]
        let tallest = max(data.map(\.1).max() ?? 0, 1)

        return VStack(alignment: .leading, spacing: 12) {
            Label("XP BREAKDOWN", systemImage: "bolt.fill").font(.caption.bold()).foregroundStyle(.yellow)
            HStack(alignment: .bottom, spacing: 16) {
                ForEach(data, id: \.0) { item in
                    VStack(spacing: 6) {
                        Text("\(item.1)").font(.title3.bold()).foregroundStyle(item.2)
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(item.2.opacity(0.3))
                            .frame(width: 44, height: max(80 * CGFloat(item.1) / CGFloat(tallest), 6))
                        Text(item.0).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(item.0): \(item.1) XP")
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total").font(.caption).foregroundStyle(.secondary)
                    Text("\(store.practiceXP) XP")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    let level = XPLevel.current(xp: store.practiceXP)
                    Label(level.name, systemImage: level.icon)
                        .font(.caption.bold()).foregroundStyle(level.color)
                }
            }
            Text("10 XP per lesson finished, 5 XP per quiz question answered right (once a day each).")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: – Leaderboard link

    private var weeklyLeaderboardLink: some View {
        NavigationLink { WeeklyLeaderboardView().environmentObject(store) } label: {
            HStack(spacing: 14) {
                Image(systemName: "calendar.badge.clock").font(.title2).foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 3) {
                    Text("This week").font(.headline)
                    Text("\(WeeklyXPStore.shared.weeklyXP) XP this week · resets in \(WeeklyXPStore.shared.daysUntilReset)d")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(16)
            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var trophyRoomLink: some View {
        NavigationLink { TrophyRoomView() } label: {
            HStack(spacing: 14) {
                Image(systemName: "trophy.fill").font(.title2).foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Trophy Room").font(.headline)
                    Text("\(AchievementStore.shared.unlocked.count)/\(AchievementStore.shared.achievements.count) achievements unlocked")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(16)
            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var leaderboardLink: some View {
        NavigationLink { LeaderboardView() } label: {
            HStack(spacing: 14) {
                Image(systemName: "trophy.fill").font(.title2).foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Pacers").font(.headline)
                    Text("Race computer pacers set around your level").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(16)
            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var weeklyInsightsLink: some View {
        NavigationLink { WeeklyInsightsView() } label: {
            HStack(spacing: 14) {
                Image(systemName: "chart.xyaxis.line").font(.title2).foregroundStyle(.purple)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Weekly Insights").font(.headline)
                    Text("Heatmap, velocity, weak spots & recommendations").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(16)
            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var seasonLink: some View {
        NavigationLink {
            SeasonView().environmentObject(seasonStore).environmentObject(premiumStore)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "trophy.fill").font(.title2).symbolRenderingMode(.hierarchical).foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Season \(seasonStore.season.number)").font(.headline)
                        Text("Tier \(seasonStore.tier)").font(.caption.bold())
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.orange.opacity(0.15), in: Capsule())
                            .foregroundStyle(.orange)
                    }
                    Text("\(seasonStore.season.daysRemaining) days remaining · \(seasonStore.tierXP)/\(Season.xpPerTier) XP to next tier")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(16)
            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var portfolioLink: some View {
        NavigationLink { PortfolioView().environmentObject(store) } label: {
            HStack(spacing: 14) {
                Image(systemName: "doc.badge.gearshape.fill").font(.title2).foregroundStyle(.purple)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Developer Portfolio").font(.headline)
                    Text("Export your completed lessons as HTML or PDF").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(16)
            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: – Helpers

    private func shortCat(_ cat: String) -> String {
        switch cat {
        case "Web development": return "Web Dev"
        case "Cybersecurity":   return "Security"
        default:                return cat
        }
    }

    private func catColor(_ cat: String) -> Color {
        switch cat {
        case "Web development": return .blue
        case "Python":          return .green
        case "Cybersecurity":   return .red
        case "TypeScript":      return .cyan
        case "React":           return .teal
        case "Swift":           return .orange
        default:                return .mint
        }
    }
}

// MARK: - Practice Heatmap View

struct PracticeHeatmap: View {
    let practicedDays: Set<String>
    private let weeks = 12
    private let cols = 7

    var body: some View {
        let days = last84Days()
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(20), spacing: 4), count: cols), spacing: 4) {
            ForEach(days, id: \.self) { key in
                let practiced = practicedDays.contains(key)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(practiced ? Color.orange : Color.secondary.opacity(0.12))
                    .frame(width: 20, height: 20)
                    .overlay {
                        if practiced {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9)).foregroundStyle(.white)
                        }
                    }
            }
        }
        HStack {
            Text("12 weeks ago").font(.caption2).foregroundStyle(.secondary)
            Spacer()
            Text("Today").font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func last84Days() -> [String] {
        (0..<(weeks * cols)).reversed().compactMap { offset in
            Calendar.current.date(byAdding: .day, value: -offset, to: Date())
        }.map { date in
            let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
            return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        }
    }
}
