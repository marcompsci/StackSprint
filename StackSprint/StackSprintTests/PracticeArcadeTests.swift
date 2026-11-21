import Testing
import Foundation
@testable import StackSprint

private func lesson(_ id: String, _ term: String, clue: String) -> Lesson {
    Lesson(id: id, term: term, category: "T", clue: clue, definition: "\(term) definition.", code: "", difficulty: nil)
}

@Suite("Arcade content")
@MainActor
struct ArcadeContentTests {
    @Test func predictAndErrorItemsAreWellFormed() {
        for item in PredictOutput.all { #expect(item.options.indices.contains(item.answer)) }
        for item in ErrorDecoder.all { #expect(item.options.indices.contains(item.answer)) }
        #expect(Set(PredictOutput.all.map(\.id)).count == PredictOutput.all.count)
        #expect(Set(ErrorDecoder.all.map(\.id)).count == ErrorDecoder.all.count)
    }

    @Test func errorOptionsAreShuffledButKeepTheAnswer() {
        var answerPositions = Set<Int>()
        for item in ErrorDecoder.all {
            let mixed = ErrorDecoder.shuffled(item)
            #expect(mixed.options[mixed.answer] == item.options[item.answer])
            #expect(Set(mixed.options) == Set(item.options))
            answerPositions.insert(mixed.answer)
        }
        #expect(answerPositions.count > 1) // the right answer isn't always in the same place
    }

    @Test func miniProjectsHaveSteps() {
        #expect(MiniProjects.all.count == 7)
        #expect(MiniProjects.all.allSatisfy { $0.steps.count >= 4 })
    }
}

@Suite("Match and speed rounds")
@MainActor
struct MatchSpeedTests {
    let lessons = (1...8).map { lesson("l\($0)", "Term\($0)", clue: "Clue \($0)") }

    @Test func matchRoundPairsEveryTerm() throws {
        let round = try #require(MatchGame.make(from: lessons, seed: "x"))
        #expect(round.terms.count == 5 && round.clues.count == 5)
        #expect(Set(round.clues) == Set(round.terms.compactMap { round.pairs[$0] }))
        #expect(round.clues != round.terms.compactMap { round.pairs[$0] }) // not already in order
    }

    @Test func matchNeedsEnoughLessons() {
        #expect(MatchGame.make(from: Array(lessons.prefix(3)), seed: "x") == nil)
    }

    @Test func speedStatementsAreHonest() {
        let statements = SpeedRound.make(from: lessons, count: 60, seed: "s")
        #expect(statements.count == 60)
        let clueFor = Dictionary(uniqueKeysWithValues: lessons.map { ($0.term, $0.clue) })
        for s in statements { #expect((clueFor[s.term] == s.clue) == s.isTrue) }
        #expect(statements.contains { $0.isTrue } && statements.contains { !$0.isTrue })
        #expect(SpeedRound.make(from: Array(lessons.prefix(2)), seed: "s").isEmpty)
    }
}

@Suite("Motivation and exports")
@MainActor
struct MotivationTests {
    @Test func everyWhyHasAReminderAndATrack() {
        for why in LearningWhy.allCases {
            #expect(!why.reminder.isEmpty)
            #expect(!why.suggestedTrack.isEmpty)
        }
    }

    @Test func buddyMessageMentionsTheWeek() {
        let text = BuddyMessage.text(streak: 4, comparison: WeekComparison(thisWeek: 3, lastWeek: 1), why: .career)
        #expect(text.contains("3 lessons"))
        #expect(text.contains("4 days"))
        #expect(text.contains("career"))
        #expect(!BuddyMessage.text(streak: 0, comparison: WeekComparison(thisWeek: 1, lastWeek: 0), why: nil).contains("streak"))
    }

    @Test func csvHasHeaderRowsAndQuotes() {
        let records = ["a": [LessonQuizRecord(date: Date(timeIntervalSince1970: 0), score: 4, total: 5, missed: [], sureAnswers: 3)]]
        let csv = QuizHistoryCSV.make(records: records, terms: ["a": "Hello, \"world\""])
        let lines = csv.split(separator: "\n")
        #expect(lines.count == 2)
        #expect(lines[0].hasPrefix("date,lesson,score"))
        #expect(lines[1].contains("\"Hello, \"\"world\"\"\",4,5,3,,"))
    }

    @Test func dueTodayCountsAndSpeaks() {
        let now = Date(timeIntervalSince1970: 1_000)
        #expect(DueToday.count(dueDates: [now.addingTimeInterval(-1), now, now.addingTimeInterval(1)], now: now) == 2)
        #expect(DueToday.dialog(0).contains("Nothing"))
        #expect(DueToday.dialog(1).hasPrefix("1 lesson"))
        #expect(DueToday.dialog(4).hasPrefix("4 lessons"))
    }

    @Test func subscriptionLineText() {
        let line = SubscriptionLine(title: "Pro", date: Date(timeIntervalSince1970: 0), renews: false)
        #expect(line.text.hasPrefix("Ends"))
    }

    @Test func arcadeAchievements() {
        var e = AchievementContext.Extras()
        #expect(LearningAchievements.condition("builder", e) == false)
        e.projectsBuilt = 1
        e.speedBest = 25
        #expect(LearningAchievements.condition("builder", e) == true)
        #expect(LearningAchievements.condition("speedster", e) == true)
        #expect(LearningAchievements.progress("predictor", e)?.goal == 8)
    }
}
