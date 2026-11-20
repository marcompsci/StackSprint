import Combine
import Foundation

// MARK: - Phases 121–145: deeper practice
//
// • Complete the code: fill a blank in the lesson's example (faded worked examples).
// • Related lessons: connect new ideas to ones you know (elaboration).
// • Daily reflection: writing what you learned improves later performance
//   (Di Stefano et al., "Learning by Thinking", 2014).
// • Teach a friend: sharing a lesson card (the protégé effect).
// • Tough lessons ("leeches" in spaced-repetition terms) get a different approach.
// • Review forecast, lesson of the day, quiz combos and new achievements.

// MARK: - Complete the code

struct CodeCloze: Equatable {
    /// The example with the blank shown as "____".
    let prompt: String
    let answer: String
}

enum CodeClozeBuilder {
    private static let skip: Set<String> = ["the", "and", "for", "you", "not", "with", "this", "that", "from", "are", "was", "but"]

    /// Blanks out one meaningful token of the lesson's code. Prefers a word that also
    /// appears in the term or definition, so the blank tests the lesson's idea.
    static func make(for lesson: Lesson) -> CodeCloze? {
        let code = lesson.code
        guard !code.isEmpty else { return nil }
        let tokens = tokenRanges(in: code)
        guard !tokens.isEmpty else { return nil }
        let lessonWords = Set((lesson.term + " " + lesson.definition).lowercased()
            .split(whereSeparator: { !$0.isLetter }).map(String.init))
        let scored = tokens.enumerated().map { index, range -> (Range<String.Index>, Int) in
            let word = String(code[range])
            var score = min(word.count, 10)
            if lessonWords.contains(word.lowercased()) { score += 20 }
            if index == 0 { score -= 5 }
            return (range, score)
        }
        guard let best = scored.max(by: { $0.1 < $1.1 || ($0.1 == $1.1 && $0.0.lowerBound > $1.0.lowerBound) }) else { return nil }
        let answer = String(code[best.0])
        var prompt = code
        prompt.replaceSubrange(best.0, with: "____")
        return CodeCloze(prompt: prompt, answer: answer)
    }

    /// Identifier-like words of 3+ letters, skipping very common English words.
    static func tokenRanges(in code: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var start: String.Index?
        var i = code.startIndex
        func close(at end: String.Index) {
            if let s = start {
                let word = code[s..<end]
                if word.count >= 3, word.first?.isLetter == true, !skip.contains(word.lowercased()) { ranges.append(s..<end) }
            }
            start = nil
        }
        while i < code.endIndex {
            let c = code[i]
            if c.isLetter || c.isNumber || c == "_" {
                if start == nil { start = i }
            } else {
                close(at: i)
            }
            i = code.index(after: i)
        }
        close(at: code.endIndex)
        return ranges
    }

    /// Code answers are exact apart from case and surrounding spaces.
    static func isCorrect(_ typed: String, _ cloze: CodeCloze) -> Bool {
        typed.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == cloze.answer.lowercased()
    }
}

// MARK: - Related lessons

enum RelatedLessons {
    private static func words(_ lesson: Lesson) -> Set<String> {
        Set((lesson.term + " " + lesson.definition + " " + lesson.clue).lowercased()
            .split(whereSeparator: { !$0.isLetter }).map(String.init).filter { $0.count >= 4 }.map { String($0.prefix(6)) })
    }

    /// The lessons whose wording overlaps most with this one. Same track breaks ties.
    static func find(for lesson: Lesson, in all: [Lesson], limit: Int = 3) -> [Lesson] {
        let mine = words(lesson)
        guard !mine.isEmpty else { return [] }
        let scored = all.filter { $0.id != lesson.id }.compactMap { other -> (Lesson, Double)? in
            let theirs = words(other)
            let shared = mine.intersection(theirs).count
            guard shared >= 2 else { return nil }
            let jaccard = Double(shared) / Double(mine.union(theirs).count)
            return (other, jaccard + (other.category == lesson.category ? 0.05 : 0))
        }
        return scored.sorted { $0.1 == $1.1 ? $0.0.id < $1.0.id : $0.1 > $1.1 }.prefix(limit).map(\.0)
    }
}

// MARK: - Daily reflection

@MainActor final class JournalStore: ObservableObject {
    static let shared = JournalStore()
    static let key = "journal.entries"
    @Published private(set) var entries: [String: String] = [:]

    init(defaults: UserDefaults = .standard) {
        entries = defaults.dictionary(forKey: Self.key) as? [String: String] ?? [:]
    }

    func save(_ text: String, on date: Date = Date()) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        entries[LearningStore.dayKey(date)] = trimmed.isEmpty ? nil : String(trimmed.prefix(500))
        persist()
    }

    func entry(on date: Date = Date()) -> String? { entries[LearningStore.dayKey(date)] }

    /// Newest first.
    var sorted: [(day: String, text: String)] {
        entries.sorted { $0.key > $1.key }.map { (day: $0.key, text: $0.value) }
    }

    func merge(_ incoming: [String: String]) {
        for (day, text) in incoming where entries[day] == nil { entries[day] = text }
        persist()
    }

    func eraseAll() { entries = [:]; persist() }
    private func persist() { UserDefaults.standard.set(entries, forKey: Self.key) }
}

enum JournalPrompt {
    static let all = [
        "What's one thing you learned today, in a sentence?",
        "What surprised you today?",
        "Where could you use today's lesson?",
        "What's still a bit confusing? Write the question down.",
        "How would you explain today's idea to a friend?",
        "What mistake taught you the most today?",
        "What connects today's lesson to something you already knew?",
    ]

    /// A different prompt each day of the week.
    static func forDay(_ date: Date, calendar: Calendar = .current) -> String {
        let weekday = calendar.component(.weekday, from: date)
        return all[(weekday - 1) % all.count]
    }
}

// MARK: - Tough lessons (leeches)

enum ToughLessons {
    /// Lessons that keep going wrong: at least three quizzes at 3/5 or lower, and the
    /// latest one isn't a 5/5 yet. These need a new approach, not just more reviews.
    static func find(records: [String: [LessonQuizRecord]], minLowScores: Int = 3) -> [String] {
        records.compactMap { id, list -> (String, Int)? in
            let low = list.filter { $0.total > 0 && $0.score * 5 <= $0.total * 3 }.count
            guard low >= minLowScores, let last = list.last, last.score < last.total else { return nil }
            return (id, low)
        }
        .sorted { $0.1 == $1.1 ? $0.0 < $1.0 : $0.1 > $1.1 }
        .map(\.0)
    }

    static let tips = [
        "Reread the explanation, then close it and explain it in your own words.",
        "Do \"Complete the code\" for this lesson to see the idea in use.",
        "Look at the related lessons: the mix-up is often with a look-alike.",
        "Take a break and come back tomorrow. Spacing helps hard material most.",
    ]
}

// MARK: - Review forecast

enum ReviewForecast {
    /// Reviews due on each of the next `days` days. Overdue reviews count as today.
    static func days(dueDates: [Date], now: Date = Date(), days: Int = 14, calendar: Calendar = .current) -> [(day: Date, count: Int)] {
        let today = calendar.startOfDay(for: now)
        var counts = Array(repeating: 0, count: days)
        for due in dueDates {
            let day = calendar.startOfDay(for: due)
            let offset = max(0, calendar.dateComponents([.day], from: today, to: day).day ?? 0)
            if offset < days { counts[offset] += 1 }
        }
        return counts.enumerated().map { (day: calendar.date(byAdding: .day, value: $0.offset, to: today) ?? today, count: $0.element) }
    }
}

// MARK: - Lesson of the day

enum LessonOfTheDay {
    /// The same learned lesson all day, a different one tomorrow.
    static func pick(from ids: [String], date: Date = Date()) -> String? {
        guard !ids.isEmpty else { return nil }
        let sorted = ids.sorted()
        var hash: UInt64 = 1469598103934665603
        for byte in LearningStore.dayKey(date).utf8 { hash = (hash ^ UInt64(byte)) &* 1099511628211 }
        return sorted[Int(hash % UInt64(sorted.count))]
    }
}

// MARK: - Quiz combos

enum QuizCombo {
    /// A short cheer at 3, 5 and 10 right answers in a row.
    static func message(for streak: Int) -> String? {
        switch streak {
        case 3: return "3 in a row"
        case 5: return "5 in a row: on fire"
        case 10: return "10 in a row: unstoppable"
        default: return nil
        }
    }
}

// MARK: - Yearly savings on the paywall

enum YearlySavings {
    /// Whole-number percent saved by paying yearly instead of 12 months. Nil under 5%.
    static func percent(monthly: Decimal, yearly: Decimal) -> Int? {
        let twelve = monthly * 12
        guard twelve > 0 else { return nil }
        let saved = (twelve - yearly) / twelve * 100
        let value = Int(truncating: NSDecimalNumber(decimal: saved).rounding(accordingToBehavior:
            NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false,
                                   raiseOnUnderflow: false, raiseOnDivideByZero: false)))
        return value >= 5 ? value : nil
    }
}

// MARK: - New achievements

extension AchievementContext {
    /// Counts from the learning tools, filled in where the context is built.
    struct Extras {
        var perfectQuizzes = 0
        var explanations = 0
        var focusMinutes = 0
        var journalDays = 0
        var certificates = 0
    }

    @MainActor static func currentExtras(lessonsByTrack: [String: [Lesson]], completed: Set<String>,
                                         locked: Set<String>) -> Extras {
        let records = MasteryStore.shared.records
        let perfect = records.values.flatMap { $0 }.filter { $0.total > 0 && $0.score == $0.total }.count
        let certificates = lessonsByTrack.filter { !locked.contains($0.key) }.values.filter { lessons in
            TrackCertificate.isEarned(lessons: lessons, completed: completed, best: { MasteryStore.shared.best($0) })
        }.count
        return Extras(perfectQuizzes: perfect, explanations: ExplainBackStore.shared.notes.count,
                      focusMinutes: FocusStore.shared.minutesByDay.values.reduce(0, +),
                      journalDays: JournalStore.shared.entries.count, certificates: certificates)
    }
}

enum LearningAchievements {
    static let all: [Achievement] = [
        Achievement(id: "perfect-five", title: "Perfect Five", description: "Score 5/5 on a lesson quiz", icon: "star.fill", rarity: .bronze),
        Achievement(id: "perfect-twenty", title: "Flawless", description: "Score 5/5 on 20 lesson quizzes", icon: "star.circle.fill", rarity: .gold),
        Achievement(id: "teacher", title: "Teacher", description: "Explain 10 lessons in your own words", icon: "text.bubble.fill", rarity: .silver),
        Achievement(id: "deep-focus", title: "Deep Focus", description: "Spend 100 minutes in focus sessions", icon: "timer", rarity: .silver),
        Achievement(id: "reflective", title: "Reflective", description: "Write 7 daily reflections", icon: "book.closed.fill", rarity: .silver),
        Achievement(id: "certified", title: "Certified", description: "Earn your first track certificate", icon: "rosette", rarity: .gold),
    ]

    static func condition(_ id: String, _ e: AchievementContext.Extras) -> Bool? {
        switch id {
        case "perfect-five": return e.perfectQuizzes >= 1
        case "perfect-twenty": return e.perfectQuizzes >= 20
        case "teacher": return e.explanations >= 10
        case "deep-focus": return e.focusMinutes >= 100
        case "reflective": return e.journalDays >= 7
        case "certified": return e.certificates >= 1
        default: return nil
        }
    }

    static func progress(_ id: String, _ e: AchievementContext.Extras) -> (current: Int, goal: Int)? {
        switch id {
        case "perfect-five": return (e.perfectQuizzes, 1)
        case "perfect-twenty": return (e.perfectQuizzes, 20)
        case "teacher": return (e.explanations, 10)
        case "deep-focus": return (e.focusMinutes, 100)
        case "reflective": return (e.journalDays, 7)
        case "certified": return (e.certificates, 1)
        default: return nil
        }
    }
}
