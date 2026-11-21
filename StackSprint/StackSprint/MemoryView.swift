import Charts
import SwiftUI

// MARK: - Memory
//
// Each lesson you've reviewed has an estimated chance you'd recall it right now, from
// the forgetting curve (p = 2^(-days/half-life)). Reviews are timed for when that
// drops toward 90%, which is when practice does the most good.

struct MemoryView: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @ObservedObject private var reviews = SM2Engine.shared
    @ObservedObject private var mastery = MasteryStore.shared

    private struct Item: Identifiable {
        let lesson: Lesson
        let recall: Double
        var id: String { lesson.id }
    }

    private var items: [Item] {
        (store.curriculum?.lessons ?? []).compactMap { lesson in
            guard !premiumStore.isLocked(lesson.category), let card = reviews.card(for: lesson.id) else { return nil }
            return Item(lesson: lesson, recall: MemoryModel.recall(card: card))
        }
        .sorted { $0.recall < $1.recall }
    }

    var body: some View {
        let all = items
        let fading = all.filter { MemoryModel.band($0.recall) == .fading }
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if all.isEmpty {
                    ContentUnavailableView("Nothing to measure yet", systemImage: "brain.head.profile",
                                           description: Text("Finish a lesson and its quiz, and you'll see how well each one is sticking."))
                } else {
                    summary(all, fading: fading)
                    if !fading.isEmpty {
                        NavigationLink { ReviewSessionView(queue: fading.map(\.lesson)) } label: {
                            Label("Review the \(fading.count) fading \(fading.count == 1 ? "lesson" : "lessons")", systemImage: "arrow.clockwise")
                                .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent).tint(.orange)
                    }
                    accuracyChart
                    weakKinds
                    SolidLessonsCard()
                    MemoryInsightsSection()
                    ReviewForecastSection()
                    ToughLessonsSection()
                    lessonList(all)
                }
                HowMemoryWorksSection()
            }
            .padding(20).frame(maxWidth: 760)
        }
        .navigationTitle("Memory")
        .modifier(SprintTheme())
    }

    private func summary(_ all: [Item], fading: [Item]) -> some View {
        let average = all.map(\.recall).reduce(0, +) / Double(all.count)
        let strong = all.filter { MemoryModel.band($0.recall) == .strong }.count
        return VStack(alignment: .leading, spacing: 10) {
            Text("\(Int((average * 100).rounded()))%").font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("Estimated recall across \(all.count) \(all.count == 1 ? "lesson" : "lessons")").foregroundStyle(.secondary)
            HStack(spacing: 10) {
                pill("\(strong) strong", .green)
                pill("\(all.count - strong - fading.count) holding", .mint)
                pill("\(fading.count) fading", .orange)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func pill(_ text: String, _ color: Color) -> some View {
        Text(text).font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 6)
            .background(color.opacity(0.15), in: Capsule()).foregroundStyle(color)
    }

    @ViewBuilder
    private var accuracyChart: some View {
        let weeks = mastery.weeklyAccuracy()
        if weeks.contains(where: { $0.accuracy != nil }) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Lesson quiz accuracy").font(.headline)
                Chart {
                    ForEach(weeks, id: \.weekStart) { week in
                        if let accuracy = week.accuracy {
                            BarMark(x: .value("Week", week.weekStart, unit: .weekOfYear),
                                    y: .value("Accuracy", accuracy * 100))
                                .foregroundStyle(.mint)
                        }
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 50, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel { Text("\(value.as(Int.self) ?? 0)%") }
                    }
                }
                .frame(height: 160)
                .accessibilityLabel("Quiz accuracy by week")
                .accessibilityValue(weeks.compactMap { $0.accuracy.map { "\(Int($0 * 100))%" } }.joined(separator: ", "))
            }
        }
    }

    @ViewBuilder
    private var weakKinds: some View {
        let kinds = mastery.weakestKinds.prefix(2)
        if !kinds.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Where points slip").font(.headline)
                ForEach(Array(kinds), id: \.kind) { entry in
                    Text("\(entry.kind.label): missed \(entry.misses) \(entry.misses == 1 ? "time" : "times")")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func lessonList(_ all: [Item]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Every lesson").font(.headline)
            ForEach(all) { item in
                NavigationLink { LessonHistoryView(lesson: item.lesson) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.lesson.term).font(.subheadline.bold())
                            Text("\(item.lesson.category) · \(mastery.level(item.lesson.id).rawValue)").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(Int((item.recall * 100).rounded()))%").font(.subheadline.monospacedDigit())
                            .foregroundStyle(color(MemoryModel.band(item.recall)))
                    }
                    .padding(12)
                    .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(item.lesson.term), \(MemoryModel.band(item.recall).rawValue), \(Int(item.recall * 100)) percent")
            }
        }
    }

    private func color(_ band: MemoryModel.Band) -> Color {
        switch band {
        case .strong: return .green
        case .okay: return .mint
        case .fading: return .orange
        }
    }
}

// MARK: - How StackSprint helps you remember

struct HowMemoryWorksSection: View {
    private let points: [(String, String, String)] = [
        ("checkmark.circle.fill", "Test yourself, don't just reread",
         "Pulling an answer from memory makes it stick far better than reading it again. That's why every lesson ends with a 5-question quiz."),
        ("calendar.badge.clock", "Space it out",
         "Reviews spread over days beat cramming. Each lesson comes back right before you'd start to forget it."),
        ("lightbulb.fill", "Guess first",
         "Trying to answer before you're told, even wrongly, makes the explanation stick when it arrives."),
        ("arrow.left.arrow.right", "Tell similar ideas apart",
         "One quiz question always contrasts the lesson with a look-alike, so you learn the difference."),
        ("flame.fill", "A little every day",
         "Intensive language programs rely on daily practice and frequent testing. A small daily target does the same at your pace."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How StackSprint helps you remember").font(.headline)
            ForEach(points, id: \.1) { point in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: point.0).foregroundStyle(.mint).frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(point.1).font(.subheadline.bold())
                        Text(point.2).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
