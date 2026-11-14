import Foundation

// MARK: - Fair code checks
//
// "Recreate this example" used to demand a byte-for-byte match, so a curly quote
// from the keyboard, a trailing space or a missing blank line failed a correct answer.
// The check now ignores what doesn't change the code's meaning and points at the
// first line that really differs.

enum CodeCheck {
    enum Result: Equatable {
        case empty
        case match
        /// `line` is 1-based, counted over non-blank lines of the example.
        case mismatch(line: Int, expected: String, typed: String)
    }

    /// Python cares about indentation; the other lesson languages don't.
    static func indentationMatters(for category: String) -> Bool { category == "Python" }

    static func compare(typed: String, expected: String, keepIndentation: Bool) -> Result {
        let typedLines = normalizedLines(typed, keepIndentation: keepIndentation)
        let expectedLines = normalizedLines(expected, keepIndentation: keepIndentation)
        if typedLines.isEmpty { return .empty }
        for index in 0..<max(typedLines.count, expectedLines.count) {
            let want = index < expectedLines.count ? expectedLines[index] : ""
            let got = index < typedLines.count ? typedLines[index] : ""
            if want != got { return .mismatch(line: index + 1, expected: want, typed: got) }
        }
        return .match
    }

    static func normalizedLines(_ text: String, keepIndentation: Bool) -> [String] {
        straightenQuotes(text)
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\t", with: "    ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .components(separatedBy: "\n")
            .map { line -> String in
                var line = line
                while let last = line.last, last == " " { line.removeLast() }
                if !keepIndentation { line = String(line.drop { $0 == " " }) }
                return line
            }
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    /// iOS keyboards insert typographic quotes and dashes outside code editors.
    static func straightenQuotes(_ text: String) -> String {
        var out = text
        for curly in ["\u{201C}", "\u{201D}", "\u{201E}", "\u{2033}"] { out = out.replacingOccurrences(of: curly, with: "\"") }
        for curly in ["\u{2018}", "\u{2019}", "\u{201A}", "\u{2032}"] { out = out.replacingOccurrences(of: curly, with: "'") }
        return out
    }

    /// One sentence a learner can act on.
    static func hint(for result: Result) -> String {
        switch result {
        case .empty:
            return "Type the example above, then check it."
        case .match:
            return "Nicely done! Make your own version in Studio next."
        case let .mismatch(line, expected, typed):
            if typed.isEmpty { return "Line \(line) is missing. It should be: \(expected)" }
            if expected.isEmpty { return "There's extra code from line \(line): \(typed)" }
            let column = zip(expected, typed).prefix { $0 == $1 }.count + 1
            return "Line \(line), around character \(column). Expected: \(expected)  ·  Yours: \(typed)"
        }
    }
}

// MARK: - Review grading
//
// A lesson visit produces exactly one spaced-repetition grade. Pressing Check
// again after passing used to grade the card again, pushing it weeks into the
// future after a single session.

enum ReviewGrade {
    /// SM-2 quality for a solved example: first try is easy, a few misses is hard.
    static func solved(failedAttempts: Int) -> Int {
        switch failedAttempts {
        case 0: return 5
        case 1: return 4
        default: return 3
        }
    }

    /// Left the lesson after trying and not solving it: review again tomorrow.
    static let unsolved = 2

    /// Concept-only lessons (no code to type) that the learner marks as reviewed.
    static let reviewedConcept = 4
}

// MARK: - Lesson flow

enum LessonFlow {
    /// The next unfinished lesson after `lesson` in the same track, wrapping to
    /// earlier unfinished ones. Nil when the whole track is done.
    static func next(after lesson: Lesson, in lessons: [Lesson], completed: Set<String>) -> Lesson? {
        let track = lessons.filter { $0.category == lesson.category }
        guard let index = track.firstIndex(where: { $0.id == lesson.id }) else { return nil }
        let ordered = track[(index + 1)...] + track[..<index]
        return ordered.first { !completed.contains($0.id) && $0.id != lesson.id }
    }

    /// What "Continue" should open: the first unfinished lesson in the preferred
    /// track, otherwise in any unlocked track. Nil when everything is done.
    static func continueLesson(in lessons: [Lesson], completed: Set<String>,
                               preferredTrack: String, locked: Set<String>) -> Lesson? {
        if let lesson = lessons.first(where: { $0.category == preferredTrack && !locked.contains($0.category) && !completed.contains($0.id) }) {
            return lesson
        }
        return lessons.first { !locked.contains($0.category) && !completed.contains($0.id) }
    }
}

// MARK: - Quizzes for every track
//
// Only Web and Cybersecurity had quizzes. Every track's lessons already pair a
// term with a definition, so a fair multiple-choice round can be built from them:
// the definition is the question, the right term plus three other terms from
// the same track are the choices.

enum TrackQuiz {
    static let termPrefix = "term-"

    static func lessonID(forQuestion id: String) -> String? {
        id.hasPrefix(termPrefix) ? String(id.dropFirst(termPrefix.count)) : nil
    }

    /// Term-matching questions for one track, in a stable order for a given seed.
    static func termQuestions(track: String, lessons: [Lesson], seed: String = "") -> [Question] {
        let pool = lessons.filter { $0.category == track }
        guard pool.count >= 4 else { return [] }
        var rng = SeededGenerator(seed: track + seed)
        return pool.map { lesson in
            let others = pool.filter { $0.id != lesson.id }.shuffled(using: &rng).prefix(3).map(\.term)
            var choices = [lesson.term] + others
            choices.shuffle(using: &rng)
            return Question(
                id: termPrefix + lesson.id,
                question: "Which term matches this? \(lesson.definition)",
                choices: choices,
                answer: choices.firstIndex(of: lesson.term) ?? 0,
                explanation: "\(lesson.term): \(lesson.definition)"
            )
        }
        .shuffled(using: &rng)
    }

    /// Handwritten questions that belong to a track (only Web and Cybersecurity are tagged).
    static func curated(track: String, questions: [Question]) -> [Question] {
        switch track {
        case "Web development": return questions.filter { $0.id.hasPrefix("web-") }
        case "Cybersecurity": return questions.filter { $0.id.hasPrefix("cyber-") }
        default: return []
        }
    }
}

/// A small deterministic random generator (SplitMix64) so quizzes and tests are repeatable.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: String) {
        // FNV-1a over UTF-8: stable across launches, unlike String.hashValue.
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in seed.utf8 { hash = (hash ^ UInt64(byte)) &* 0x100000001b3 }
        state = hash
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}

// MARK: - Lesson search

enum LessonSearch {
    /// Lessons matching every word of the query, best matches first:
    /// term starts with the query, then term contains it, then the explanation does.
    static func results(for query: String, in lessons: [Lesson]) -> [Lesson] {
        let words = query.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return [] }
        let whole = words.joined(separator: " ")
        func haystack(_ l: Lesson) -> String {
            [l.term, l.category, l.clue, l.definition, l.code].joined(separator: " ").lowercased()
        }
        func rank(_ l: Lesson) -> Int {
            let term = l.term.lowercased()
            if term == whole { return 0 }
            if term.hasPrefix(whole) { return 1 }
            if term.contains(whole) { return 2 }
            if words.allSatisfy(term.contains) { return 3 }
            return 4
        }
        return lessons
            .filter { lesson in let text = haystack(lesson); return words.allSatisfy(text.contains) }
            .enumerated()
            .sorted { (rank($0.element), $0.offset) < (rank($1.element), $1.offset) }
            .map(\.element)
    }
}
