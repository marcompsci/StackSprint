import Combine
import SwiftUI

// MARK: - Adaptive Quiz Engine

@MainActor final class AdaptiveEngine: ObservableObject {
    /// Shared so every quiz (Challenge Mode, track quizzes, Practice) feeds the same weak-spot data.
    static let shared = AdaptiveEngine()
    // wrong attempt counts per question ID, persisted to UserDefaults
    @Published private(set) var wrongCounts: [String: Int] = {
        UserDefaults.standard.dictionary(forKey: "adaptive.wrongCounts") as? [String: Int] ?? [:]
    }()

    func recordWrong(_ id: String) {
        wrongCounts[id, default: 0] += 1
        persist()
    }

    func recordCorrect(_ id: String) {
        // Decay: reduce wrong count by 1 on correct answer
        if let count = wrongCounts[id], count > 0 {
            wrongCounts[id] = count - 1
            if wrongCounts[id] == 0 { wrongCounts.removeValue(forKey: id) }
            persist()
        }
    }

    // Return questions sorted so harder (more wrong) ones appear first
    func sortedSession(_ questions: [Question], count: Int = 10) -> [Question] {
        let weighted = questions.sorted { a, b in
            (wrongCounts[a.id] ?? 0) > (wrongCounts[b.id] ?? 0)
        }
        // Take top half weakest + random fill to `count`
        let weakCount = min(count / 2, weighted.count)
        var picked = Array(weighted.prefix(weakCount))
        let remaining = weighted.dropFirst(weakCount).shuffled()
        picked += remaining.prefix(count - weakCount)
        return picked.prefix(count).map { $0 }
    }

    /// Tracks where the learner has missed the most questions.
    func weakTopics(questions: [Question], curriculum: [Lesson]) -> [WeakTopic] {
        var catWrong: [String: Int] = [:]
        var catTotal: [String: Int] = [:]
        for q in questions {
            guard let cat = QuestionBank.track(forQuestionID: q.id, lessons: curriculum) else { continue }
            catTotal[cat, default: 0] += 1
            catWrong[cat, default: 0] += (wrongCounts[q.id] ?? 0)
        }
        return catWrong
            .filter { $0.value > 0 }
            .map { WeakTopic(category: $0.key, wrongCount: $0.value, totalQuestions: catTotal[$0.key] ?? 1) }
            .sorted { $0.wrongCount > $1.wrongCount }
    }

    private func persist() {
        UserDefaults.standard.set(wrongCounts, forKey: "adaptive.wrongCounts")
    }
}

struct WeakTopic: Identifiable {
    var id: String { category }
    let category: String
    let wrongCount: Int
    let totalQuestions: Int
    var accuracy: Double { 1.0 - min(Double(wrongCount) / Double(totalQuestions), 1.0) }
}

// MARK: - Adaptive Quiz View (full challenge mode)

struct AdaptiveQuizView: View {
    @EnvironmentObject var store: LearningStore
    @ObservedObject private var engine = AdaptiveEngine.shared
    @Environment(\.dismiss) private var dismiss

    @State private var questions: [Question] = []
    @State private var index = 0
    @State private var selected: Int?
    @State private var score = 0
    @State private var done = false
    @EnvironmentObject var premiumStore: PremiumStore
    /// "Mixed" or a track name. Only tracks the learner can open are offered.
    @State private var category = Self.mixed
    static let mixed = "Mixed (adaptive)"

    private var unlockedTracks: [String] {
        store.tracks.filter { premiumStore.isPro || !PremiumStore.proTracks.contains($0) }
    }
    /// Every track's questions (handwritten + term questions), never from a locked track.
    private var pool: [Question] {
        let tracks = category == Self.mixed ? unlockedTracks : unlockedTracks.filter { $0 == category }
        return tracks.flatMap { store.quiz(for: $0) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if questions.isEmpty {
                    setupView
                } else if done {
                    resultsView
                } else {
                    quizBody
                }
            }
            .modifier(SprintTheme())
            .navigationTitle("Challenge Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: – Setup

    private var setupView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("CHALLENGE MODE", systemImage: "bolt.fill")
                        .font(.caption.bold()).foregroundStyle(.yellow)
                    Text("Adaptive Quiz").font(.largeTitle.bold())
                    Text("Questions adapt to your weak spots. Get one wrong and it comes back sooner.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                // Weakness report
                let topics = engine.weakTopics(questions: unlockedTracks.flatMap { store.quiz(for: $0) },
                                               curriculum: store.curriculum?.lessons ?? [])
                if !topics.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("NEEDS WORK", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.bold()).foregroundStyle(.orange)
                        ForEach(topics.prefix(3)) { topic in
                            WeaknessRow(topic: topic)
                        }
                    }
                    .padding(14)
                    .background(Color.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                // Category picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Choose a focus").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                    Picker("Category", selection: $category) {
                        Text(Self.mixed).tag(Self.mixed)
                        ForEach(unlockedTracks, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .padding(12)
                    .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button { startQuiz() } label: {
                    Label("Start 10-question session", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent).tint(.yellow)
                .foregroundStyle(.black)
            }
            .padding(22)
        }
    }

    // MARK: – Quiz body

    private var quizBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                let q = questions[index]
                HStack {
                    Text("Q \(index + 1) of \(questions.count)").font(.caption.bold()).foregroundStyle(.secondary)
                    Spacer()
                    ProgressView(value: Double(index), total: Double(questions.count))
                        .frame(width: 120).tint(.yellow)
                }

                Text(q.question).font(.title2.bold()).fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    ForEach(q.choices.indices, id: \.self) { i in
                        Button {
                            guard selected == nil else { return }
                            selected = i
                            if i == q.answer {
                                score += 1
                                store.recordDailyRecall(q.id)
                                engine.recordCorrect(q.id)
                            } else {
                                engine.recordWrong(q.id)
                            }
                        } label: {
                            HStack {
                                Text(q.choices[i]).font(.subheadline).multilineTextAlignment(.leading)
                                Spacer()
                                if let s = selected {
                                    if i == q.answer {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                    } else if i == s {
                                        Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                                    }
                                }
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .background(choiceBG(i, q: q), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(choiceBorder(i, q: q), lineWidth: 1.5))
                        .disabled(selected != nil)
                    }
                }

                if let s = selected {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(s == q.answer ? "Correct!" : "Not quite.").font(.headline)
                            .foregroundStyle(s == q.answer ? .green : .orange)
                        Text(q.explanation).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button(index + 1 < questions.count ? "Next question" : "See results") {
                        if index + 1 < questions.count { index += 1; selected = nil }
                        else { done = true }
                    }
                    .buttonStyle(.borderedProminent).tint(.yellow)
                    .foregroundStyle(.black)
                }
            }
            .padding(22)
        }
    }

    // MARK: – Results

    private var resultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(scoreLabel).font(.largeTitle.bold())
                    Text("\(score) / \(questions.count) correct").font(.title2).foregroundStyle(.secondary)
                    Text(scoreMessage).font(.subheadline).foregroundStyle(.secondary)
                }

                let topics = engine.weakTopics(questions: unlockedTracks.flatMap { store.quiz(for: $0) },
                                               curriculum: store.curriculum?.lessons ?? [])
                if !topics.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("FOCUS THESE NEXT", systemImage: "target").font(.caption.bold()).foregroundStyle(.orange)
                        ForEach(topics.prefix(3)) { WeaknessRow(topic: $0) }
                    }
                    .padding(14)
                    .background(Color.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                HStack(spacing: 12) {
                    Button("Play again") {
                        index = 0; score = 0; selected = nil; done = false; startQuiz()
                    }
                    .buttonStyle(.borderedProminent).tint(.yellow)
                    .foregroundStyle(.black)

                    Button("Done") { dismiss() }.buttonStyle(.bordered)
                }
            }
            .padding(22)
        }
    }

    // MARK: – Helpers

    private func startQuiz() {
        questions = engine.sortedSession(pool)
        index = 0; score = 0; selected = nil; done = false
    }

    private func choiceBG(_ i: Int, q: Question) -> Color {
        guard let s = selected else { return SprintPalette.card }
        if i == q.answer { return .green.opacity(0.12) }
        if i == s { return .red.opacity(0.10) }
        return SprintPalette.card
    }

    private func choiceBorder(_ i: Int, q: Question) -> Color {
        guard let s = selected else { return .secondary.opacity(0.15) }
        if i == q.answer { return .green.opacity(0.5) }
        if i == s { return .red.opacity(0.4) }
        return .secondary.opacity(0.1)
    }

    private var scoreLabel: String {
        let pct = Double(score) / Double(max(questions.count, 1))
        switch pct {
        case 0.9...: return "Perfect run"
        case 0.7...: return "Strong session"
        case 0.5...: return "Solid effort"
        default:     return "Good practice"
        }
    }

    private var scoreMessage: String {
        let wrong = questions.count - score
        if wrong == 0 { return "Every answer correct. Your weak spots are shrinking." }
        return "The \(wrong) wrong answer\(wrong == 1 ? "" : "s") will reappear sooner next session."
    }
}

// MARK: - Weakness Row

struct WeaknessRow: View {
    let topic: WeakTopic
    var body: some View {
        HStack {
            Text(topic.category).font(.subheadline.bold())
            Spacer()
            ProgressView(value: topic.accuracy)
                .tint(topic.accuracy > 0.7 ? .mint : .orange)
                .frame(width: 80)
            Text("\(Int(topic.accuracy * 100))%")
                .font(.caption.bold().monospaced())
                .foregroundStyle(topic.accuracy > 0.7 ? .mint : .orange)
                .frame(width: 38, alignment: .trailing)
        }
    }
}

// MARK: - Which track a question belongs to

enum QuestionBank {
    private static let prefixes: [(String, String)] = [
        ("web-", "Web development"), ("cyber-", "Cybersecurity"), ("q-ts", "TypeScript"),
        ("q-react", "React"), ("q-swift", "Swift"), ("q-go", "Go"), ("q-rust", "Rust"),
        ("q-interview", "Interview Prep"), ("q-py", "Python"),
    ]

    /// The track for a handwritten or generated question, or nil if it can't be told.
    static func track(forQuestionID id: String, lessons: [Lesson]) -> String? {
        if let lessonID = TrackQuiz.lessonID(forQuestion: id) {
            return lessons.first { $0.id == lessonID }?.category
        }
        return prefixes.first { id.hasPrefix($0.0) }?.1
    }
}
