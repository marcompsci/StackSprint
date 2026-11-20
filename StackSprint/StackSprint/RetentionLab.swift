import Combine
import Foundation

// MARK: - Phases 81–100: more ways to make lessons stick
//
// • Confidence checks (metacognition). Learners who rate their confidence find out
//   what they only *think* they know. Errors made with high confidence are corrected
//   especially well once feedback arrives (the "hypercorrection effect", Butterfield &
//   Metcalfe 2001). Right answers that were guesses are treated as shaky.
// • Typed recall (production beats recognition). Typing the term from memory is
//   harder than picking it, and harder retrieval makes stronger memories.
// • Self-explanation. Explaining an idea in your own words improves understanding
//   (Bisra et al. 2018 meta-analysis, g ≈ 0.55).
// • Interleaving. Mixing lessons in one session helps learners tell similar ideas apart
//   (Brunmair & Richter 2019 meta-analysis: g ≈ 0.42 overall, but it varies by
//   material and can reverse for word lists, so it's an extra option, not the default).
// • Delayed retesting. A second quiz a day or more later is spaced retrieval, which is
//   the single strongest combination in the research.
// • Sleep. Memories settle overnight; a short review in the evening is a good habit
//   (Diekelmann & Born 2010). Opt-in reminder only.

// MARK: - Typed recall

enum TypedAnswer {
    /// Lowercased, accents folded, letters and digits only ("Pull-Request " → "pullrequest").
    static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    /// Edit distance between two strings.
    static func distance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var previous = Array(0...b.count)
        for i in 1...a.count {
            var current = [i] + Array(repeating: 0, count: b.count)
            for j in 1...b.count {
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1))
            }
            previous = current
        }
        return previous[b.count]
    }

    /// Small typos are forgiven on longer terms; short terms must be exact.
    static func matches(_ typed: String, _ expected: String) -> Bool {
        let t = normalize(typed), e = normalize(expected)
        guard !t.isEmpty, !e.isEmpty else { return false }
        if t == e { return true }
        let allowed = e.count >= 10 ? 2 : (e.count >= 5 ? 1 : 0)
        return distance(t, e) <= allowed
    }
}

// MARK: - Confidence

enum AnswerConfidence: String, Codable {
    case sure, guessing
}

extension LessonQuizBuilder {
    /// Review quality that also counts how the learner felt: every two correct answers
    /// that were guesses count as one miss, so a lucky score doesn't push the review away.
    static func reviewQuality(score: Int, of total: Int, luckyGuesses: Int) -> Int {
        reviewQuality(score: max(0, score - luckyGuesses / 2), of: total)
    }

    /// Why a wrong choice is wrong, when the choice belongs to another lesson.
    static func whyNot(_ choice: String, in question: LessonQuizQuestion, lessons: [Lesson]) -> String? {
        guard question.choices.indices.contains(question.answer), choice != question.choices[question.answer] else { return nil }
        if let other = lessons.first(where: { $0.term == choice }) {
            return "\(other.term) is something else: \(other.clue)"
        }
        if let other = lessons.first(where: { mask(firstSentence($0.definition), terms: [$0.term]) == choice }) {
            return "That describes \(other.term)."
        }
        if let other = lessons.first(where: { !$0.code.isEmpty && firstCodeLine($0.code) == choice }) {
            return "That example is from \(other.term)."
        }
        return nil
    }
}

// MARK: - Explain it back (self-explanation)

enum ExplainBack {
    private static let stopwords: Set<String> = [
        "about", "after", "again", "always", "another", "because", "before", "being", "between", "could",
        "doesn", "every", "first", "isn", "might", "never", "other", "something", "their", "there", "these",
        "thing", "things", "those", "through", "under", "until", "using", "which", "while", "without",
        "would", "where", "makes", "lets", "means", "often", "should", "small", "short", "later",
    ]

    /// Up to four important words from the definition, in order. Not the term itself.
    static func keyIdeas(for lesson: Lesson, limit: Int = 4) -> [String] {
        let termWords = Set(lesson.term.lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init))
        var seen = Set<String>()
        var ideas: [String] = []
        for raw in lesson.definition.split(whereSeparator: { !$0.isLetter && $0 != "'" }) {
            let word = raw.lowercased().replacingOccurrences(of: "'s", with: "")
            guard word.count >= 5, !stopwords.contains(word), !termWords.contains(word),
                  seen.insert(stem(word)).inserted else { continue }
            ideas.append(word)
            if ideas.count == limit { break }
        }
        return ideas
    }

    /// Which ideas the learner's own words cover. Matches on word stems, so "tests" covers "testing".
    static func covered(_ text: String, ideas: [String]) -> [String] {
        let words = Set(text.lowercased().split(whereSeparator: { !$0.isLetter }).map { stem(String($0)) })
        return ideas.filter { words.contains(stem($0)) }
    }

    static func stem(_ word: String) -> String { String(word.lowercased().prefix(5)) }

    /// A useful explanation has some substance: at least eight words.
    static func isSubstantial(_ text: String) -> Bool {
        text.split(whereSeparator: { $0.isWhitespace }).count >= 8
    }
}

@MainActor final class ExplainBackStore: ObservableObject {
    static let shared = ExplainBackStore()
    static let key = "explainBack.notes"
    @Published private(set) var notes: [String: String] = [:]

    init(defaults: UserDefaults = .standard) {
        notes = defaults.dictionary(forKey: Self.key) as? [String: String] ?? [:]
    }

    func save(_ text: String, for lessonID: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        notes[lessonID] = trimmed.isEmpty ? nil : String(trimmed.prefix(1000))
        persist()
    }

    func merge(_ incoming: [String: String]) {
        for (id, text) in incoming where notes[id] == nil { notes[id] = text }
        persist()
    }

    func eraseAll() { notes = [:]; persist() }

    private func persist() { UserDefaults.standard.set(notes, forKey: Self.key) }
}

// MARK: - Mixed review (interleaving)

enum MixedReview {
    /// Lessons to mix: weakest memory first, alternating tracks so neighbours differ.
    static func pickLessons(_ candidates: [(lesson: Lesson, recall: Double)], limit: Int = 5) -> [Lesson] {
        let sorted = candidates.sorted { $0.recall < $1.recall }.map(\.lesson)
        var byTrack: [String: [Lesson]] = [:]
        var order: [String] = []
        for lesson in sorted {
            if byTrack[lesson.category] == nil { order.append(lesson.category) }
            byTrack[lesson.category, default: []].append(lesson)
        }
        var picked: [Lesson] = []
        var round = 0
        while picked.count < limit {
            var added = false
            for track in order {
                if let list = byTrack[track], list.indices.contains(round), picked.count < limit {
                    picked.append(list[round]); added = true
                }
            }
            if !added { break }
            round += 1
        }
        return picked
    }

    /// Up to `count` questions, taken one per lesson in turn, most important kinds first,
    /// so no two questions in a row are about the same lesson.
    static func questions(for lessons: [Lesson], all: [Lesson], count: Int = 10) -> [LessonQuizQuestion] {
        let sets = lessons.map { lesson in
            LessonQuizBuilder.build(for: lesson, in: all.filter { $0.category == lesson.category })
        }.filter { !$0.isEmpty }
        var result: [LessonQuizQuestion] = []
        var depth = 0
        while result.count < count {
            var added = false
            for set in sets where set.indices.contains(depth) && result.count < count {
                result.append(set[depth]); added = true
            }
            if !added { break }
            depth += 1
        }
        return result
    }
}

// MARK: - Next-day retest

enum Retest {
    /// A lesson last quizzed one to three days ago (not today), weakest result first.
    static func candidate(records: [String: [LessonQuizRecord]], allowed: Set<String>,
                          now: Date = Date(), calendar: Calendar = .current) -> String? {
        let today = calendar.startOfDay(for: now)
        let options = records.compactMap { id, list -> (String, LessonQuizRecord)? in
            guard allowed.contains(id), let last = list.last else { return nil }
            let day = calendar.startOfDay(for: last.date)
            guard let gap = calendar.dateComponents([.day], from: day, to: today).day, (1...3).contains(gap) else { return nil }
            return (id, last)
        }
        return options.sorted { a, b in
            let ra = Double(a.1.score) / Double(max(a.1.total, 1)), rb = Double(b.1.score) / Double(max(b.1.total, 1))
            return ra == rb ? a.1.date > b.1.date : ra < rb
        }.first?.0
    }

    /// The same lesson's questions in a new order, so the retest isn't answered by position.
    static func reshuffled(_ questions: [LessonQuizQuestion], seed: String) -> [LessonQuizQuestion] {
        var rng = SeededGenerator(seed: seed)
        return questions.map { q in
            let correct = q.choices[q.answer]
            let choices = q.choices.count > 2 ? q.choices.shuffled(using: &rng) : q.choices
            return LessonQuizQuestion(id: q.id, kind: q.kind, prompt: q.prompt, choices: choices,
                                      answer: choices.firstIndex(of: correct) ?? q.answer, explanation: q.explanation)
        }
    }
}

// MARK: - You vs. last week

struct WeekComparison: Equatable {
    let thisWeek: Int
    let lastWeek: Int

    static func make(activity: Set<String>, now: Date = Date(), calendar: Calendar = .current) -> WeekComparison {
        let lastWeekDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        return WeekComparison(thisWeek: WeeklyGoalMath.lessons(in: activity, weekOf: now, calendar: calendar),
                              lastWeek: WeeklyGoalMath.lessons(in: activity, weekOf: lastWeekDate, calendar: calendar))
    }

    var message: String {
        if thisWeek == 0 && lastWeek == 0 { return "Finish a lesson to start your weekly record." }
        if thisWeek > lastWeek { return "\(thisWeek - lastWeek) more than last week. You're ahead of your past self." }
        if thisWeek == lastWeek { return "Level with last week. One more lesson puts you ahead." }
        return "\(lastWeek - thisWeek) to go to match last week."
    }
}

// MARK: - Study planner

enum StudyPlanner {
    static let trackKey = "plan.track"
    static let dateKey = "plan.finishBy"

    /// Lessons a day needed to finish `remaining` lessons by the end of `finishBy`.
    /// Nil when the date has already passed.
    static func lessonsPerDay(remaining: Int, now: Date = Date(), finishBy: Date, calendar: Calendar = .current) -> Int? {
        let start = calendar.startOfDay(for: now), end = calendar.startOfDay(for: finishBy)
        guard let gap = calendar.dateComponents([.day], from: start, to: end).day, gap >= 0 else { return nil }
        guard remaining > 0 else { return 0 }
        let days = gap + 1
        return (remaining + days - 1) / days
    }
}

// MARK: - Track certificates

enum TrackCertificate {
    /// Earned when every lesson in the track is finished and its best lesson quiz is 4/5 or better.
    static func isEarned(lessons: [Lesson], completed: Set<String>, best: (String) -> Int?) -> Bool {
        !lessons.isEmpty && lessons.allSatisfy { completed.contains($0.id) && (best($0.id) ?? 0) >= 4 }
    }

    /// How many lessons in the track meet the bar.
    static func progress(lessons: [Lesson], completed: Set<String>, best: (String) -> Int?) -> Int {
        lessons.filter { completed.contains($0.id) && (best($0.id) ?? 0) >= 4 }.count
    }
}

// MARK: - Prompt builder (AI Skills)

struct PromptDraft: Equatable {
    var role = ""
    var task = ""
    var context = ""
    var format = ""
    var avoid = ""
}

enum PromptCheck {
    static func assemble(_ draft: PromptDraft) -> String {
        var lines: [String] = []
        let role = draft.role.trimmingCharacters(in: .whitespacesAndNewlines)
        if !role.isEmpty { lines.append("You are \(role).") }
        let task = draft.task.trimmingCharacters(in: .whitespacesAndNewlines)
        if !task.isEmpty { lines.append(task) }
        let context = draft.context.trimmingCharacters(in: .whitespacesAndNewlines)
        if !context.isEmpty { lines.append("Context: \(context)") }
        let format = draft.format.trimmingCharacters(in: .whitespacesAndNewlines)
        if !format.isEmpty { lines.append("Format: \(format)") }
        let avoid = draft.avoid.trimmingCharacters(in: .whitespacesAndNewlines)
        if !avoid.isEmpty { lines.append("Avoid: \(avoid)") }
        return lines.joined(separator: "\n")
    }

    struct Item: Identifiable, Equatable {
        let id: String
        let ok: Bool
        let text: String
    }

    static func feedback(_ draft: PromptDraft) -> [Item] {
        let words = draft.task.split(whereSeparator: { $0.isWhitespace }).count
        var items = [
            Item(id: "task", ok: words >= 6, text: words >= 6 ? "The task says what you want." : "Describe the task in at least a full sentence."),
            Item(id: "context", ok: !draft.context.trimmingCharacters(in: .whitespaces).isEmpty,
                 text: "Context: who it's for, and why."),
            Item(id: "format", ok: !draft.format.trimmingCharacters(in: .whitespaces).isEmpty,
                 text: "Format: length, style or structure of the answer."),
            Item(id: "role", ok: !draft.role.trimmingCharacters(in: .whitespaces).isEmpty,
                 text: "Optional: a role can set the right tone."),
        ]
        let warnings = privacyWarnings(assemble(draft))
        items.append(Item(id: "privacy", ok: warnings.isEmpty,
                          text: warnings.isEmpty ? "No private details spotted." : warnings.joined(separator: " ")))
        return items
    }

    /// Private details that shouldn't go into an AI chat.
    static func privacyWarnings(_ text: String) -> [String] {
        var warnings: [String] = []
        let lower = text.lowercased()
        if text.range(of: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#, options: [.regularExpression, .caseInsensitive]) != nil {
            warnings.append("Remove the email address.")
        }
        let digitRuns = text.split(whereSeparator: { !$0.isNumber && $0 != " " && $0 != "-" && $0 != "(" && $0 != ")" })
            .map { $0.filter(\.isNumber) }
        if digitRuns.contains(where: { $0.count >= 13 }) {
            warnings.append("That long number looks like a card or account number: leave it out.")
        } else if digitRuns.contains(where: { $0.count >= 10 }) {
            warnings.append("Remove the phone number.")
        }
        if ["password", "passcode", "social security", "ssn", "pin code"].contains(where: { lower.contains($0) }) {
            warnings.append("Never share passwords or ID numbers with an AI tool.")
        }
        return warnings
    }
}

// MARK: - Recording a lesson quiz

@MainActor enum LessonQuizRecorder {
    /// Saves the result and sets the next review. Guesses and confident misses both
    /// pull the review closer, because the memory is weaker than the score suggests.
    static func record(_ lessonID: String, _ result: LessonQuizResult) {
        MasteryStore.shared.record(lessonID: lessonID, score: result.score, total: result.total,
                                   missed: result.missed.map(\.kind),
                                   luckyGuesses: result.luckyGuesses, confidentMisses: result.confidentMisses)
        var quality = LessonQuizBuilder.reviewQuality(score: result.score, of: result.total, luckyGuesses: result.luckyGuesses)
        if result.confidentMisses > 0 { quality = min(quality, 3) }
        SM2Engine.shared.recordReview(lessonID: lessonID, quality: quality)
    }
}
