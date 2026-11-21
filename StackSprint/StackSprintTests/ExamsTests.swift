import Testing
import Foundation
import SwiftUI
@testable import StackSprint

private func lessons(_ n: Int, track: String = "T") -> [Lesson] {
    (1...n).map { Lesson(id: "\(track)\($0)", term: "Term\($0)", category: track, clue: "Clue \($0)",
                         definition: "Term\($0) handles job number \($0) in a program.", code: "", difficulty: nil) }
}

@Suite("Checkpoints and exams")
@MainActor
struct ExamTests {
    @Test func unitsGroupFourLessonsAndFoldATinyRemainder() {
        #expect(Exams.units(track: "T", lessons: lessons(12)).map(\.lessonIDs.count) == [4, 4, 4])
        #expect(Exams.units(track: "T", lessons: lessons(10)).map(\.lessonIDs.count) == [4, 4, 2])
        #expect(Exams.units(track: "T", lessons: lessons(9)).map(\.lessonIDs.count) == [4, 5])
        #expect(Exams.units(track: "T", lessons: []).isEmpty)
        #expect(Exams.units(track: "T", lessons: lessons(8)).first?.title == "Checkpoint 1")
    }

    @Test func checkpointOpensWhenAllLessonsAreDone() {
        let unit = Exams.units(track: "T", lessons: lessons(8))[0]
        #expect(!Exams.isOpen(unit, completed: ["T1", "T2", "T3"]))
        #expect(Exams.isOpen(unit, completed: ["T1", "T2", "T3", "T4"]))
    }

    @Test func finalExamOpensAtEightyPercent() {
        let final = Exams.finalExam(track: "T", lessons: lessons(10))
        #expect(final.isFinal && final.title == "Final exam")
        #expect(!Exams.isOpen(final, completed: Set((1...7).map { "T\($0)" })))
        #expect(Exams.isOpen(final, completed: Set((1...8).map { "T\($0)" })))
    }

    @Test func passMark() {
        #expect(Exams.passed(score: 12, total: 15))
        #expect(!Exams.passed(score: 11, total: 15))
        #expect(!Exams.passed(score: 0, total: 0))
    }

    @Test func questionCounts() {
        let all = lessons(12)
        let unit = Exams.units(track: "T", lessons: all)[0]
        #expect(Exams.questions(for: unit, lessons: all).count == Exams.checkpointQuestions)
        #expect(Exams.questions(for: Exams.finalExam(track: "T", lessons: all), lessons: all).count == Exams.finalQuestions)
    }
}

@Suite("Hints, trial reminders and breaks")
@MainActor
struct HintTrialBreakTests {
    @Test func hintsDontRevealTheAnswer() {
        let recall = LessonQuizQuestion(id: "a-recall", kind: .recall, prompt: "?", choices: ["Loop", "Array", "Map"], answer: 0, explanation: "")
        #expect(QuizHint.text(for: recall) == "Starts with \"L\" and has 4 characters.")
        let meaning = LessonQuizQuestion(id: "a-meaning", kind: .meaning, prompt: "?", choices: ["x", "y", "z"], answer: 0, explanation: "")
        let hint = QuizHint.text(for: meaning)
        #expect(hint.contains("y") && !hint.contains("\"x\""))
    }

    @Test func trialReminderIsTwoDaysBeforeAtTen() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let ends = now.addingTimeInterval(7 * 86_400)
        let fire = try #require(TrialReminder.fireDate(trialEnds: ends, now: now, calendar: cal))
        #expect(cal.component(.hour, from: fire) == 10)
        #expect(cal.dateComponents([.day], from: cal.startOfDay(for: fire), to: cal.startOfDay(for: ends)).day == 2)
        #expect(TrialReminder.fireDate(trialEnds: now.addingTimeInterval(86_400), now: now, calendar: cal) == nil)
        #expect(TrialReminder.body(plan: "AI Skills", price: "$4.99", ends: ends).contains("$4.99"))
    }

    @Test func breakIsDueAfterTwentyFiveMinutes() {
        let start = Date(timeIntervalSince1970: 0)
        #expect(!StudyBreak.isDue(sessionStart: start, dismissedAt: nil, now: start.addingTimeInterval(24 * 60)))
        #expect(StudyBreak.isDue(sessionStart: start, dismissedAt: nil, now: start.addingTimeInterval(25 * 60)))
        #expect(!StudyBreak.isDue(sessionStart: start, dismissedAt: start.addingTimeInterval(26 * 60), now: start.addingTimeInterval(30 * 60)))
        #expect(!StudyBreak.isDue(sessionStart: nil, dismissedAt: nil))
    }

    @Test func colourBlindPaletteAvoidsRedGreen() {
        let palette = DisplayPrefs.feedback(colorBlind: true)
        #expect(palette.right == .blue && palette.wrong == .orange)
    }

    @Test func cheatSheetOnlyListsFinishedLessons() {
        let all = lessons(4)
        let lines = CheatSheet.lines(track: "T", lessons: all, completed: ["T1", "T3"])
        #expect(lines.map(\.term) == ["Term1", "Term3"])
    }

    @Test func examAchievements() {
        var e = AchievementContext.Extras()
        #expect(LearningAchievements.condition("graduate", e) == false)
        e.examsPassed = 1
        #expect(LearningAchievements.condition("graduate", e) == true)
    }

    @Test func newContentIsWellFormed() {
        #expect(PredictOutput.all.count == 20 && ErrorDecoder.all.count == 14)
        for item in PredictOutput.all { #expect(item.options.indices.contains(item.answer)) }
        #expect(Set(PredictOutput.all.map(\.id)).count == 20)
        let paid = (PaidContent.ai + PaidContent.professional).map(\.id)
        #expect(Set(paid).count == paid.count)
    }
}
