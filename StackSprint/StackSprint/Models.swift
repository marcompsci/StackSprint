import Combine
import Foundation
import SwiftUI

struct Lesson: Codable, Identifiable {
    let id: String
    let term: String
    let category: String
    let clue: String
    let definition: String
    let code: String
    let difficulty: String?
}

struct Question: Codable, Identifiable {
    let id: String
    let question: String
    let choices: [String]
    let answer: Int
    let explanation: String
}

struct Curriculum: Codable {
    let lessons: [Lesson]
    let questions: [Question]

    static func load() throws -> Curriculum {
        guard let url = Bundle.main.url(forResource: "curriculum", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
    }
}

// MARK: - Remote Curriculum Loader

enum CurriculumLoader {
    private static let cacheKey = "ss.curriculum.cache"

    /// Returns a previously-fetched remote curriculum if one is cached.
    static func cachedCurriculum() -> Curriculum? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let curriculum = try? JSONDecoder().decode(Curriculum.self, from: data),
              !curriculum.lessons.isEmpty
        else { return nil }
        return curriculum
    }

    /// Fetches a remote curriculum from the configured URL and caches it on success.
    static func fetchRemote(urlString: String) async -> Curriculum? {
        guard !urlString.isEmpty,
              let url = URL(string: urlString),
              url.scheme == "https"
        else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let curriculum = try JSONDecoder().decode(Curriculum.self, from: data)
            guard !curriculum.lessons.isEmpty else { return nil }
            UserDefaults.standard.set(data, forKey: cacheKey)
            return curriculum
        } catch {
            return nil
        }
    }
}

struct ProgressRow: Codable {
    let user_id: String
    let lesson_id: String
}

@MainActor final class LearningStore: ObservableObject {
    @Published var completed: Set<String> = []
    @Published private(set) var practicedDays: Set<String> = []
    @Published private(set) var correctRecallAnswers: Set<String> = []
    /// "yyyy-MM-dd|lessonID" for every day a lesson was finished or practiced again.
    /// The weekly goal counts these, so it measures lessons rather than days.
    @Published private(set) var lessonActivity: Set<String> = []
    @Published var curriculum: Curriculum? { didSet { rebuildIndex() } }
    /// Track names in curriculum order, and each track's lessons, built once per curriculum
    /// instead of being re-filtered on every screen refresh.
    private(set) var tracks: [String] = []
    private(set) var lessonsByTrack: [String: [Lesson]] = [:]
    private var quizCache: [String: [Question]] = [:]
    @Published var error: String?
    private var namespace = "guest"
    /// Runs when XP is earned; the argument is the XP gained (10 per lesson, 5 per quiz answer).
    var onPractice: ((Int) -> Void)?
    /// Runs whenever today counts as practiced, including replays that earn no new XP,
    /// so reminders and widgets know the learner showed up.
    var onActivity: (() -> Void)?

    init() {
        // Bundled JSON is always the safety net
        do { curriculum = try Curriculum.load() } catch { self.error = "Lesson content could not load: \(error.localizedDescription)" }
        // Override with a cached remote version if one exists (it's more up to date)
        if let cached = CurriculumLoader.cachedCurriculum() { curriculum = cached }
        rebuildIndex() // property observers don't run inside init
        switchUser(nil)
    }

    /// Fetches a fresh curriculum from the remote URL configured in BackendConfig.json.
    /// Call once on app launch from a Task so it doesn't block startup.
    func refreshCurriculumIfNeeded() async {
        guard let urlString = BackendConfig.remoteCurriculumURL else { return }
        if let remote = await CurriculumLoader.fetchRemote(urlString: urlString) {
            curriculum = remote
        }
    }

    private func rebuildIndex() {
        let lessons = curriculum?.lessons ?? []
        var order: [String] = []
        var grouped: [String: [Lesson]] = [:]
        for lesson in lessons {
            if grouped[lesson.category] == nil { order.append(lesson.category) }
            grouped[lesson.category, default: []].append(lesson)
        }
        tracks = order
        lessonsByTrack = grouped
        quizCache = [:]
    }

    /// Handwritten questions for the track plus a term question for each of its lessons.
    func quiz(for track: String) -> [Question] {
        if let cached = quizCache[track] { return cached }
        let questions = TrackQuiz.curated(track: track, questions: curriculum?.questions ?? [])
            + TrackQuiz.termQuestions(track: track, lessons: lessonsByTrack[track] ?? [])
        quizCache[track] = questions
        return questions
    }

    /// Lessons finished in a track, and how many it has.
    func progress(in track: String) -> (done: Int, total: Int) {
        let lessons = lessonsByTrack[track] ?? []
        return (lessons.filter { completed.contains($0.id) }.count, lessons.count)
    }

    func switchUser(_ id: String?) {
        namespace = id ?? "guest"
        completed = Set(UserDefaults.standard.stringArray(forKey: "native.completed.\(namespace)") ?? [])
        practicedDays = Set(UserDefaults.standard.stringArray(forKey: "native.practiceDays.\(namespace)") ?? [])
        correctRecallAnswers = Set(UserDefaults.standard.stringArray(forKey: "native.dailyRecall.\(namespace)") ?? [])
        lessonActivity = Set(UserDefaults.standard.stringArray(forKey: "native.lessonActivity.\(namespace)") ?? [])
    }

    func complete(_ id: String) {
        guard !completed.contains(id) else { return }
        completed.insert(id)
        practicedDays.insert(Self.dayKey(Date()))
        lessonActivity.insert("\(Self.dayKey(Date()))|\(id)")
        persist()
        onPractice?(10)
        onActivity?()
    }

    /// Counts today as a practice day without awarding XP: replaying a mastered
    /// lesson, finishing a review or a quiz round keeps the streak alive.
    func recordPractice() {
        let today = Self.dayKey(Date())
        guard !practicedDays.contains(today) else { return }
        practicedDays.insert(today)
        persist()
        onActivity?()
    }

    /// Practicing an already-finished lesson again: counts toward the streak and
    /// the weekly lesson goal, but earns no new XP.
    func recordLessonReplay(_ id: String) {
        let today = Self.dayKey(Date())
        let inserted = lessonActivity.insert("\(today)|\(id)").inserted
        let newDay = practicedDays.insert(today).inserted
        guard inserted || newDay else { return }
        persist()
        onActivity?()
    }

    /// Lessons finished or practiced this week (Monday or Sunday start, per the user's calendar).
    var lessonsThisWeek: Int { WeeklyGoalMath.lessons(in: lessonActivity, weekOf: Date()) }

    /// Lessons finished or practiced today, and quiz questions answered right today.
    var lessonsToday: Int { lessonActivity.filter { $0.hasPrefix(Self.dayKey(Date()) + "|") }.count }
    var quizAnswersToday: Int { correctRecallAnswers.filter { $0.hasPrefix(Self.dayKey(Date()) + "|") }.count }

    var practicedToday: Bool { practicedDays.contains(Self.dayKey(Date())) }

    func recordDailyRecall(_ questionID: String) {
        let key = "\(Self.dayKey(Date()))|\(questionID)"
        guard !correctRecallAnswers.contains(key) else { return }
        correctRecallAnswers.insert(key)
        practicedDays.insert(Self.dayKey(Date()))
        persist()
        onPractice?(5)
        onActivity?()
    }

    func recalledToday(_ questionID: String) -> Bool {
        correctRecallAnswers.contains("\(Self.dayKey(Date()))|\(questionID)")
    }

    var practiceXP: Int { completed.count * 10 + correctRecallAnswers.count * 5 }

    func merge(_ rows: [ProgressRow]) { completed.formUnion(rows.map(\.lesson_id)); persist() }

    /// Clears lessons, practice days, quiz answers and lesson activity for this profile.
    func eraseProgress() {
        completed = []; practicedDays = []; correctRecallAnswers = []; lessonActivity = []
        persist()
        UserDefaults.standard.removeObject(forKey: "stats.bestStreak")
        onActivity?()
    }

    func mergeLessonActivity(_ activity: Set<String>) {
        lessonActivity.formUnion(activity)
        persist()
    }

    func mergeFromCloud(completed: Set<String>, practicedDays: Set<String>, recallAnswers: Set<String>) {
        self.completed.formUnion(completed)
        self.practicedDays.formUnion(practicedDays)
        self.correctRecallAnswers.formUnion(recallAnswers)
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(Array(completed), forKey: "native.completed.\(namespace)")
        UserDefaults.standard.set(Array(practicedDays), forKey: "native.practiceDays.\(namespace)")
        UserDefaults.standard.set(Array(correctRecallAnswers), forKey: "native.dailyRecall.\(namespace)")
        UserDefaults.standard.set(Array(lessonActivity), forKey: "native.lessonActivity.\(namespace)")
    }

    var lastPracticedDate: Date? {
        guard let latest = practicedDays.sorted().last else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: latest)
    }

    /// A streak stays alive until the end of today: if you practiced yesterday
    /// but not yet today, it still shows (and today is when you keep it).
    var currentStreak: Int { StreakMath.current(days: practicedDays, today: Date()) }
    var streakAtRisk: Bool { StreakMath.atRisk(days: practicedDays, today: Date()) }

    /// The longest run of consecutive practice days in the learner's history.
    var bestStreak: Int {
        max(StreakMath.best(days: practicedDays), UserDefaults.standard.integer(forKey: "stats.bestStreak"))
    }

    static func dayKey(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}

// MARK: - Streak maths (pure, unit-tested)

enum StreakMath {
    /// Consecutive practice days ending today, or ending yesterday when today
    /// hasn't been practiced yet (the streak is at risk, not lost).
    static func current(days: Set<String>, today: Date, calendar: Calendar = .current) -> Int {
        var date = calendar.startOfDay(for: today)
        if !days.contains(key(date, calendar)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: date) else { return 0 }
            date = yesterday
        }
        var count = 0
        while days.contains(key(date, calendar)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }
        return count
    }

    /// True when there's a streak to keep and today hasn't been practiced yet.
    static func atRisk(days: Set<String>, today: Date, calendar: Calendar = .current) -> Bool {
        !days.contains(key(today, calendar)) && current(days: days, today: today, calendar: calendar) > 0
    }

    /// The longest run of consecutive days anywhere in the history.
    static func best(days: Set<String>, calendar: Calendar = .current) -> Int {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        let dates = days.compactMap { formatter.date(from: $0) }.map { calendar.startOfDay(for: $0) }.sorted()
        var best = 0, run = 0
        var previous: Date?
        for date in dates {
            if let previous, let next = calendar.date(byAdding: .day, value: 1, to: previous),
               calendar.isDate(next, inSameDayAs: date) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = date
        }
        return best
    }

    static func key(_ date: Date, _ calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}

// MARK: - Weekly goal maths

enum WeeklyGoalMath {
    /// Day keys for the calendar week containing `date`.
    static func weekKeys(containing date: Date, calendar: Calendar = .current) -> Set<String> {
        guard let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start else { return [] }
        return Set((0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
            .map { StreakMath.key($0, calendar) })
    }

    /// Distinct lessons with activity this week (the same lesson on two days counts twice,
    /// the same lesson twice in one day counts once).
    static func lessons(in activity: Set<String>, weekOf date: Date, calendar: Calendar = .current) -> Int {
        let week = weekKeys(containing: date, calendar: calendar)
        return activity.filter { entry in
            guard let day = entry.split(separator: "|", maxSplits: 1).first else { return false }
            return week.contains(String(day))
        }.count
    }
}
