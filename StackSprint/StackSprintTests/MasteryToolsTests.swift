import Testing
import Foundation
@testable import StackSprint

private func lesson(_ id: String, _ term: String, track: String = "T", clue: String = "clue",
                    definition: String = "A definition.", code: String = "") -> Lesson {
    Lesson(id: id, term: term, category: track, clue: clue, definition: definition, code: code, difficulty: nil)
}

private var utc: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}

@Suite("Complete the code")
@MainActor
struct CodeClozeTests {
    @Test func blanksAWordFromTheLesson() throws {
        let item = lesson("v", "Variable", definition: "A variable stores a value you can change later.",
                          code: "var score = 0\nscore += 10")
        let cloze = try #require(CodeClozeBuilder.make(for: item))
        #expect(cloze.prompt.contains("____"))
        #expect(item.code.contains(cloze.answer))
        #expect(cloze.answer.count >= 3)
        // Putting the answer back gives the original code.
        #expect(cloze.prompt.replacingOccurrences(of: "____", with: cloze.answer) == item.code
                || item.code.components(separatedBy: cloze.answer).count > 2)
    }

    @Test func prefersAWordThatAppearsInTheDefinition() throws {
        let item = lesson("l", "Loop", definition: "A loop repeats code for each item in a list.",
                          code: "for item in items {\n    render(item)\n}")
        let cloze = try #require(CodeClozeBuilder.make(for: item))
        #expect(cloze.answer == "item" || cloze.answer == "items")
    }

    @Test func noCodeNoCloze() {
        #expect(CodeClozeBuilder.make(for: lesson("x", "X")) == nil)
    }

    @Test func checkingIgnoresCaseAndSpaces() {
        let cloze = CodeCloze(prompt: "____ x = 1", answer: "let")
        #expect(CodeClozeBuilder.isCorrect(" LET ", cloze))
        #expect(!CodeClozeBuilder.isCorrect("var", cloze))
    }
}

@Suite("Related, tough and forecast")
@MainActor
struct RelatedTests {
    @Test func relatedLessonsShareWording() {
        let a = lesson("a", "Unit test", definition: "A unit test checks one function automatically with known input.")
        let b = lesson("b", "Integration test", definition: "An integration test checks several parts working together automatically.")
        let c = lesson("c", "Color", definition: "Colors set the mood of a page.")
        let related = RelatedLessons.find(for: a, in: [a, b, c])
        #expect(related.map(\.id) == ["b"])
    }

    @Test func toughLessonsNeedThreeLowScores() {
        func r(_ s: Int) -> LessonQuizRecord { LessonQuizRecord(date: Date(), score: s, total: 5, missed: []) }
        let records = ["hard": [r(2), r(3), r(1), r(4)], "fixed": [r(2), r(2), r(3), r(5)], "ok": [r(2), r(5)]]
        #expect(ToughLessons.find(records: records) == ["hard"])
    }

    @Test func forecastCountsOverdueAsToday() {
        let cal = utc
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let dates = [now.addingTimeInterval(-86_400 * 3), now, now.addingTimeInterval(86_400 * 2), now.addingTimeInterval(86_400 * 30)]
        let days = ReviewForecast.days(dueDates: dates, now: now, days: 14, calendar: cal)
        #expect(days.count == 14)
        #expect(days[0].count == 2)
        #expect(days[2].count == 1)
        #expect(days.map(\.count).reduce(0, +) == 3)
    }
}

@Suite("Daily extras")
@MainActor
struct DailyExtrasTests {
    @Test func lessonOfTheDayIsStableForADay() {
        let ids = ["a", "b", "c", "d", "e"]
        let day = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(LessonOfTheDay.pick(from: ids, date: day) == LessonOfTheDay.pick(from: ids.reversed(), date: day))
        #expect(LessonOfTheDay.pick(from: [], date: day) == nil)
        let picks = Set((0..<10).compactMap { LessonOfTheDay.pick(from: ids, date: day.addingTimeInterval(Double($0) * 86_400)) })
        #expect(picks.count > 1)
    }

    @Test func journalPromptsRotateByWeekday() {
        let cal = utc
        let monday = Date(timeIntervalSince1970: 1_799_971_200) // any start day: 7 days in a row cover every weekday
        let prompts = Set((0..<7).map { JournalPrompt.forDay(monday.addingTimeInterval(Double($0) * 86_400), calendar: cal) })
        #expect(prompts.count == 7)
    }

    @Test func comboMessages() {
        #expect(QuizCombo.message(for: 3) != nil)
        #expect(QuizCombo.message(for: 4) == nil)
        #expect(QuizCombo.message(for: 10)?.contains("10") == true)
    }

    @Test func yearlySavingsRounds() {
        #expect(YearlySavings.percent(monthly: Decimal(string: "4.99")!, yearly: Decimal(string: "39.99")!) == 33)
        #expect(YearlySavings.percent(monthly: 5, yearly: 59) == nil)  // under 5%
        #expect(YearlySavings.percent(monthly: 0, yearly: 10) == nil)
    }
}

@Suite("Learning achievements and content")
@MainActor
struct LearningAchievementTests {
    @Test func conditionsAndProgress() {
        var extras = AchievementContext.Extras()
        #expect(LearningAchievements.condition("perfect-five", extras) == false)
        extras.perfectQuizzes = 1
        extras.focusMinutes = 120
        #expect(LearningAchievements.condition("perfect-five", extras) == true)
        #expect(LearningAchievements.condition("deep-focus", extras) == true)
        #expect(LearningAchievements.condition("first-spark", extras) == nil)
        #expect(LearningAchievements.progress("teacher", extras)?.goal == 10)
    }

    @Test func newAchievementsAreInTheTrophyRoom() {
        let ids = Set(AchievementStore.allAchievements.map(\.id))
        #expect(LearningAchievements.all.allSatisfy { ids.contains($0.id) })
        #expect(ids.count == AchievementStore.allAchievements.count)
    }

    @Test func paidContentIdsAreUnique() {
        let ids = (PaidContent.ai + PaidContent.professional).map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(ClaimChecks.all.count == 12 && BugHunts.all.count == 12)
    }
}
