import Charts
import SwiftUI

// MARK: - Weekly Insights View

struct WeeklyInsightsView: View {
    @EnvironmentObject var store: LearningStore
    @StateObject private var engine = AdaptiveEngine()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                activityHeatmapSection
                velocitySection
                weakSpotsSection
                recommendationsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Weekly Insights")
        .navigationBarTitleDisplayMode(.large)
        .modifier(SprintTheme())
    }

    // MARK: Activity Heatmap

    private var activityHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("30-Day Activity", systemImage: "calendar.badge.clock")
                .font(.headline)
            Text("Days you practiced in the last 30 days")
                .font(.caption).foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
                ForEach(last30Days, id: \.key) { entry in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(entry.practiced ? Color.mint.opacity(0.78) : Color.secondary.opacity(0.12))
                        .frame(height: 32)
                        .overlay(
                            Text(entry.dayLabel)
                                .font(.system(size: 8))
                                .foregroundStyle(entry.practiced ? .white : .secondary)
                        )
                }
            }

            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2).fill(Color.secondary.opacity(0.12)).frame(width: 12, height: 12)
                Text("No activity").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                RoundedRectangle(cornerRadius: 2).fill(Color.mint.opacity(0.78)).frame(width: 12, height: 12)
                Text("Practiced").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private struct DayEntry { let key: String; let dayLabel: String; let practiced: Bool }

    private var last30Days: [DayEntry] {
        let calendar = Calendar.current
        return (0..<30).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
            let comps = calendar.dateComponents([.year, .month, .day], from: date)
            let key = String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
            let day = String(comps.day ?? 0)
            return DayEntry(key: key, dayLabel: day, practiced: store.practicedDays.contains(key))
        }
    }

    // MARK: Learning Velocity

    private var velocitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Learning Velocity", systemImage: "chart.bar.fill")
                .font(.headline)
            Text("Days practiced each week over the last 4 weeks")
                .font(.caption).foregroundStyle(.secondary)

            Chart {
                ForEach(last4Weeks, id: \.label) { item in
                    BarMark(
                        x: .value("Week of", item.label),
                        y: .value("Days", item.days)
                    )
                    .foregroundStyle(Color.mint.gradient)
                    .cornerRadius(6)
                }
                RuleMark(y: .value("5-day target", 5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(Color.secondary.opacity(0.4))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("target").font(.caption2).foregroundStyle(.secondary)
                    }
            }
            .frame(height: 140)
            .chartYScale(domain: 0...7)
            .chartXAxis { AxisMarks { _ in AxisValueLabel().font(.caption) } }
            .chartYAxis { AxisMarks(position: .leading) { _ in AxisValueLabel().font(.caption) } }
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private struct WeekBar { let label: String; let days: Int }

    private var last4Weeks: [WeekBar] {
        let calendar = Calendar.current
        let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
        return (0..<4).reversed().map { weekOffset in
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: Date())!
            let weekStart = calendar.date(byAdding: .day, value: -6, to: weekEnd)!
            let days = (0..<7).filter { dayOffset in
                let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
                let comps = calendar.dateComponents([.year, .month, .day], from: date)
                let key = String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
                return store.practicedDays.contains(key)
            }.count
            return WeekBar(label: fmt.string(from: weekStart), days: days)
        }
    }

    // MARK: Weak Spots

    private var weakSpotsSection: some View {
        let topics = weakTopics
        return VStack(alignment: .leading, spacing: 12) {
            Label("Needs Practice", systemImage: "exclamationmark.triangle.fill")
                .font(.headline).foregroundStyle(.orange)

            if topics.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.mint)
                    Text("No weak spots detected — keep quizzing to track accuracy!")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(topics) { topic in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(topic.category).font(.subheadline.bold())
                            Spacer()
                            Text("\(Int(topic.accuracy * 100))% accuracy")
                                .font(.caption.bold())
                                .foregroundStyle(topic.accuracy < 0.5 ? Color.red : Color.orange)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(
                                    (topic.accuracy < 0.5 ? Color.red : Color.orange).opacity(0.12),
                                    in: Capsule()
                                )
                        }
                        ProgressView(value: topic.accuracy)
                            .tint(topic.accuracy < 0.5 ? .red : .orange)
                        Text("\(topic.wrongCount) wrong attempt\(topic.wrongCount == 1 ? "" : "s")")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if topic.id != topics.last?.id { Divider() }
                }
            }
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private var weakTopics: [WeakTopic] {
        guard let curriculum = store.curriculum else { return [] }
        return engine.weakTopics(questions: curriculum.questions, curriculum: curriculum.lessons)
    }

    // MARK: Personalized Recommendations

    private var recommendationsSection: some View {
        let recs = recommendations
        return VStack(alignment: .leading, spacing: 12) {
            Label("Recommended Next", systemImage: "sparkles")
                .font(.headline).foregroundStyle(.purple)

            if recs.isEmpty {
                Text("Complete more lessons to get personalized recommendations.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 8)
            } else {
                ForEach(recs) { lesson in
                    NavigationLink(destination: LessonView(lesson: lesson)) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(Color.purple.opacity(0.12)).frame(width: 36, height: 36)
                                Image(systemName: "book.fill").font(.caption).foregroundStyle(.purple)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lesson.term).font(.subheadline.bold()).foregroundStyle(.primary)
                                Text(lesson.category).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundStyle(Color.purple.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                    if lesson.id != recs.last?.id { Divider() }
                }
            }
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private var recommendations: [Lesson] {
        guard let curriculum = store.curriculum else { return [] }
        let incomplete = curriculum.lessons.filter { !store.completed.contains($0.id) }
        let startedCategories = Set(
            curriculum.lessons.filter { store.completed.contains($0.id) }.map(\.category)
        )
        let weakCategories = Set(weakTopics.prefix(2).map(\.category))
        let priority = weakCategories.isEmpty ? startedCategories : weakCategories.union(startedCategories)
        let filtered = incomplete.filter { priority.contains($0.category) }
        return Array((filtered.isEmpty ? incomplete : filtered).prefix(4))
    }
}
