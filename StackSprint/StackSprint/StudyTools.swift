import Combine
import Foundation

// MARK: - Phases 101–120: study tools
//
// • Placement check: skip what you already know, but verify it later with a review.
// • Glossary and notes export: everything you've learned, in one searchable place.
// • Answer review, calibration and "mistakes you were sure about".
// • Weak-type drills, a two-minute review for busy days, and a focus timer.

// MARK: - Quiz answers

/// One answered question, kept so the learner can review every answer afterwards.
struct QuizAnswer: Identifiable {
    let question: LessonQuizQuestion
    /// The chosen choice. -1 for a typed answer that didn't match.
    let chosen: Int
    let confidence: AnswerConfidence?
    var id: String { question.id }
    var correct: Bool { chosen == question.answer }
}

extension LessonQuizBuilder {
    /// The lesson a question was built from ("pro-commit-meaning" → "pro-commit").
    static func lessonID(of question: LessonQuizQuestion) -> String {
        let suffix = "-\(question.kind.rawValue)"
        return question.id.hasSuffix(suffix) ? String(question.id.dropLast(suffix.count)) : question.id
    }
}

// MARK: - Placement check

@MainActor final class PlacementStore: ObservableObject {
    static let shared = PlacementStore()
    static let key = "placement.known"
    /// Lessons the learner showed they already know. They're skipped by Continue
    /// but not marked finished, so no XP is given for them.
    @Published private(set) var known: Set<String> = []

    init(defaults: UserDefaults = .standard) {
        known = Set(defaults.stringArray(forKey: Self.key) ?? [])
    }

    func markKnown(_ ids: [String]) {
        known.formUnion(ids)
        persist()
    }

    func merge(_ ids: [String]) { markKnown(ids) }
    func eraseAll() { known = []; persist() }
    private func persist() { UserDefaults.standard.set(Array(known).sorted(), forKey: Self.key) }
}

enum Placement {
    static let size = 8

    /// The first lessons of a track the learner hasn't finished or tested out of.
    static func candidates(track: [Lesson], completed: Set<String>, known: Set<String>, limit: Int = size) -> [Lesson] {
        Array(track.filter { !completed.contains($0.id) && !known.contains($0.id) }.prefix(limit))
    }

    /// One "what it means" question per lesson: the core idea, nothing else.
    static func questions(for lessons: [Lesson], track: [Lesson]) -> [LessonQuizQuestion] {
        lessons.compactMap { LessonQuizBuilder.build(for: $0, in: track).first { $0.kind == .meaning } }
    }

    /// Lessons answered right without guessing. A lucky guess doesn't count as knowing it.
    static func knownLessons(from answers: [QuizAnswer]) -> [String] {
        answers.filter { $0.correct && $0.confidence != .guessing }.map { LessonQuizBuilder.lessonID(of: $0.question) }
    }
}

// MARK: - Glossary

enum Glossary {
    static func entries(_ lessons: [Lesson], query: String = "", track: String? = nil) -> [Lesson] {
        let q = query.trimmingCharacters(in: .whitespaces)
        return lessons
            .filter { track == nil || $0.category == track }
            .filter { q.isEmpty || $0.term.localizedCaseInsensitiveContains(q) || $0.definition.localizedCaseInsensitiveContains(q) }
            .sorted { $0.term.localizedCaseInsensitiveCompare($1.term) == .orderedAscending }
    }

    /// Entries grouped by first letter; digits and symbols go under "#".
    static func sections(_ lessons: [Lesson]) -> [(letter: String, lessons: [Lesson])] {
        var groups: [String: [Lesson]] = [:]
        var order: [String] = []
        for lesson in lessons {
            let first = lesson.term.first.map { String($0).uppercased() } ?? "#"
            let letter = first.range(of: "^[A-Z]$", options: .regularExpression) != nil ? first : "#"
            if groups[letter] == nil { order.append(letter) }
            groups[letter, default: []].append(lesson)
        }
        return order.sorted { ($0 == "#" ? "{" : $0) < ($1 == "#" ? "{" : $1) }.map { (letter: $0, lessons: groups[$0] ?? []) }
    }
}

// MARK: - Study notes export

enum StudyNotesExport {
    /// A Markdown file of everything the learner wrote: notes and explanations, by track.
    static func markdown(lessons: [Lesson], notes: [String: String], explanations: [String: String], date: Date = Date()) -> String {
        let written = lessons.filter {
            !(notes[$0.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !(explanations[$0.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        var out = "# My StackSprint notes\n\nExported \(date.formatted(date: .long, time: .omitted))\n"
        if written.isEmpty { return out + "\nNo notes yet.\n" }
        var tracks: [String] = []
        for lesson in written where !tracks.contains(lesson.category) { tracks.append(lesson.category) }
        for track in tracks {
            out += "\n## \(track)\n"
            for lesson in written where lesson.category == track {
                out += "\n### \(lesson.term)\n\n> \(LessonQuizBuilder.firstSentence(lesson.definition))\n"
                if let mine = explanations[lesson.id], !mine.isEmpty { out += "\n**In my words:** \(mine)\n" }
                if let note = notes[lesson.id], !note.isEmpty { out += "\n**Note:** \(note)\n" }
            }
        }
        return out
    }
}

// MARK: - Calibration and confident mistakes

extension MasteryStore {
    /// How often "Sure" answers were right. Nil until there are at least 10 of them.
    func calibration() -> Double? {
        Self.calibration(records: records)
    }

    static func calibration(records: [String: [LessonQuizRecord]]) -> Double? {
        let all = records.values.flatMap { $0 }
        let sure = all.compactMap(\.sureAnswers).reduce(0, +)
        guard sure >= 10 else { return nil }
        let wrong = all.compactMap(\.confidentMisses).reduce(0, +)
        return Double(max(0, sure - wrong)) / Double(sure)
    }

    /// Lessons whose latest quiz had a wrong answer the learner was sure about, newest first.
    static func confidentMistakes(records: [String: [LessonQuizRecord]]) -> [String] {
        records.compactMap { id, list -> (String, Date)? in
            guard let last = list.last, (last.confidentMisses ?? 0) > 0 else { return nil }
            return (id, last.date)
        }
        .sorted { $0.1 > $1.1 }
        .map(\.0)
    }
}

// MARK: - Weak-type drill and two-minute review

enum TargetedDrill {
    /// Up to `count` questions of one kind, one per lesson.
    static func questions(kind: LessonQuizKind, lessons: [Lesson], all: [Lesson], count: Int = 5) -> [LessonQuizQuestion] {
        var result: [LessonQuizQuestion] = []
        for lesson in lessons where result.count < count {
            let set = LessonQuizBuilder.build(for: lesson, in: all.filter { $0.category == lesson.category })
            if let match = set.first(where: { $0.kind == kind }) { result.append(match) }
        }
        return result
    }

    /// Three questions for busy days: due lessons first, then the most recent ones.
    static func quickReview(due: [Lesson], recent: [Lesson], all: [Lesson], count: Int = 3) -> [LessonQuizQuestion] {
        var lessons: [Lesson] = []
        for lesson in due + recent where !lessons.contains(where: { $0.id == lesson.id }) { lessons.append(lesson) }
        return MixedReview.questions(for: Array(lessons.prefix(count)), all: all, count: count)
    }
}

// MARK: - Focus timer

@MainActor final class FocusStore: ObservableObject {
    static let shared = FocusStore()
    static let key = "focus.minutesByDay"
    @Published private(set) var minutesByDay: [String: Int] = [:]

    init(defaults: UserDefaults = .standard) {
        minutesByDay = defaults.dictionary(forKey: Self.key) as? [String: Int] ?? [:]
    }

    func record(minutes: Int, on date: Date = Date()) {
        guard minutes > 0 else { return }
        minutesByDay[LearningStore.dayKey(date), default: 0] += minutes
        persist()
    }

    func minutes(on date: Date = Date()) -> Int { minutesByDay[LearningStore.dayKey(date)] ?? 0 }

    /// Total over the last 7 days, today included.
    func minutesThisWeek(now: Date = Date(), calendar: Calendar = .current) -> Int {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) }.map { minutes(on: $0) }.reduce(0, +)
    }

    func merge(_ incoming: [String: Int]) {
        for (day, value) in incoming { minutesByDay[day] = max(minutesByDay[day] ?? 0, value) }
        persist()
    }

    func eraseAll() { minutesByDay = [:]; persist() }
    private func persist() { UserDefaults.standard.set(minutesByDay, forKey: Self.key) }
}

enum FocusMath {
    static let lengths = [10, 15, 25]

    /// Fraction of the session done, 0...1.
    static func progress(start: Date, minutes: Int, now: Date) -> Double {
        let total = Double(minutes * 60)
        guard total > 0 else { return 1 }
        return min(1, max(0, now.timeIntervalSince(start) / total))
    }

    /// Whole minutes actually focused, capped at the session length.
    static func focusedMinutes(start: Date, minutes: Int, now: Date) -> Int {
        min(minutes, max(0, Int(now.timeIntervalSince(start) / 60)))
    }

    static func remainingText(start: Date, minutes: Int, now: Date) -> String {
        let left = max(0, Int((Double(minutes * 60) - now.timeIntervalSince(start)).rounded(.up)))
        return String(format: "%d:%02d", left / 60, left % 60)
    }
}

// MARK: - Retest reminder copy

extension ReminderCopy {
    static func retest(_ term: String) -> String {
        "Still remember \(term)? A two-minute check today makes it stick."
    }
}

extension TargetedDrill {
    /// Lesson ids from "day|id" activity entries, most recent day first, no repeats.
    static func recentLessonIDs(_ activity: Set<String>, limit: Int = 10) -> [String] {
        let pairs = activity.compactMap { entry -> (String, String)? in
            let parts = entry.split(separator: "|", maxSplits: 1).map(String.init)
            return parts.count == 2 ? (parts[0], parts[1]) : nil
        }
        var seen = Set<String>()
        var ids: [String] = []
        for (_, id) in pairs.sorted(by: { $0.0 == $1.0 ? $0.1 < $1.1 : $0.0 > $1.0 }) where seen.insert(id).inserted {
            ids.append(id)
            if ids.count == limit { break }
        }
        return ids
    }
}
