import Combine
import Foundation

// MARK: - What the research says, and how this file uses it
//
// • Retrieval practice (the testing effect): pulling an answer out of memory makes it
//   stick far better than rereading. Roediger & Karpicke (2006); meta-analyses put the
//   effect around g = 0.5.  → Every lesson ends with a 5-question quiz.
// • Spacing: reviews spread over days beat cramming (g ≈ 0.7).  → Quiz results set the
//   next review date.
// • Forgetting curve / half-life: recall probability decays as p = 2^(-Δ/h), where Δ is
//   time since practice and h the memory's half-life (Settles & Meeder, Duolingo 2016).
//   → MemoryModel estimates how well each lesson is remembered right now.
// • Pretesting / generation: guessing before you're told primes memory, even when the
//   guess is wrong, as long as feedback follows.  → "Quick guess" before the reveal.
// • Discrimination / interleaving: telling similar ideas apart improves transfer.
//   → One question in each quiz contrasts the lesson with its most similar neighbour.
// • Intensive courses (e.g. the Defense Language Institute) pair daily study, heavy
//   active recall and frequent testing.  → Short daily target, daily reviews, tests.

// MARK: - End-of-lesson quiz

enum LessonQuizKind: String, Codable, CaseIterable {
    case meaning, recall, keyDetail, application, discrimination

    /// Most important first: what it means, then naming it, then details.
    var priority: Int { Self.allCases.firstIndex(of: self) ?? 0 }

    var label: String {
        switch self {
        case .meaning: return "What it means"
        case .recall: return "Name it"
        case .keyDetail: return "Key detail"
        case .application: return "Spot it in use"
        case .discrimination: return "Tell it apart"
        }
    }
}

struct LessonQuizQuestion: Identifiable, Equatable {
    let id: String
    let kind: LessonQuizKind
    let prompt: String
    let choices: [String]
    let answer: Int
    let explanation: String
}

enum LessonQuizBuilder {
    static let questionCount = 5

    /// Five questions about one lesson, most important first. Wrong choices come from
    /// other lessons in the same track, so they're plausible. Deterministic per lesson.
    static func build(for lesson: Lesson, in lessons: [Lesson]) -> [LessonQuizQuestion] {
        let others = lessons.filter { $0.category == lesson.category && $0.id != lesson.id && $0.term != lesson.term }
        guard others.count >= 3 else { return [] }
        var rng = SeededGenerator(seed: "lesson-quiz|" + lesson.id)
        var questions: [LessonQuizQuestion] = []

        // 1. Meaning: which description is right?
        // Each description hides its own term, so the wording can't give the answer away.
        let meaningWrong = others.shuffled(using: &rng).prefix(3).map { mask(firstSentence($0.definition), terms: [$0.term]) }
        questions.append(make(lesson, .meaning, "Which best describes \(lesson.term)?",
                              correct: mask(firstSentence(lesson.definition), terms: [lesson.term]), wrong: Array(meaningWrong), rng: &rng,
                              explanation: lesson.definition))

        // 2. Recall: name the idea from its clue (a different cue than the definition).
        let recallWrong = others.shuffled(using: &rng).prefix(3).map(\.term)
        questions.append(make(lesson, .recall, "Which term matches this? \(mask(lesson.clue, terms: [lesson.term]))",
                              correct: lesson.term, wrong: Array(recallWrong), rng: &rng,
                              explanation: "\(lesson.term): \(lesson.clue)"))

        // 3. Key detail: fill the most important missing word.
        if let cloze = cloze(for: lesson, others: others, rng: &rng) {
            questions.append(cloze)
        } else {
            questions.append(trueFalse(lesson, others: others, rng: &rng))
        }

        // 4. Application: spot the example, or judge a statement.
        let withCode = others.filter { !firstCodeLine($0.code).isEmpty }
        if !firstCodeLine(lesson.code).isEmpty && withCode.count >= 3 {
            let wrong = withCode.shuffled(using: &rng).prefix(3).map { firstCodeLine($0.code) }
            questions.append(make(lesson, .application, "Which example is about \(lesson.term)?",
                                  correct: firstCodeLine(lesson.code), wrong: Array(wrong), rng: &rng,
                                  explanation: "The example for \(lesson.term) starts: \(firstCodeLine(lesson.code))"))
        } else {
            questions.append(trueFalse(lesson, others: others, rng: &rng, kind: .application))
        }

        // 5. Discrimination: the most similar lesson, side by side.
        let neighbour = mostSimilar(to: lesson, in: others)
        var pair = [lesson.term, neighbour.term]
        pair.shuffle(using: &rng)
        questions.append(LessonQuizQuestion(
            id: "\(lesson.id)-discrimination", kind: .discrimination,
            prompt: "\(lesson.term) or \(neighbour.term)? \(mask(firstSentence(lesson.definition), terms: [lesson.term, neighbour.term]))",
            choices: pair, answer: pair.firstIndex(of: lesson.term) ?? 0,
            explanation: "\(lesson.term): \(firstSentence(lesson.definition)) \(neighbour.term): \(firstSentence(neighbour.definition))"))

        return Array(questions.sorted { $0.kind.priority < $1.kind.priority }.prefix(questionCount))
    }

    // MARK: Pieces

    private static func make(_ lesson: Lesson, _ kind: LessonQuizKind, _ prompt: String, correct: String,
                             wrong: [String], rng: inout SeededGenerator, explanation: String) -> LessonQuizQuestion {
        var choices = [correct] + wrong.filter { $0 != correct }
        var seen = Set<String>()
        choices = choices.filter { seen.insert($0).inserted }
        choices.shuffle(using: &rng)
        return LessonQuizQuestion(id: "\(lesson.id)-\(kind.rawValue)", kind: kind, prompt: prompt,
                                  choices: choices, answer: choices.firstIndex(of: correct) ?? 0, explanation: explanation)
    }

    private static func trueFalse(_ lesson: Lesson, others: [Lesson], rng: inout SeededGenerator,
                                  kind: LessonQuizKind = .keyDetail) -> LessonQuizQuestion {
        let tellTruth = Bool.random(using: &rng)
        let other = others.randomElement(using: &rng) ?? lesson
        let claim = mask(tellTruth ? firstSentence(lesson.definition) : firstSentence(other.definition),
                         terms: [lesson.term, other.term])
        let statement = "True or false: this describes \(lesson.term). \(claim)"
        return LessonQuizQuestion(id: "\(lesson.id)-\(kind.rawValue)", kind: kind, prompt: statement,
                                  choices: ["True", "False"], answer: tellTruth ? 0 : 1,
                                  explanation: tellTruth ? lesson.definition
                                  : "False. That describes \(other.term). \(lesson.term): \(firstSentence(lesson.definition))")
    }

    /// Blanks a key word in the first sentence (not the term, not a filler word).
    private static func cloze(for lesson: Lesson, others: [Lesson], rng: inout SeededGenerator) -> LessonQuizQuestion? {
        let sentence = firstSentence(lesson.definition)
        let termWords = Set(lesson.term.lowercased().split { !$0.isLetter }.map(String.init))
        let words = sentence.split(separator: " ").map(String.init)
        let candidates = words.map(cleanWord).enumerated().filter { _, word in
            word.count >= 5 && !stopWords.contains(word.lowercased()) && !termWords.contains(word.lowercased())
        }
        // The core of a definition sits early ("X is the structure of..."), so prefer the
        // longest word in the first half, skipping the first two words; else the longest anywhere.
        let core = candidates.filter { $0.offset >= 2 && $0.offset < max(4, words.count / 2) }
        guard let target = (core.isEmpty ? candidates : core).max(by: { $0.element.count < $1.element.count }) else { return nil }
        let answer = target.element
        let pool = Set(others.flatMap { firstSentence($0.definition).split(separator: " ").map(String.init).map(cleanWord) })
            .filter { $0.count >= 4 && !stopWords.contains($0.lowercased()) && $0.lowercased() != answer.lowercased() }
            .sorted()
        guard pool.count >= 3 else { return nil }
        let wrong = Array(pool.shuffled(using: &rng).prefix(3))
        var blanked = words
        blanked[target.offset] = words[target.offset].replacingOccurrences(of: answer, with: "_____")
        return make(lesson, .keyDetail, "Fill the gap: \(blanked.joined(separator: " "))",
                    correct: answer, wrong: wrong, rng: &rng, explanation: sentence)
    }

    private static func mostSimilar(to lesson: Lesson, in others: [Lesson]) -> Lesson {
        let mine = Set(words(in: lesson.definition + " " + lesson.clue))
        return others.max { a, b in
            mine.intersection(words(in: a.definition + " " + a.clue)).count
                < mine.intersection(words(in: b.definition + " " + b.clue)).count
        } ?? others[0]
    }

    private static func words(in text: String) -> [String] {
        text.lowercased().split { !$0.isLetter }.map(String.init).filter { $0.count >= 4 && !stopWords.contains($0) }
    }

    /// Replaces each term (any letter case) with a blank.
    static func mask(_ text: String, terms: [String]) -> String {
        terms.filter { !$0.isEmpty }.sorted { $0.count > $1.count }.reduce(text) {
            $0.replacingOccurrences(of: $1, with: "___", options: .caseInsensitive)
        }
    }

    static func firstSentence(_ text: String) -> String {
        if let end = text.firstIndex(where: { ".!?".contains($0) }) {
            return String(text[...end]).trimmingCharacters(in: .whitespaces)
        }
        return text
    }

    static func firstCodeLine(_ code: String) -> String {
        code.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty && !$0.hasPrefix("//") && !$0.hasPrefix("#") } ?? ""
    }

    private static func cleanWord(_ word: String) -> String {
        word.trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.symbols))
    }

    private static let stopWords: Set<String> = [
        "about", "after", "again", "because", "before", "being", "between", "could", "every", "other", "their",
        "there", "these", "thing", "things", "those", "through", "under", "until", "using", "where", "which",
        "while", "would", "should", "something", "someone", "people", "makes", "lets", "helps", "often", "never",
        "always", "first", "small", "really", "right", "when", "what", "with", "that", "this", "from", "your",
        "into", "they", "them", "than", "then", "have", "will", "also", "just", "like", "more", "most", "some",
    ]

    /// Spaced-review quality (SM-2 scale) from a quiz score out of five.
    static func reviewQuality(score: Int, of total: Int = questionCount) -> Int {
        guard total > 0 else { return 3 }
        switch Double(score) / Double(total) {
        case 1: return 5
        case 0.8...: return 4
        case 0.6...: return 3
        default: return ReviewGrade.unsolved
        }
    }
}

// MARK: - Mastery: every lesson quiz you've taken

struct LessonQuizRecord: Codable, Equatable {
    let date: Date
    let score: Int
    let total: Int
    /// Which kinds of question were missed, so weak spots are specific.
    let missed: [LessonQuizKind]
    /// Right answers the learner marked as guesses (nil in records from before confidence checks).
    var luckyGuesses: Int? = nil
    /// Wrong answers the learner was sure about: the ones most worth a second look.
    var confidentMisses: Int? = nil
    /// How many answers were marked "Sure" (nil when confidence wasn't asked).
    var sureAnswers: Int? = nil
}

@MainActor final class MasteryStore: ObservableObject {
    static let shared = MasteryStore()
    static let key = "mastery.records"

    @Published private(set) var records: [String: [LessonQuizRecord]] = [:]

    init(defaults: UserDefaults = .standard) {
        if let data = defaults.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode([String: [LessonQuizRecord]].self, from: data) {
            records = decoded
        }
    }

    func record(lessonID: String, score: Int, total: Int, missed: [LessonQuizKind], date: Date = Date(),
                luckyGuesses: Int? = nil, confidentMisses: Int? = nil, sureAnswers: Int? = nil) {
        records[lessonID, default: []].append(LessonQuizRecord(date: date, score: score, total: total, missed: missed,
                                                               luckyGuesses: luckyGuesses, confidentMisses: confidentMisses,
                                                               sureAnswers: sureAnswers))
        if records[lessonID]!.count > 20 { records[lessonID]!.removeFirst(records[lessonID]!.count - 20) }
        persist()
    }

    func latest(_ lessonID: String) -> LessonQuizRecord? { records[lessonID]?.last }
    func best(_ lessonID: String) -> Int? { records[lessonID]?.map(\.score).max() }

    enum Level: String { case new = "New", learning = "Learning", mastered = "Mastered" }

    /// Mastered: a perfect quiz, or two 4+/5 results on different days.
    static func level(for records: [LessonQuizRecord]) -> Level {
        guard !records.isEmpty else { return .new }
        if records.contains(where: { $0.score == $0.total }) { return .mastered }
        let strongDays = Set(records.filter { $0.score * 5 >= $0.total * 4 }.map { Calendar.current.startOfDay(for: $0.date) })
        return strongDays.count >= 2 ? .mastered : .learning
    }

    func level(_ lessonID: String) -> Level { Self.level(for: records[lessonID] ?? []) }

    /// Accuracy per calendar week (oldest first), for the progress chart.
    func weeklyAccuracy(weeks: Int = 8, now: Date = Date(), calendar: Calendar = .current) -> [(weekStart: Date, accuracy: Double?)] {
        guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        let all = records.values.flatMap { $0 }
        return (0..<weeks).reversed().compactMap { back -> (Date, Double?)? in
            guard let start = calendar.date(byAdding: .weekOfYear, value: -back, to: thisWeek),
                  let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) else { return nil }
            let inWeek = all.filter { $0.date >= start && $0.date < end }
            let total = inWeek.reduce(0) { $0 + $1.total }
            return (start, total == 0 ? nil : Double(inWeek.reduce(0) { $0 + $1.score }) / Double(total))
        }
    }

    /// The question kinds missed most across all quizzes.
    var weakestKinds: [(kind: LessonQuizKind, misses: Int)] {
        var counts: [LessonQuizKind: Int] = [:]
        for record in records.values.flatMap({ $0 }) { for kind in record.missed { counts[kind, default: 0] += 1 } }
        return counts.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }

    func merge(_ incoming: [String: [LessonQuizRecord]]) {
        for (id, list) in incoming {
            let existing = Set((records[id] ?? []).map(\.date))
            records[id, default: []].append(contentsOf: list.filter { !existing.contains($0.date) })
            records[id]?.sort { $0.date < $1.date }
        }
        persist()
    }

    func eraseAll() { records = [:]; persist() }

    private func persist() {
        if let data = try? JSONEncoder().encode(records) { UserDefaults.standard.set(data, forKey: Self.key) }
    }
}

// MARK: - Memory strength (forgetting curve)

enum MemoryModel {
    /// Reviews are scheduled for when recall drops to about 90%.
    static let targetRecall = 0.9

    /// Half-life in days implied by a review interval: p(interval) = targetRecall.
    static func halfLife(intervalDays: Int) -> Double {
        Double(max(intervalDays, 1)) / -log2(targetRecall)
    }

    /// Estimated chance of recalling the lesson now: p = 2^(-Δ/h).
    static func recall(card: SM2Card, now: Date = Date()) -> Double {
        let last = Calendar.current.date(byAdding: .day, value: -max(card.interval, 1), to: card.dueDate) ?? card.dueDate
        let elapsed = max(0, now.timeIntervalSince(last) / 86_400)
        return pow(2, -elapsed / halfLife(intervalDays: card.interval))
    }

    enum Band: String { case strong = "Strong", okay = "Holding", fading = "Fading" }

    static func band(_ p: Double) -> Band { p >= 0.95 ? .strong : p >= targetRecall ? .okay : .fading }
}

// MARK: - Study routine (for reminders at the time you usually practice)

@MainActor enum StudyRoutine {
    static let key = "routine.sessionHours"

    /// Records the hour of the day's first study session (keeps the last 20 days).
    static func recordSession(at date: Date = Date(), defaults: UserDefaults = .standard) {
        let day = StreakMath.key(date, .current)
        guard defaults.string(forKey: "routine.lastDay") != day else { return }
        defaults.set(day, forKey: "routine.lastDay")
        var hours = defaults.array(forKey: key) as? [Int] ?? []
        hours.append(Calendar.current.component(.hour, from: date))
        if hours.count > 20 { hours.removeFirst(hours.count - 20) }
        defaults.set(hours, forKey: key)
    }

    /// The hour you usually study, once there are at least 5 sessions to go on.
    static func usualHour(defaults: UserDefaults = .standard) -> Int? {
        usualHour(from: defaults.array(forKey: key) as? [Int] ?? [])
    }

    nonisolated static func usualHour(from hours: [Int]) -> Int? {
        guard hours.count >= 5 else { return nil }
        let counts = Dictionary(grouping: hours, by: { $0 }).mapValues(\.count)
        let top = counts.values.max() ?? 0
        // The most common hour; ties go to the latest hour seen.
        return hours.reversed().first { counts[$0] == top }
    }
}

// MARK: - Reminder wording that doesn't go stale

enum ReminderCopy {
    static let recentKey = "reminders.recentTemplates"

    /// Fading-memory reminders say how many lessons need a review that day.
    static func fading(count: Int) -> String {
        count == 1 ? "1 lesson is starting to fade. A 2-minute review locks it in."
                   : "\(count) lessons are starting to fade. A quick review locks them in."
    }

    static let daily = [
        "Two minutes now beats an hour later. Your next lesson is ready.",
        "Quick check-in: one lesson and a 5-question quiz.",
        "Your streak is waiting. One small lesson keeps it going.",
        "Practice a little today so it sticks tomorrow.",
        "New lesson unlocked. See if you can ace the quiz.",
    ]

    /// Picks a message, avoiding the ones used most recently: a message loses its pull
    /// when it's seen over and over (the "novelty effect" Duolingo reports).
    static func pick(from options: [String], recent: [String]) -> String {
        options.first { !recent.contains($0) } ?? options.min { (recent.lastIndex(of: $0) ?? -1) < (recent.lastIndex(of: $1) ?? -1) } ?? options[0]
    }
}
