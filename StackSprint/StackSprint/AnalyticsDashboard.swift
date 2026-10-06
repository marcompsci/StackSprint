import Charts
import Combine
import SwiftUI

// MARK: - Analytics Dashboard

struct AnalyticsDashboardView: View {
    @EnvironmentObject var store: LearningStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                streakStatsCard
                heatmapSection
                categoryProgressSection
                xpBreakdownChart
                leaderboardLink
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: 680)
        }
        .navigationTitle("Analytics")
        .modifier(SprintTheme())
    }

    // MARK: – Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("YOUR LEARNING STATS").font(.caption.bold()).tracking(1.3).foregroundStyle(.mint)
            Text("How you practice").font(.system(.title, design: .rounded, weight: .bold))
            Text("\(store.practicedDays.count) active days · \(store.completed.count) lessons done")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    // MARK: – Streak stats

    private var streakStatsCard: some View {
        let best = UserDefaults.standard.integer(forKey: "stats.bestStreak")
        return HStack(spacing: 0) {
            statBlock(value: store.currentStreak, label: "Current streak", icon: "flame.fill", color: .orange)
            Divider().padding(.vertical, 12)
            statBlock(value: best, label: "Best streak", icon: "trophy.fill", color: .yellow)
            Divider().padding(.vertical, 12)
            statBlock(value: store.practicedDays.count, label: "Total days", icon: "calendar", color: .mint)
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private func statBlock(value: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
            Text("\(value)").font(.system(size: 32, weight: .bold, design: .rounded))
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
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20))
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
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: – XP Breakdown chart

    private var xpBreakdownChart: some View {
        let lessonXP   = store.completed.count * 10
        let recallXP   = store.correctRecallAnswers.count * 5
        let streakXP   = store.currentStreak * 2
        let data: [(String, Int, Color)] = [
            ("Lessons", lessonXP, .mint),
            ("Recall",  recallXP, .purple),
            ("Streak",  streakXP, .orange),
        ]

        return VStack(alignment: .leading, spacing: 12) {
            Label("XP BREAKDOWN", systemImage: "bolt.fill").font(.caption.bold()).foregroundStyle(.yellow)
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(data, id: \.0) { item in
                    VStack(spacing: 6) {
                        Text("\(item.1)").font(.title3.bold()).foregroundStyle(item.2)
                        Text("XP").font(.caption2).foregroundStyle(.secondary)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(item.2.opacity(0.3))
                            .frame(width: 44, height: max(CGFloat(item.1) / 4, 8))
                        Text(item.0).font(.caption2).foregroundStyle(.secondary)
                    }
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
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: – Leaderboard link

    private var leaderboardLink: some View {
        NavigationLink { LeaderboardView() } label: {
            HStack(spacing: 14) {
                Image(systemName: "trophy.fill").font(.title2).foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Leaderboard").font(.headline)
                    Text("See how your XP ranks globally").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(16)
            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20))
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
                RoundedRectangle(cornerRadius: 4)
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
