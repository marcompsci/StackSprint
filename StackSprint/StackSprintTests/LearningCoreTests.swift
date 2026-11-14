import Testing
import Foundation
import CoreGraphics
@testable import StackSprint

// MARK: - Streaks

@Suite("Streaks")
@MainActor
struct StreakTests {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return c
    }
    private func day(_ string: String) -> Date {
        let f = DateFormatter()
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.date(from: string + " 12:00")!
    }

    @Test func countsThroughToday() {
        let days: Set<String> = ["2026-11-11", "2026-11-12", "2026-11-13"]
        #expect(StreakMath.current(days: days, today: day("2026-11-13"), calendar: calendar) == 3)
        #expect(!StreakMath.atRisk(days: days, today: day("2026-11-13"), calendar: calendar))
    }

    @Test func survivesUntilEndOfToday() {
        // Practiced the last two days, not yet today: the streak is at risk, not gone.
        let days: Set<String> = ["2026-11-11", "2026-11-12"]
        #expect(StreakMath.current(days: days, today: day("2026-11-13"), calendar: calendar) == 2)
        #expect(StreakMath.atRisk(days: days, today: day("2026-11-13"), calendar: calendar))
    }

    @Test func breaksAfterAMissedDay() {
        let days: Set<String> = ["2026-11-10", "2026-11-11"]
        #expect(StreakMath.current(days: days, today: day("2026-11-13"), calendar: calendar) == 0)
        #expect(!StreakMath.atRisk(days: days, today: day("2026-11-13"), calendar: calendar))
    }

    @Test func bestFindsLongestRun() {
        let days: Set<String> = ["2026-01-01", "2026-01-02", "2026-01-03", "2026-01-04",
                                 "2026-02-10", "2026-02-11", "2026-03-01"]
        #expect(StreakMath.best(days: days, calendar: calendar) == 4)
        #expect(StreakMath.best(days: [], calendar: calendar) == 0)
    }

    @Test func bestCrossesMonthAndYear() {
        let days: Set<String> = ["2025-12-30", "2025-12-31", "2026-01-01"]
        #expect(StreakMath.best(days: days, calendar: calendar) == 3)
    }
}

// MARK: - Code checks

@Suite("CodeCheck")
@MainActor
struct CodeCheckTests {
    @Test func curlyQuotesAndTrailingSpacesPass() {
        let expected = "print(\"hi\")\nname = 'Ada'"
        let typed = "print(\u{201C}hi\u{201D})   \n\nname = \u{2018}Ada\u{2019}\n"
        #expect(CodeCheck.compare(typed: typed, expected: expected, keepIndentation: true) == .match)
    }

    @Test func indentationIgnoredOutsidePython() {
        let expected = "if (ok) {\n  go();\n}"
        let typed = "if (ok) {\ngo();\n}"
        #expect(CodeCheck.compare(typed: typed, expected: expected, keepIndentation: false) == .match)
        #expect(CodeCheck.compare(typed: typed, expected: expected, keepIndentation: true) != .match)
    }

    @Test func tabsCountAsSpaces() {
        #expect(CodeCheck.compare(typed: "if x:\n\tprint(x)", expected: "if x:\n    print(x)", keepIndentation: true) == .match)
    }

    @Test func pointsAtFirstDifferentLine() {
        let result = CodeCheck.compare(typed: "a = 1\nb = 3", expected: "a = 1\nb = 2", keepIndentation: false)
        #expect(result == .mismatch(line: 2, expected: "b = 2", typed: "b = 3"))
        #expect(CodeCheck.hint(for: result).contains("Line 2"))
    }

    @Test func missingAndExtraLines() {
        #expect(CodeCheck.compare(typed: "a", expected: "a\nb", keepIndentation: false) == .mismatch(line: 2, expected: "b", typed: ""))
        #expect(CodeCheck.compare(typed: "a\nb", expected: "a", keepIndentation: false) == .mismatch(line: 2, expected: "", typed: "b"))
    }

    @Test func emptyIsNotAFailure() {
        #expect(CodeCheck.compare(typed: "  \n ", expected: "a", keepIndentation: false) == .empty)
    }

    @Test func everyLessonExampleMatchesItself() throws {
        let curriculum = try Curriculum.load()
        for lesson in curriculum.lessons where !lesson.code.isEmpty {
            let keep = CodeCheck.indentationMatters(for: lesson.category)
            #expect(CodeCheck.compare(typed: lesson.code, expected: lesson.code, keepIndentation: keep) == .match, "\(lesson.id)")
        }
    }
}

// MARK: - Review grading

@Suite("ReviewGrade")
@MainActor
struct ReviewGradeTests {
    @Test func firstTryIsEasiest() {
        #expect(ReviewGrade.solved(failedAttempts: 0) == 5)
        #expect(ReviewGrade.solved(failedAttempts: 1) == 4)
        #expect(ReviewGrade.solved(failedAttempts: 6) == 3)
    }

    @Test func unsolvedResetsTheCard() {
        var card = SM2Card.initial(lessonID: "x")
        card.update(quality: 5); card.update(quality: 5)
        #expect(card.interval == 6)
        card.update(quality: ReviewGrade.unsolved)
        #expect(card.interval == 1)
        #expect(card.repetitions == 0)
    }
}

// MARK: - Lesson flow

@Suite("LessonFlow")
@MainActor
struct LessonFlowTests {
    private func lesson(_ id: String, _ track: String) -> Lesson {
        Lesson(id: id, term: id, category: track, clue: "", definition: "def \(id)", code: "", difficulty: nil)
    }

    @Test func nextSkipsFinishedAndWraps() {
        let lessons = [lesson("a", "T"), lesson("b", "T"), lesson("c", "T"), lesson("z", "Other")]
        #expect(LessonFlow.next(after: lessons[0], in: lessons, completed: ["b"])?.id == "c")
        #expect(LessonFlow.next(after: lessons[2], in: lessons, completed: [])?.id == "a")
        #expect(LessonFlow.next(after: lessons[0], in: lessons, completed: ["a", "b", "c"]) == nil)
    }

    @Test func continuePrefersTrackAndSkipsLocked() {
        let lessons = [lesson("g1", "Go"), lesson("w1", "Web"), lesson("w2", "Web"), lesson("p1", "Python")]
        #expect(LessonFlow.continueLesson(in: lessons, completed: ["w1"], preferredTrack: "Web", locked: ["Go"])?.id == "w2")
        #expect(LessonFlow.continueLesson(in: lessons, completed: ["w1", "w2"], preferredTrack: "Web", locked: ["Go"])?.id == "p1")
        #expect(LessonFlow.continueLesson(in: lessons, completed: ["w1", "w2", "p1"], preferredTrack: "Web", locked: ["Go"]) == nil)
    }
}

// MARK: - Track quizzes

@Suite("TrackQuiz")
@MainActor
struct TrackQuizTests {
    @Test func everyTrackGetsAFairQuiz() throws {
        let curriculum = try Curriculum.load()
        let tracks = Set(curriculum.lessons.map(\.category))
        for track in tracks {
            let questions = TrackQuiz.termQuestions(track: track, lessons: curriculum.lessons)
            let lessonCount = curriculum.lessons.filter { $0.category == track }.count
            #expect(questions.count == lessonCount, "\(track)")
            for q in questions {
                #expect(q.choices.count == 4)
                #expect(Set(q.choices).count == 4, "duplicate choices in \(q.id)")
                #expect(q.answer >= 0 && q.answer < q.choices.count)
                let id = try #require(TrackQuiz.lessonID(forQuestion: q.id))
                let lesson = try #require(curriculum.lessons.first { $0.id == id })
                #expect(q.choices[q.answer] == lesson.term)
            }
        }
    }

    @Test func answersAreSpreadAcrossPositions() throws {
        let curriculum = try Curriculum.load()
        let all = Set(curriculum.lessons.map(\.category)).flatMap {
            TrackQuiz.termQuestions(track: $0, lessons: curriculum.lessons)
        }
        let positions = Set(all.map(\.answer))
        #expect(positions.count == 4)
    }

    @Test func stableForTheSameSeed() throws {
        let curriculum = try Curriculum.load()
        let a = TrackQuiz.termQuestions(track: "Rust", lessons: curriculum.lessons, seed: "s")
        let b = TrackQuiz.termQuestions(track: "Rust", lessons: curriculum.lessons, seed: "s")
        #expect(a.map(\.id) == b.map(\.id))
        #expect(a.map(\.choices) == b.map(\.choices))
    }

    @Test func curatedMatchesTracksByPrefix() throws {
        let curriculum = try Curriculum.load()
        #expect(TrackQuiz.curated(track: "Web development", questions: curriculum.questions).count == 25)
        #expect(TrackQuiz.curated(track: "Cybersecurity", questions: curriculum.questions).count == 25)
        #expect(TrackQuiz.curated(track: "Go", questions: curriculum.questions).count == 4)
        #expect(TrackQuiz.curated(track: "Python", questions: curriculum.questions).isEmpty)
    }
}

// MARK: - Search

@Suite("LessonSearch")
@MainActor
struct LessonSearchTests {
    private func lesson(_ id: String, _ term: String, _ definition: String) -> Lesson {
        Lesson(id: id, term: term, category: "T", clue: "", definition: definition, code: "", difficulty: nil)
    }

    @Test func termMatchesRankFirst() {
        let lessons = [lesson("1", "Closures", "functions that capture state"),
                       lesson("2", "State", "data that changes"),
                       lesson("3", "Statements", "lines of code")]
        let results = LessonSearch.results(for: "state", in: lessons).map(\.id)
        #expect(results == ["2", "3", "1"])
    }

    @Test func everyWordMustMatch() {
        let lessons = [lesson("1", "Hash map", "key value lookup"), lesson("2", "Array", "ordered values")]
        #expect(LessonSearch.results(for: "key lookup", in: lessons).map(\.id) == ["1"])
        #expect(LessonSearch.results(for: "   ", in: lessons).isEmpty)
    }

    @Test func findsRealLessons() throws {
        let curriculum = try Curriculum.load()
        #expect(!LessonSearch.results(for: "goroutine", in: curriculum.lessons).isEmpty)
        #expect(LessonSearch.results(for: "zzqqxx", in: curriculum.lessons).isEmpty)
    }
}

// MARK: - Backup

@Suite("ProgressBackup")
@MainActor
struct ProgressBackupTests {
    private func sample() -> ProgressBackup {
        ProgressBackup(exportedAt: Date(timeIntervalSince1970: 1_800_000_000),
                       completedLessons: ["web-html"], practiceDays: ["2026-11-12"],
                       quizAnswers: ["2026-11-12|web-1"],
                       reviewCards: ["web-html": SM2Card.initial(lessonID: "web-html")],
                       bookmarks: ["web-css"], notes: ["web-css": "remember selectors"],
                       completedMissions: ["design-1"], missionDrafts: ["project.design.draft": ".a{}"])
    }

    @Test func roundTrips() throws {
        let backup = sample()
        let decoded = try ProgressBackup.decode(backup.encoded())
        #expect(decoded.completedLessons == backup.completedLessons)
        #expect(decoded.notes == backup.notes)
        #expect(decoded.reviewCards.keys.sorted() == ["web-html"])
        #expect(abs(decoded.exportedAt.timeIntervalSince(backup.exportedAt)) < 1)
    }

    @Test func rejectsOtherFilesAndNewerVersions() throws {
        #expect(throws: ProgressBackup.BackupError.self) { try ProgressBackup.decode(Data("{\"hello\":1}".utf8)) }
        var newer = sample()
        newer.version = ProgressBackup.currentVersion + 1
        let data = try newer.encoded()
        #expect(throws: ProgressBackup.BackupError.self) { try ProgressBackup.decode(data) }
    }

    @Test func reviewMergeKeepsMoreProgress() {
        var ahead = SM2Card.initial(lessonID: "a")
        ahead.update(quality: 5); ahead.update(quality: 5)
        let fresh = SM2Card.initial(lessonID: "a")
        let merged = SM2Engine.merged(["a": fresh], ["a": ahead, "b": SM2Card.initial(lessonID: "b")])
        #expect(merged["a"]?.repetitions == 2)
        #expect(merged["b"] != nil)
        #expect(SM2Engine.merged(["a": ahead], ["a": fresh])["a"]?.repetitions == 2)
    }
}

// MARK: - Phases 11–25

@Suite("WeeklyGoal")
@MainActor
struct WeeklyGoalTests {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        c.firstWeekday = 1 // Sunday
        return c
    }
    private func date(_ s: String) -> Date {
        var parts = DateComponents()
        let p = s.split(separator: "-").compactMap { Int($0) }
        parts.year = p[0]; parts.month = p[1]; parts.day = p[2]; parts.hour = 12
        return calendar.date(from: parts)!
    }

    @Test func countsLessonsNotDays() {
        // Week of Sun 8 Nov – Sat 14 Nov 2026: three lessons on one day count three times.
        let activity: Set<String> = ["2026-11-09|a", "2026-11-09|b", "2026-11-09|c", "2026-11-13|a", "2026-11-07|z"]
        #expect(WeeklyGoalMath.lessons(in: activity, weekOf: date("2026-11-13"), calendar: calendar) == 4)
    }

    @Test func tenAWeekIsReachable() {
        let activity = Set((1...10).map { "2026-11-10|lesson\($0)" })
        #expect(WeeklyGoalMath.lessons(in: activity, weekOf: date("2026-11-12"), calendar: calendar) == 10)
    }
}

@Suite("Reminders")
@MainActor
struct ReminderTests {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return c
    }
    private func at(_ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    @Test func skipsTodayOncePracticed() {
        let dates = NotificationManager.reminderDates(hour: 19, minute: 0, now: at(13, 9), skipToday: true, calendar: calendar)
        #expect(dates.count == NotificationManager.reminderDays)
        #expect(!calendar.isDate(dates[0], inSameDayAs: at(13, 9)))
        #expect(calendar.isDate(dates[0], inSameDayAs: at(14, 9)))
    }

    @Test func keepsTodayWhenNotPracticedAndStillAhead() {
        let dates = NotificationManager.reminderDates(hour: 19, minute: 0, now: at(13, 9), skipToday: false, calendar: calendar)
        #expect(calendar.isDate(dates[0], inSameDayAs: at(13, 9)))
        #expect(calendar.component(.hour, from: dates[0]) == 19)
    }

    @Test func dropsTodayWhenTimeHasPassed() {
        let dates = NotificationManager.reminderDates(hour: 8, minute: 0, now: at(13, 9), skipToday: false, calendar: calendar)
        #expect(calendar.isDate(dates[0], inSameDayAs: at(14, 9)))
    }
}

@Suite("Polish")
@MainActor
struct PolishTests {
    @Test func spotlightIdentifierOpensLesson() {
        let router = LessonRouter.shared
        router.request = nil
        router.open(spotlightIdentifier: LessonRouter.spotlightPrefix + "web-html")
        #expect(router.request == .lesson("web-html"))
        router.request = nil
        router.open(spotlightIdentifier: "something-else")
        #expect(router.request == nil)
    }

    @Test func copyNamesDontCollide() {
        #expect(FreeBuildSession.copyName(for: "Page", taken: ["Page"]) == "Page copy")
        #expect(FreeBuildSession.copyName(for: "Page", taken: ["Page", "Page copy"]) == "Page copy 2")
    }

    @Test func weakestAreLowEaseFirst() {
        let lessons = ["a", "b", "c"].map { Lesson(id: $0, term: $0, category: "T", clue: "", definition: "", code: "", difficulty: nil) }
        var hard = SM2Card.initial(lessonID: "a"); hard.easeFactor = 1.5
        var medium = SM2Card.initial(lessonID: "b"); medium.easeFactor = 2.0
        let easy = SM2Card.initial(lessonID: "c")
        let weak = SM2Engine.weakest(cards: ["a": hard, "b": medium, "c": easy], in: lessons, limit: 5)
        #expect(weak.map(\.id) == ["a", "b"])
    }

    @Test func storeIndexesTracksAndQuizzes() {
        let store = LearningStore()
        #expect(store.tracks.count == 9)
        #expect(store.tracks.first == "Web development")
        #expect(store.quiz(for: "Web development").count == 25 + 12)
        #expect(store.quiz(for: "Go").count == 4 + 10)
        #expect(store.quiz(for: "Python").count == 12)
        #expect(store.progress(in: "Rust").total == 10)
    }

    @Test func versionOneBackupsStillRestore() throws {
        let json = """
        {"version":1,"exportedAt":"2026-11-13T00:00:00Z","completedLessons":["web-html"],"practiceDays":[],
         "quizAnswers":[],"reviewCards":{},"bookmarks":[],"notes":{},"completedMissions":[],"missionDrafts":{}}
        """
        let backup = try ProgressBackup.decode(Data(json.utf8))
        #expect(backup.lessonActivity == nil)
        #expect(backup.completedLessons == ["web-html"])
    }
}


// MARK: - Phases 26–40

@Suite("Honest rewards")
@MainActor
struct HonestRewardTests {
    @Test func everyQuestionHasATrack() throws {
        let curriculum = try Curriculum.load()
        for q in curriculum.questions {
            #expect(QuestionBank.track(forQuestionID: q.id, lessons: curriculum.lessons) != nil, "\(q.id)")
        }
        #expect(QuestionBank.track(forQuestionID: "cyber-3", lessons: []) == "Cybersecurity")
        #expect(QuestionBank.track(forQuestionID: "term-web-html", lessons: curriculum.lessons) == "Web development")
    }

    @Test func freeTracksNeverIncludeProQuestions() throws {
        let store = LearningStore()
        let free = store.tracks.filter { !PremiumStore.proTracks.contains($0) }
        let pool = free.flatMap { store.quiz(for: $0) }
        let curriculum = try Curriculum.load()
        for q in pool {
            let track = QuestionBank.track(forQuestionID: q.id, lessons: curriculum.lessons)
            #expect(!PremiumStore.proTracks.contains(track ?? ""), "\(q.id)")
        }
    }

    @Test func missionsNeedRealProgress() {
        #expect(DailyMission.progress(type: .lessons, lessonsToday: 2, quizAnswersToday: 9, practicedToday: true) == 2)
        #expect(DailyMission.progress(type: .recall, lessonsToday: 2, quizAnswersToday: 9, practicedToday: true) == 9)
        #expect(DailyMission.progress(type: .streak, lessonsToday: 0, quizAnswersToday: 0, practicedToday: false) == 0)
    }

    @Test func weeklyXPOnlyGrows() {
        let weekly = WeeklyXPStore.shared
        let before = weekly.weeklyXP
        weekly.recordXP(10)
        weekly.recordXP(-50)
        #expect(weekly.weeklyXP == before + 10)
        #expect(weekly.daysUntilReset >= 1 && weekly.daysUntilReset <= 7)
    }
}

@Suite("Tutor and portfolio")
@MainActor
struct TutorPortfolioTests {
    private let lesson = Lesson(id: "x", term: "Closures", category: "Swift", clue: "", definition: "Functions that capture values.",
                                code: "let add = { $0 + 1 }", difficulty: "beginner")

    @Test func tutorKnowsTheLesson() {
        let text = TutorViewModel.instructions(for: lesson)
        #expect(text.contains("Closures"))
        #expect(text.contains("let add"))
        #expect(!TutorViewModel.instructions(for: nil).contains("studying"))
    }

    @Test func portfolioListsMissionsAndPrintsLight() {
        let data = PortfolioData(displayName: "Omari <dev>", completedLessons: [lesson], streak: 3, xp: 40,
                                 generatedDate: Date(), studioMissions: ["CSS · Palette Pop"])
        let screen = PortfolioGenerator.html(from: data)
        let print = PortfolioGenerator.html(from: data, forPrint: true)
        #expect(screen.contains("Studio missions"))
        #expect(screen.contains("Omari &lt;dev&gt;"))
        #expect(print.contains("--bg: #ffffff"))
        #expect(!screen.contains("--bg: #ffffff"))
    }

    @Test func longPortfolioSpansPages() throws {
        let many = (0..<80).map { Lesson(id: "l\($0)", term: "Term \($0)", category: "Web development", clue: "",
                                        definition: String(repeating: "A long explanation. ", count: 6), code: "", difficulty: nil) }
        let data = PortfolioData(displayName: "Me", completedLessons: many, streak: 1, xp: 800, generatedDate: Date())
        let pdf = try #require(PortfolioGenerator.pdf(from: data))
        let pages = CGPDFDocument(CGDataProvider(data: pdf as CFData)!)?.numberOfPages ?? 0
        #expect(pages > 1)
    }
}
