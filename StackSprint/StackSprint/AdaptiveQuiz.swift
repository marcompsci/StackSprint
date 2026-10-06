import Combine
import SwiftUI

// MARK: - Adaptive Quiz Engine

@MainActor final class AdaptiveEngine: ObservableObject {
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

    // Weak topics: categories where user got most questions wrong
    func weakTopics(questions: [Question], curriculum: [Lesson]) -> [WeakTopic] {
        var catWrong: [String: Int] = [:]
        var catTotal: [String: Int] = [:]

        for q in questions {
            // Match question to category via shared term in id prefix (best-effort)
            let cat = inferCategory(q.id, curriculum: curriculum)
            catTotal[cat, default: 0] += 1
            catWrong[cat, default: 0] += (wrongCounts[q.id] ?? 0)
        }

        return catWrong
            .filter { $0.value > 0 }
            .map { WeakTopic(category: $0.key, wrongCount: $0.value, totalQuestions: catTotal[$0.key] ?? 1) }
            .sorted { $0.wrongCount > $1.wrongCount }
    }

    private func inferCategory(_ questionID: String, curriculum: [Lesson]) -> String {
        if questionID.hasPrefix("q-ts")        { return "TypeScript" }
        if questionID.hasPrefix("q-react")     { return "React" }
        if questionID.hasPrefix("q-swift")     { return "Swift" }
        if questionID.hasPrefix("q-cyber")     { return "Cybersecurity" }
        if questionID.hasPrefix("q-py")        { return "Python" }
        if questionID.hasPrefix("q-go")        { return "Go" }
        if questionID.hasPrefix("q-rust")      { return "Rust" }
        if questionID.hasPrefix("q-interview") { return "Interview Prep" }
        return "Web development"
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
    @StateObject private var engine = AdaptiveEngine()
    @Environment(\.dismiss) private var dismiss

    @State private var questions: [Question] = []
    @State private var index = 0
    @State private var selected: Int?
    @State private var score = 0
    @State private var done = false
    @State private var category: QuizCategory = .mixed

    enum QuizCategory: String, CaseIterable, Identifiable {
        case mixed = "Mixed (adaptive)"
        case webDev = "Web Dev"
        case python = "Python"
        case cyber = "Cybersecurity"
        case typescript = "TypeScript"
        case react = "React"
        case swift = "Swift"
        var id: String { rawValue }
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
                    Text("Adaptive Quiz").font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("Questions adapt to your weak spots. Get one wrong and it comes back sooner.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                // Weakness report
                let topics = engine.weakTopics(questions: store.curriculum?.questions ?? [],
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
                    .background(Color.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                }

                // Category picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("CHOOSE A FOCUS").font(.caption.bold()).foregroundStyle(.secondary)
                    Picker("Category", selection: $category) {
                        ForEach(QuizCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(12)
                    .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 12))
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
                        .background(choiceBG(i, q: q), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(choiceBorder(i, q: q), lineWidth: 1.5))
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
                    .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 14))

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
                    Text(scoreLabel).font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("\(score) / \(questions.count) correct").font(.title2).foregroundStyle(.secondary)
                    Text(scoreMessage).font(.subheadline).foregroundStyle(.secondary)
                }

                let topics = engine.weakTopics(questions: store.curriculum?.questions ?? [],
                                               curriculum: store.curriculum?.lessons ?? [])
                if !topics.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("FOCUS THESE NEXT", systemImage: "target").font(.caption.bold()).foregroundStyle(.orange)
                        ForEach(topics.prefix(3)) { WeaknessRow(topic: $0) }
                    }
                    .padding(14)
                    .background(Color.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
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
        let all = store.curriculum?.questions ?? []
        let filtered: [Question] = {
            switch category {
            case .mixed:      return all
            case .webDev:     return all.filter { $0.id.hasPrefix("q-web") || (!$0.id.hasPrefix("q-ts") && !$0.id.hasPrefix("q-react") && !$0.id.hasPrefix("q-swift") && !$0.id.hasPrefix("q-py") && !$0.id.hasPrefix("q-cyber")) }
            case .python:     return all.filter { $0.id.hasPrefix("q-py") }
            case .cyber:      return all.filter { $0.id.hasPrefix("q-cyber") }
            case .typescript: return all.filter { $0.id.hasPrefix("q-ts") }
            case .react:      return all.filter { $0.id.hasPrefix("q-react") }
            case .swift:      return all.filter { $0.id.hasPrefix("q-swift") }
            }
        }()
        questions = engine.sortedSession(filtered.isEmpty ? all : filtered)
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
        case 0.9...: return "Perfect run! \u{1F3C6}"
        case 0.7...: return "Great session! \u{1F4AA}"
        case 0.5...: return "Solid effort. \u{1F4DA}"
        default:     return "Good practice. \u{1F4A1}"
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
