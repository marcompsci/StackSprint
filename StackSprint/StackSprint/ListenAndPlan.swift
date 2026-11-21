import Combine
import Foundation

// MARK: - Phases 231–255
//
// • How hard was it? Learners rate each lesson Easy / OK / Hard. Hard lessons come back
//   for review tomorrow and are reviewed first: people's own judgement of difficulty is a
//   useful signal for scheduling (it's how Anki-style systems work).
// • Listen & recall: hands-free review for a walk or commute. The app reads a clue, pauses
//   so you can answer in your head, then says the answer. Still active retrieval.
// • Your first week: a short checklist of the habits that matter most early on.
// • Best study time: when your quiz accuracy is highest, from your own results.
// • A new free track: SQL & Data.

// MARK: - Lesson difficulty

enum LessonFeel: String, Codable, CaseIterable, Identifiable {
    case easy, ok, hard
    var id: String { rawValue }
    var label: String {
        switch self {
        case .easy: return "Easy"
        case .ok: return "OK"
        case .hard: return "Hard"
        }
    }
    var icon: String {
        switch self {
        case .easy: return "hare.fill"
        case .ok: return "hand.thumbsup.fill"
        case .hard: return "tortoise.fill"
        }
    }
}

@MainActor final class LessonFeelStore: ObservableObject {
    static let shared = LessonFeelStore()
    static let key = "lessonFeel.ratings"
    @Published private(set) var ratings: [String: LessonFeel] = [:]

    init(defaults: UserDefaults = .standard) {
        let raw = defaults.dictionary(forKey: Self.key) as? [String: String] ?? [:]
        ratings = raw.compactMapValues(LessonFeel.init(rawValue:))
    }

    func rate(_ lessonID: String, _ feel: LessonFeel) {
        ratings[lessonID] = feel
        persist()
        // A lesson that felt hard comes back tomorrow, whatever the quiz said.
        if feel == .hard { SM2Engine.shared.recordReview(lessonID: lessonID, quality: 2) }
    }

    var hardLessons: Set<String> { Set(ratings.filter { $0.value == .hard }.keys) }

    func merge(_ incoming: [String: String]) {
        for (id, raw) in incoming where ratings[id] == nil {
            if let feel = LessonFeel(rawValue: raw) { ratings[id] = feel }
        }
        persist()
    }

    var exported: [String: String] { ratings.mapValues(\.rawValue) }
    func eraseAll() { ratings = [:]; persist() }
    private func persist() { UserDefaults.standard.set(exported, forKey: Self.key) }
}

extension MixedReview {
    /// Recall estimates adjusted so lessons the learner found hard come first.
    static func weighted(_ candidates: [(lesson: Lesson, recall: Double)], hard: Set<String>) -> [(lesson: Lesson, recall: Double)] {
        candidates.map { (lesson: $0.lesson, recall: hard.contains($0.lesson.id) ? $0.recall * 0.8 : $0.recall) }
    }
}

// MARK: - Listen & recall

struct ListenCard: Equatable {
    let lessonID: String
    let prompt: String
    let answer: String
}

enum ListenRecall {
    static let pauseSeconds = 5

    static func card(for lesson: Lesson) -> ListenCard {
        ListenCard(lessonID: lesson.id,
                   prompt: "What's the term for this? \(lesson.clue)",
                   answer: "\(lesson.term). \(LessonQuizBuilder.firstSentence(lesson.definition))")
    }

    /// Finished lessons, weakest memory first, up to `limit`.
    static func queue(_ candidates: [(lesson: Lesson, recall: Double)], limit: Int = 10) -> [ListenCard] {
        candidates.sorted { $0.recall == $1.recall ? $0.lesson.id < $1.lesson.id : $0.recall < $1.recall }
            .prefix(limit).map { card(for: $0.lesson) }
    }
}

// MARK: - Your first week

struct FirstWeekTask: Identifiable, Equatable {
    let id: String
    let title: String
    let done: Bool
}

struct FirstWeekState {
    var lessonsDone = 0
    var quizzesTaken = 0
    var remindersOn = false
    var explanations = 0
    var arcadePlayed = false
    var brainDumps = 0
    var streak = 0
}

enum FirstWeek {
    static let startKey = "firstWeek.start"
    static let hiddenKey = "firstWeek.hidden"
    static let completedKey = "firstWeek.completed"
    static let days = 14

    static func tasks(_ s: FirstWeekState) -> [FirstWeekTask] {
        [
            FirstWeekTask(id: "lesson", title: "Finish your first lesson", done: s.lessonsDone >= 1),
            FirstWeekTask(id: "quiz", title: "Take a lesson quiz", done: s.quizzesTaken >= 1),
            FirstWeekTask(id: "reminders", title: "Turn on study reminders", done: s.remindersOn),
            FirstWeekTask(id: "explain", title: "Explain a lesson in your own words", done: s.explanations >= 1),
            FirstWeekTask(id: "arcade", title: "Play a round in the Arcade", done: s.arcadePlayed),
            FirstWeekTask(id: "dump", title: "Try a brain dump", done: s.brainDumps >= 1),
            FirstWeekTask(id: "streak", title: "Reach a 3-day streak", done: s.streak >= 3),
        ]
    }

    /// Shown for the first two weeks, until everything is done or the learner hides it.
    static func isVisible(start: Date?, now: Date = Date(), tasks: [FirstWeekTask], hidden: Bool) -> Bool {
        guard !hidden, let start, !tasks.allSatisfy(\.done) else { return false }
        return now.timeIntervalSince(start) < Double(days * 86_400)
    }
}

// MARK: - Best study time

enum StudyTimeOfDay: String, CaseIterable {
    case morning, afternoon, evening, night

    static func of(hour: Int) -> StudyTimeOfDay {
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<22: return .evening
        default: return .night
        }
    }

    var label: String { rawValue }
}

struct BestTime: Equatable {
    let time: StudyTimeOfDay
    let accuracy: Int
    let otherAccuracy: Int
}

enum BestStudyTime {
    static let minimumQuizzes = 3

    /// The part of the day with the highest quiz accuracy, if at least two parts have
    /// three or more quizzes and the best is clearly ahead (5 points or more).
    static func find(records: [String: [LessonQuizRecord]], calendar: Calendar = .current) -> BestTime? {
        var right: [StudyTimeOfDay: Int] = [:], total: [StudyTimeOfDay: Int] = [:], count: [StudyTimeOfDay: Int] = [:]
        for list in records.values {
            for record in list where record.total > 0 {
                let slot = StudyTimeOfDay.of(hour: calendar.component(.hour, from: record.date))
                right[slot, default: 0] += record.score
                total[slot, default: 0] += record.total
                count[slot, default: 0] += 1
            }
        }
        let eligible = StudyTimeOfDay.allCases.filter { (count[$0] ?? 0) >= minimumQuizzes }
        guard eligible.count >= 2 else { return nil }
        let accuracy = eligible.map { ($0, (right[$0] ?? 0) * 100 / max(1, total[$0] ?? 0)) }.sorted { $0.1 > $1.1 }
        let best = accuracy[0], rest = accuracy.dropFirst()
        let restRight = rest.reduce(0) { $0 + (right[$1.0] ?? 0) }
        let restTotal = rest.reduce(0) { $0 + (total[$1.0] ?? 0) }
        let other = restRight * 100 / max(1, restTotal)
        guard best.1 - other >= 5 else { return nil }
        return BestTime(time: best.0, accuracy: best.1, otherAccuracy: other)
    }
}

// MARK: - Free track: SQL & Data

enum FreeContent {
    static let sqlTrack = "SQL & Data"

    static let sql: [Lesson] = [
        Lesson(id: "sql-table", term: "Table", category: sqlTrack,
               clue: "Rows and columns that store one kind of thing.",
               definition: "A table stores data in rows (one per item) and columns (one per detail). A users table might have one row per person and columns for name and email.",
               code: "CREATE TABLE users (\n  id INTEGER PRIMARY KEY,\n  name TEXT,\n  email TEXT\n);", difficulty: "beginner"),
        Lesson(id: "sql-select", term: "SELECT", category: sqlTrack,
               clue: "The command that reads data from a table.",
               definition: "SELECT reads rows from a table. List the columns you want, or use * for all of them. It never changes the data.",
               code: "SELECT name, email FROM users;", difficulty: "beginner"),
        Lesson(id: "sql-where", term: "WHERE", category: sqlTrack,
               clue: "Filters rows so you only get the ones you want.",
               definition: "WHERE keeps only rows that match a condition. Combine conditions with AND and OR.",
               code: "SELECT name FROM users\nWHERE country = 'US' AND age >= 18;", difficulty: "beginner"),
        Lesson(id: "sql-order", term: "ORDER BY", category: sqlTrack,
               clue: "Sorts the rows in the result.",
               definition: "ORDER BY sorts results by one or more columns, ascending by default. Add DESC for largest or newest first, and LIMIT to keep only the top rows.",
               code: "SELECT name, score FROM players\nORDER BY score DESC\nLIMIT 10;", difficulty: "beginner"),
        Lesson(id: "sql-insert", term: "INSERT", category: sqlTrack,
               clue: "Adds new rows to a table.",
               definition: "INSERT INTO adds a row. Name the columns and give a value for each, in the same order.",
               code: "INSERT INTO users (name, email)\nVALUES ('Ada', 'ada@example.com');", difficulty: "beginner"),
        Lesson(id: "sql-update", term: "UPDATE", category: sqlTrack,
               clue: "Changes values in existing rows.",
               definition: "UPDATE changes rows that match a WHERE condition. Without WHERE it changes every row, so always check the condition first.",
               code: "UPDATE users SET email = 'new@example.com'\nWHERE id = 42;", difficulty: "intermediate"),
        Lesson(id: "sql-join", term: "JOIN", category: sqlTrack,
               clue: "Combines rows from two tables that are related.",
               definition: "A JOIN matches rows across tables using a shared column, like orders.user_id and users.id, so you can see each order with its customer's name.",
               code: "SELECT users.name, orders.total\nFROM orders\nJOIN users ON users.id = orders.user_id;", difficulty: "intermediate"),
        Lesson(id: "sql-group", term: "GROUP BY", category: sqlTrack,
               clue: "Collects rows into groups to count or total them.",
               definition: "GROUP BY puts rows with the same value together so you can use COUNT, SUM or AVG on each group, like orders per customer.",
               code: "SELECT user_id, COUNT(*) AS orders\nFROM orders\nGROUP BY user_id;", difficulty: "intermediate"),
        Lesson(id: "sql-key", term: "Primary and foreign keys", category: sqlTrack,
               clue: "Columns that identify rows and link tables together.",
               definition: "A primary key uniquely identifies each row. A foreign key in another table points to it, which keeps related data connected and consistent.",
               code: "CREATE TABLE orders (\n  id INTEGER PRIMARY KEY,\n  user_id INTEGER REFERENCES users(id)\n);", difficulty: "intermediate"),
        Lesson(id: "sql-injection", term: "Parameterised queries", category: sqlTrack,
               clue: "Passing user input separately so it can't change the query.",
               definition: "Never glue user input into SQL text. Use placeholders and pass values separately, so input is always treated as data. This prevents SQL injection.",
               code: "db.query(\"SELECT * FROM users WHERE email = ?\", [email])", difficulty: "intermediate"),
    ]
}
