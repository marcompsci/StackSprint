import Testing
import Foundation
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

    @Test func curatedOnlyForTaggedTracks() throws {
        let curriculum = try Curriculum.load()
        #expect(TrackQuiz.curated(track: "Web development", questions: curriculum.questions).count == 25)
        #expect(TrackQuiz.curated(track: "Cybersecurity", questions: curriculum.questions).count == 25)
        #expect(TrackQuiz.curated(track: "Go", questions: curriculum.questions).isEmpty)
    }
}
