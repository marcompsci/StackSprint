import Combine
import Foundation
import SwiftUI

// MARK: - Phases 171–200
//
// • Checkpoints and track exams: cumulative tests over several lessons. Testing across
//   a unit, not just the lesson you just read, is what builds durable, connected memory.
// • Hints: a scaffold for when you're stuck; a hinted answer is treated like a guess.
// • Bookmarks quiz, cheat sheets and session recap cards.
// • Calm mode and colour-blind-friendly feedback (wellbeing and accessibility).
// • Trial reminders: an honest heads-up before a free trial turns into a paid plan.
// • Study-break nudges after long sessions.

// MARK: - Checkpoints and exams

struct ExamUnit: Identifiable, Equatable {
    let track: String
    /// 1-based unit number, or 0 for the final exam.
    let number: Int
    let lessonIDs: [String]
    var id: String { "\(track)|\(number == 0 ? "exam" : "unit\(number)")" }
    var isFinal: Bool { number == 0 }
    var title: String { isFinal ? "Final exam" : "Checkpoint \(number)" }
}

enum Exams {
    static let unitSize = 4
    static let passPercent = 80
    static let checkpointQuestions = 8
    static let finalQuestions = 15

    /// Checkpoints of four lessons each, in track order; a short last group joins the one before.
    static func units(track: String, lessons: [Lesson]) -> [ExamUnit] {
        let ids = lessons.map(\.id)
        guard !ids.isEmpty else { return [] }
        var groups = stride(from: 0, to: ids.count, by: unitSize).map { Array(ids[$0..<min($0 + unitSize, ids.count)]) }
        if groups.count > 1, let last = groups.last, last.count < unitSize / 2 {
            groups.removeLast()
            groups[groups.count - 1] += last
        }
        return groups.enumerated().map { ExamUnit(track: track, number: $0.offset + 1, lessonIDs: $0.element) }
    }

    static func finalExam(track: String, lessons: [Lesson]) -> ExamUnit {
        ExamUnit(track: track, number: 0, lessonIDs: lessons.map(\.id))
    }

    /// A checkpoint opens when all its lessons are finished; the final exam at 80% of the track.
    static func isOpen(_ unit: ExamUnit, completed: Set<String>) -> Bool {
        guard !unit.lessonIDs.isEmpty else { return false }
        let done = unit.lessonIDs.filter { completed.contains($0) }.count
        return unit.isFinal ? done * 100 >= unit.lessonIDs.count * passPercent : done == unit.lessonIDs.count
    }

    static func passed(score: Int, total: Int) -> Bool {
        total > 0 && score * 100 >= total * passPercent
    }

    /// Questions spread across the unit's lessons, most important kinds first, mixed so the
    /// same lesson never comes twice in a row.
    static func questions(for unit: ExamUnit, lessons: [Lesson]) -> [LessonQuizQuestion] {
        let byID = Dictionary(lessons.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let unitLessons = unit.lessonIDs.compactMap { byID[$0] }
        var rng = SeededGenerator(seed: "exam|\(unit.id)")
        let order = unit.isFinal ? unitLessons.shuffled(using: &rng) : unitLessons
        return MixedReview.questions(for: order, all: lessons,
                                     count: unit.isFinal ? finalQuestions : checkpointQuestions)
    }
}

@MainActor final class ExamStore: ObservableObject {
    static let shared = ExamStore()
    static let key = "exams.best"
    /// Best percentage per unit id.
    @Published private(set) var best: [String: Int] = [:]

    init(defaults: UserDefaults = .standard) {
        best = defaults.dictionary(forKey: Self.key) as? [String: Int] ?? [:]
    }

    func record(_ unit: ExamUnit, score: Int, total: Int) {
        guard total > 0 else { return }
        let percent = score * 100 / total
        best[unit.id] = max(best[unit.id] ?? 0, percent)
        persist()
    }

    func hasPassed(_ unit: ExamUnit) -> Bool { (best[unit.id] ?? 0) >= Exams.passPercent }
    var passedCheckpoints: Int { best.filter { !$0.key.hasSuffix("|exam") && $0.value >= Exams.passPercent }.count }
    var passedExams: Int { best.filter { $0.key.hasSuffix("|exam") && $0.value >= Exams.passPercent }.count }

    func merge(_ incoming: [String: Int]) {
        for (id, value) in incoming { best[id] = max(best[id] ?? 0, value) }
        persist()
    }

    func eraseAll() { best = [:]; persist() }
    private func persist() { UserDefaults.standard.set(best, forKey: Self.key) }
}

// MARK: - Hints

enum QuizHint {
    /// A nudge that doesn't give the answer away: the first letter and length for a term,
    /// otherwise one wrong option ruled out.
    static func text(for question: LessonQuizQuestion) -> String {
        let answer = question.choices[question.answer]
        if question.kind == .recall, let first = answer.first {
            return "Starts with \"\(first)\" and has \(answer.count) characters."
        }
        if question.choices.count > 2,
           let wrong = question.choices.indices.first(where: { $0 != question.answer }) {
            return "It isn't \"\(question.choices[wrong])\"."
        }
        return "Think about what the lesson said this is for."
    }
}

// MARK: - Cheat sheets

enum CheatSheet {
    /// One line per finished lesson: term and its first sentence.
    static func lines(track: String, lessons: [Lesson], completed: Set<String>) -> [(term: String, summary: String)] {
        lessons.filter { $0.category == track && completed.contains($0.id) }
            .map { (term: $0.term, summary: LessonQuizBuilder.firstSentence($0.definition)) }
    }
}

// MARK: - Calm mode and colour-blind feedback

enum DisplayPrefs {
    static let calmKey = "display.calmMode"
    static let colorBlindKey = "display.colorBlind"

    /// Colours for right and wrong. The colour-blind palette uses blue and orange,
    /// which stay distinct for the common forms of colour blindness. Icons are always shown too.
    static func feedback(colorBlind: Bool) -> (right: Color, wrong: Color) {
        colorBlind ? (.blue, .orange) : (.green, .red)
    }
}

// MARK: - Trial reminders

enum TrialReminder {
    static let enabledKey = "trial.reminder"
    static let id = "trial.ending"

    /// Two days before the trial ends, at 10 am. Nil if that's already past.
    static func fireDate(trialEnds: Date, now: Date = Date(), calendar: Calendar = .current) -> Date? {
        guard let twoDaysBefore = calendar.date(byAdding: .day, value: -2, to: trialEnds),
              let atTen = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: twoDaysBefore),
              atTen > now else { return nil }
        return atTen
    }

    static func body(plan: String, price: String, ends: Date) -> String {
        "Your \(plan) free trial ends \(ends.formatted(date: .abbreviated, time: .omitted)). After that it's \(price). You can cancel any time in Account → Manage subscriptions."
    }
}

// MARK: - Study breaks

enum StudyBreak {
    static let minutes = 25

    /// True once the app has been open and in use for 25 minutes without a break.
    static func isDue(sessionStart: Date?, dismissedAt: Date?, now: Date = Date()) -> Bool {
        guard let sessionStart else { return false }
        let since = max(sessionStart, dismissedAt ?? .distantPast)
        return now.timeIntervalSince(since) >= Double(minutes * 60)
    }
}

