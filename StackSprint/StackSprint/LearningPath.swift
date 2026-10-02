import SwiftUI
import Combine
import FoundationModels

// MARK: - Learning Path Section (insert after hero card in LearnView)

struct LearningPathSection: View {
    @EnvironmentObject var store: LearningStore
    @StateObject private var advisor = AILearningAdvisor()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("WHAT TO DO NEXT", systemImage: "sparkles")
                .font(.caption.bold()).foregroundStyle(.mint)

            if advisor.busy {
                HStack(spacing: 12) {
                    ProgressView().tint(.mint)
                    Text("Bite is personalising your path…")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 16))
            } else if let rec = advisor.recommendation {
                RecommendationCard(rec: rec) {
                    advisor.refresh(completed: store.completed,
                                   lessons: store.curriculum?.lessons ?? [])
                }
            } else {
                Button {
                    advisor.refresh(completed: store.completed,
                                   lessons: store.curriculum?.lessons ?? [])
                } label: {
                    Label("Get a personalised suggestion", systemImage: "wand.and.stars")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
            }
        }
        .onAppear {
            if advisor.recommendation == nil && !advisor.busy {
                advisor.refresh(completed: store.completed,
                               lessons: store.curriculum?.lessons ?? [])
            }
        }
    }
}

// MARK: - Recommendation Card

private struct RecommendationCard: View {
    let rec: LearningRecommendation
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: rec.aiPowered ? "sparkles" : "lightbulb.fill")
                    .foregroundStyle(rec.aiPowered ? .mint : .yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text(rec.headline).font(.headline)
                    if rec.aiPowered {
                        Text("on-device AI · private").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button { onRefresh() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.bold()).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Refresh suggestion")
            }

            Text(rec.detail).font(.subheadline).foregroundStyle(.secondary)

            if !rec.suggestedTopics.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(rec.suggestedTopics, id: \.self) { topic in
                            Text(topic)
                                .font(.caption.bold())
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(Color.mint.opacity(0.12), in: Capsule())
                                .overlay(Capsule().stroke(Color.mint.opacity(0.3)))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(rec.aiPowered ? Color.mint.opacity(0.25) : Color.yellow.opacity(0.2)))
    }
}

// MARK: - Model

struct LearningRecommendation {
    let headline: String
    let detail: String
    let suggestedTopics: [String]
    let aiPowered: Bool
}

// MARK: - AI Advisor

@MainActor
final class AILearningAdvisor: ObservableObject {
    @Published var recommendation: LearningRecommendation?
    @Published var busy = false

    private var currentTask: Task<Void, Never>?

    func refresh(completed: Set<String>, lessons: [Lesson]) {
        currentTask?.cancel()
        busy = true
        currentTask = Task {
            defer { busy = false }
            let result = await generate(completed: completed, lessons: lessons)
            guard !Task.isCancelled else { return }
            recommendation = result
        }
    }

    private func generate(completed: Set<String>, lessons: [Lesson]) async -> LearningRecommendation {
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            if case .available = model.availability {
                if let aiRec = await tryAIRecommendation(completed: completed, lessons: lessons) {
                    return aiRec
                }
            }
        }
        return fallbackRecommendation(completed: completed, lessons: lessons)
    }

    @available(iOS 26.0, *)
    private func tryAIRecommendation(completed: Set<String>, lessons: [Lesson]) async -> LearningRecommendation? {
        let doneTerms = lessons.filter { completed.contains($0.id) }.map(\.term).prefix(10)
        let available = lessons.filter { !completed.contains($0.id) }.prefix(15).map(\.term)
        guard !available.isEmpty else { return nil }

        let completedSummary = doneTerms.isEmpty
            ? "none yet"
            : doneTerms.joined(separator: ", ")
        let availableSummary = available.joined(separator: ", ")

        let prompt = """
        Completed topics: \(completedSummary)
        Available next topics: \(availableSummary)
        Recommend the single best next topic. Reply with exactly:
        TOPIC: <topic name>
        REASON: <one sentence, max 20 words>
        """

        do {
            let session = LanguageModelSession(
                instructions: "You are a concise coding tutor. Only recommend from the available topics list. Follow the exact reply format."
            )
            let response = try await session.respond(to: prompt)
            return parseAIResponse(response.content, available: Array(available))
        } catch {
            return nil
        }
    }

    private func parseAIResponse(_ text: String, available: [String]) -> LearningRecommendation? {
        let lines = text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        var topic = ""
        var reason = ""
        for line in lines {
            if line.hasPrefix("TOPIC:") {
                topic = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("REASON:") {
                reason = String(line.dropFirst(7)).trimmingCharacters(in: .whitespaces)
            }
        }
        guard !topic.isEmpty else { return nil }
        let suggestedTopics = available.filter { $0 != topic }.prefix(3).map { $0 }
        return LearningRecommendation(
            headline: "Study \(topic) next",
            detail: reason.isEmpty ? "A good next step based on what you've covered." : reason,
            suggestedTopics: [topic] + suggestedTopics,
            aiPowered: true
        )
    }

    private func fallbackRecommendation(completed: Set<String>, lessons: [Lesson]) -> LearningRecommendation {
        let remaining = lessons.filter { !completed.contains($0.id) }

        if remaining.isEmpty {
            return LearningRecommendation(
                headline: "All lessons done!",
                detail: "You've completed every lesson. Head to Studio to apply what you know.",
                suggestedTopics: ["Studio", "GitHub push", "Project Playground"],
                aiPowered: false
            )
        }

        let completedCount = completed.count
        let pct = Double(completedCount) / Double(max(lessons.count, 1))

        let next = remaining.first!
        let suggestedTopics = remaining.prefix(4).map(\.term)

        let headline: String
        let detail: String

        switch pct {
        case 0:
            headline = "Start with \(next.term)"
            detail = "You haven't completed any lessons yet. Pick the first card to build momentum — small wins compound fast."
        case 0..<0.25:
            headline = "Keep going — try \(next.term)"
            detail = "You've completed \(completedCount) lesson\(completedCount == 1 ? "" : "s"). You're building a foundation."
        case 0.25..<0.5:
            headline = "Quarter way! Study \(next.term)"
            detail = "Great start — \(completedCount) lessons in. Keep the streak going."
        case 0.5..<0.75:
            headline = "Past the halfway mark — try \(next.term)"
            detail = "You've done \(completedCount) lessons. The home stretch is in sight."
        default:
            headline = "Almost there! Finish with \(next.term)"
            detail = "\(completedCount) lessons done. A few more and you'll have the full set."
        }

        return LearningRecommendation(
            headline: headline,
            detail: detail,
            suggestedTopics: suggestedTopics,
            aiPowered: false
        )
    }
}
