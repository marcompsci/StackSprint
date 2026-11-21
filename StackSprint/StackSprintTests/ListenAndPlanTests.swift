import Testing
import Foundation
@testable import StackSprint

private func lesson(_ id: String, _ term: String) -> Lesson {
    Lesson(id: id, term: term, category: "T", clue: "Clue for \(term)",
           definition: "\(term) does something. More detail here.", code: "", difficulty: nil)
}

@Suite("Lesson difficulty and listening")
@MainActor
struct ListenTests {
    @Test func hardLessonsAreWeightedFirst() {
        let a = lesson("a", "A"), b = lesson("b", "B")
        let weighted = MixedReview.weighted([(lesson: a, recall: 0.9), (lesson: b, recall: 0.8)], hard: ["a"])
        #expect(abs(weighted[0].recall - 0.72) < 0.0001)
        #expect(weighted[1].recall == 0.8)
        #expect(MixedReview.pickLessons(weighted, limit: 1).first?.id == "a")
    }

    @Test func listenCardsAskThenAnswer() {
        let card = ListenRecall.card(for: lesson("x", "Closure"))
        #expect(card.prompt.contains("Clue for Closure"))
        #expect(!card.prompt.contains("Closure."))
        #expect(card.answer == "Closure. Closure does something.")
    }

    @Test func listenQueueIsWeakestFirst() {
        let queue = ListenRecall.queue([(lesson: lesson("a", "A"), recall: 0.9), (lesson: lesson("b", "B"), recall: 0.2)], limit: 1)
        #expect(queue.map(\.lessonID) == ["b"])
    }
}

@Suite("First week and best time")
@MainActor
struct FirstWeekTests {
    @Test func tasksReflectState() {
        var s = FirstWeekState()
        #expect(FirstWeek.tasks(s).allSatisfy { !$0.done })
        s.lessonsDone = 1; s.quizzesTaken = 1; s.remindersOn = true; s.explanations = 1
        s.arcadePlayed = true; s.brainDumps = 1; s.streak = 3
        #expect(FirstWeek.tasks(s).allSatisfy(\.done))
        #expect(FirstWeek.tasks(s).count == 7)
    }

    @Test func visibleForTwoWeeksUntilDone() {
        let start = Date(timeIntervalSince1970: 0)
        let open = FirstWeek.tasks(FirstWeekState())
        #expect(FirstWeek.isVisible(start: start, now: start.addingTimeInterval(86_400), tasks: open, hidden: false))
        #expect(!FirstWeek.isVisible(start: start, now: start.addingTimeInterval(15 * 86_400), tasks: open, hidden: false))
        #expect(!FirstWeek.isVisible(start: start, now: start, tasks: open, hidden: true))
        #expect(!FirstWeek.isVisible(start: nil, tasks: open, hidden: false))
    }

    @Test func bestStudyTimeNeedsDataAndAClearWinner() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let day = Date(timeIntervalSince1970: 1_800_000_000 - 1_800_000_000.truncatingRemainder(dividingBy: 86_400))
        func at(_ hour: Int, _ score: Int) -> LessonQuizRecord {
            LessonQuizRecord(date: day.addingTimeInterval(Double(hour) * 3600), score: score, total: 5, missed: [])
        }
        let records = ["a": [at(8, 5), at(9, 5), at(10, 4)], "b": [at(19, 3), at(20, 3), at(21, 2)]]
        let best = BestStudyTime.find(records: records, calendar: cal)
        #expect(best?.time == .morning)
        #expect(best?.accuracy == 93)
        #expect(best?.otherAccuracy == 53)
        #expect(BestStudyTime.find(records: ["a": [at(8, 5), at(9, 5), at(10, 4)]], calendar: cal) == nil)
        #expect(StudyTimeOfDay.of(hour: 23) == .night && StudyTimeOfDay.of(hour: 4) == .night)
    }
}

@Suite("SQL track")
@MainActor
struct SQLTrackTests {
    @Test func sqlLessonsAreFreeAndUnique() throws {
        #expect(FreeContent.sql.count == 10)
        #expect(Set(FreeContent.sql.map(\.id)).count == 10)
        #expect(!PremiumStore.paidTracks.contains(FreeContent.sqlTrack))
        let merged = try Curriculum.load().withPaidTracks().withPaidTracks()
        #expect(merged.lessons.filter { $0.category == FreeContent.sqlTrack }.count == 10)
    }

    @Test func newAchievements() {
        var e = AchievementContext.Extras()
        e.listened = 50
        #expect(LearningAchievements.condition("good-ears", e) == true)
        #expect(LearningAchievements.condition("first-week", e) == false)
    }
}
