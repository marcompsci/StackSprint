import Testing
import Foundation
import StoreKit
@testable import StackSprint

private func lesson(_ id: String, _ term: String, track: String = "T", clue: String = "clue",
                    definition: String = "A definition.", code: String = "") -> Lesson {
    Lesson(id: id, term: term, category: track, clue: clue, definition: definition, code: code, difficulty: nil)
}

private var gregorian: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}

@Suite("Typed recall")
@MainActor
struct TypedRecallTests {
    @Test func exactAndNormalizedMatch() {
        #expect(TypedAnswer.matches("Pull request", "Pull request"))
        #expect(TypedAnswer.matches("  pull-REQUEST ", "Pull request"))
        #expect(TypedAnswer.matches("café", "Cafe"))
    }

    @Test func smallTyposAreForgivenOnlyOnLongerTerms() {
        #expect(TypedAnswer.matches("varible", "Variable"))           // 8 letters, 1 typo
        #expect(!TypedAnswer.matches("vrble", "Variable"))            // 3 edits
        #expect(TypedAnswer.matches("continous integraton", "Continuous integration")) // 2 typos, long
        #expect(!TypedAnswer.matches("lop", "Loop"))                  // short terms must be exact
        #expect(!TypedAnswer.matches("", "Loop"))
    }

    @Test func distanceIsLevenshtein() {
        #expect(TypedAnswer.distance("kitten", "sitting") == 3)
        #expect(TypedAnswer.distance("", "abc") == 3)
        #expect(TypedAnswer.distance("same", "same") == 0)
    }
}

@Suite("Confidence and feedback")
@MainActor
struct ConfidenceTests {
    @Test func guessesLowerTheReviewQuality() {
        #expect(LessonQuizBuilder.reviewQuality(score: 5, of: 5, luckyGuesses: 0) == 5)
        #expect(LessonQuizBuilder.reviewQuality(score: 5, of: 5, luckyGuesses: 1) == 5)
        #expect(LessonQuizBuilder.reviewQuality(score: 5, of: 5, luckyGuesses: 2) == 4)
        #expect(LessonQuizBuilder.reviewQuality(score: 1, of: 5, luckyGuesses: 4) == ReviewGrade.unsolved)
    }

    @Test func whyNotNamesTheOtherLesson() {
        let lessons = [lesson("a", "Loop", clue: "Repeats code."), lesson("b", "Variable", clue: "Stores a value.")]
        let q = LessonQuizQuestion(id: "a-recall", kind: .recall, prompt: "?", choices: ["Loop", "Variable"], answer: 0, explanation: "")
        #expect(LessonQuizBuilder.whyNot("Variable", in: q, lessons: lessons) == "Variable is something else: Stores a value.")
        #expect(LessonQuizBuilder.whyNot("Loop", in: q, lessons: lessons) == nil)       // the right answer
        #expect(LessonQuizBuilder.whyNot("True", in: q, lessons: lessons) == nil)       // not a lesson
    }

    @Test func oldRecordsWithoutConfidenceStillDecode() throws {
        let json = #"{"date":0,"score":4,"total":5,"missed":["recall"]}"#
        let record = try JSONDecoder().decode(LessonQuizRecord.self, from: Data(json.utf8))
        #expect(record.luckyGuesses == nil)
        #expect(record.score == 4)
    }
}

@Suite("Explain it back")
@MainActor
struct ExplainBackTests {
    let item = lesson("t", "Unit test", definition: "A unit test runs one piece of code with known input and checks the output automatically.")

    @Test func keyIdeasSkipTheTermAndFillerWords() {
        let ideas = ExplainBack.keyIdeas(for: item)
        #expect(!ideas.isEmpty && ideas.count <= 4)
        #expect(!ideas.contains("unit"))
        #expect(ideas.contains("piece"))
        #expect(ideas.allSatisfy { $0.count >= 5 })
    }

    @Test func coverageMatchesWordStems() {
        let covered = ExplainBack.covered("It checks pieces of code with input", ideas: ["piece", "input", "output"])
        #expect(covered == ["piece", "input"])
    }

    @Test func substantialNeedsEightWords() {
        #expect(!ExplainBack.isSubstantial("Too short"))
        #expect(ExplainBack.isSubstantial("A test runs a small piece of code and checks it"))
    }
}

@Suite("Mixed review and retest")
@MainActor
struct MixedReviewTests {
    @Test func picksWeakestFirstAndAlternatesTracks() {
        let candidates = [
            (lesson: lesson("a1", "A1", track: "A"), recall: 0.2),
            (lesson: lesson("a2", "A2", track: "A"), recall: 0.3),
            (lesson: lesson("b1", "B1", track: "B"), recall: 0.4),
            (lesson: lesson("a3", "A3", track: "A"), recall: 0.95),
        ]
        let picked = MixedReview.pickLessons(candidates, limit: 3).map(\.id)
        #expect(picked == ["a1", "b1", "a2"])
    }

    @Test func questionsNeverRepeatALessonBackToBack() {
        let a = (1...5).map { lesson("a\($0)", "Alpha\($0)", track: "A", clue: "Clue a\($0)", definition: "Alpha number \($0) does something useful here.") }
        let b = (1...5).map { lesson("b\($0)", "Beta\($0)", track: "B", clue: "Clue b\($0)", definition: "Beta number \($0) handles another distinct job.") }
        let qs = MixedReview.questions(for: [a[0], b[0], a[1]], all: a + b, count: 10)
        #expect(qs.count == 10)
        let lessonOf = qs.map { String($0.id.split(separator: "-").first ?? "") }
        for i in 1..<lessonOf.count { #expect(lessonOf[i] != lessonOf[i - 1]) }
    }

    @Test func retestPicksALessonFromOneToThreeDaysAgo() {
        let cal = gregorian
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        func record(daysAgo: Int, score: Int) -> LessonQuizRecord {
            LessonQuizRecord(date: cal.date(byAdding: .day, value: -daysAgo, to: now)!, score: score, total: 5, missed: [])
        }
        let records = ["today": [record(daysAgo: 0, score: 2)],
                       "yesterday": [record(daysAgo: 1, score: 5)],
                       "twoDays": [record(daysAgo: 2, score: 3)],
                       "old": [record(daysAgo: 9, score: 1)],
                       "locked": [record(daysAgo: 1, score: 1)]]
        let allowed: Set<String> = ["today", "yesterday", "twoDays", "old"]
        #expect(Retest.candidate(records: records, allowed: allowed, now: now, calendar: cal) == "twoDays")
        #expect(Retest.candidate(records: ["today": records["today"]!], allowed: allowed, now: now, calendar: cal) == nil)
    }

    @Test func reshuffleKeepsTheRightAnswer() {
        let q = LessonQuizQuestion(id: "x", kind: .meaning, prompt: "?", choices: ["a", "b", "c", "d"], answer: 2, explanation: "")
        let tf = LessonQuizQuestion(id: "y", kind: .keyDetail, prompt: "?", choices: ["True", "False"], answer: 1, explanation: "")
        let out = Retest.reshuffled([q, tf], seed: "s")
        #expect(out[0].choices[out[0].answer] == "c")
        #expect(Set(out[0].choices) == Set(q.choices))
        #expect(out[1].choices == ["True", "False"] && out[1].answer == 1)
    }
}

@Suite("Plans, weeks and certificates")
@MainActor
struct PlanTests {
    @Test func lessonsPerDayRoundsUp() {
        let cal = gregorian
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let in4 = cal.date(byAdding: .day, value: 4, to: now)!
        #expect(StudyPlanner.lessonsPerDay(remaining: 12, now: now, finishBy: in4, calendar: cal) == 3) // 5 days
        #expect(StudyPlanner.lessonsPerDay(remaining: 3, now: now, finishBy: now, calendar: cal) == 3)
        #expect(StudyPlanner.lessonsPerDay(remaining: 0, now: now, finishBy: in4, calendar: cal) == 0)
        let past = cal.date(byAdding: .day, value: -1, to: now)!
        #expect(StudyPlanner.lessonsPerDay(remaining: 5, now: now, finishBy: past, calendar: cal) == nil)
    }

    @Test func weekComparisonCountsLessonsPerWeek() {
        let cal = gregorian
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let lastWeek = cal.date(byAdding: .day, value: -7, to: now)!
        let activity: Set<String> = ["\(StreakMath.key(now, cal))|a", "\(StreakMath.key(now, cal))|b",
                                     "\(StreakMath.key(lastWeek, cal))|c"]
        let comparison = WeekComparison.make(activity: activity, now: now, calendar: cal)
        #expect(comparison == WeekComparison(thisWeek: 2, lastWeek: 1))
        #expect(comparison.message.contains("ahead"))
    }

    @Test func certificateNeedsEveryLessonAtFourOrBetter() {
        let lessons = [lesson("a", "A"), lesson("b", "B")]
        let best: [String: Int] = ["a": 5, "b": 3]
        #expect(!TrackCertificate.isEarned(lessons: lessons, completed: ["a", "b"], best: { best[$0] }))
        #expect(TrackCertificate.progress(lessons: lessons, completed: ["a", "b"], best: { best[$0] }) == 1)
        #expect(TrackCertificate.isEarned(lessons: lessons, completed: ["a", "b"], best: { _ in 4 }))
        #expect(!TrackCertificate.isEarned(lessons: lessons, completed: ["a"], best: { _ in 5 }))
        #expect(!TrackCertificate.isEarned(lessons: [], completed: [], best: { _ in 5 }))
    }
}

@Suite("AI Skills and Professional drills")
@MainActor
struct DrillTests {
    @Test func promptAssemblesInOrderAndSkipsBlanks() {
        var draft = PromptDraft()
        draft.role = "a patient tutor"
        draft.task = "Explain loops"
        draft.format = "Three bullet points"
        #expect(PromptCheck.assemble(draft) == "You are a patient tutor.\nExplain loops\nFormat: Three bullet points")
    }

    @Test func privacyCheckCatchesPersonalDetails() {
        #expect(PromptCheck.privacyWarnings("Email me at sam@example.com").count == 1)
        #expect(PromptCheck.privacyWarnings("Call 415-555-0134 please").first?.contains("phone") == true)
        #expect(PromptCheck.privacyWarnings("Card 4111 1111 1111 1111").first?.contains("card") == true)
        #expect(!PromptCheck.privacyWarnings("My password is hunter2").isEmpty)
        #expect(PromptCheck.privacyWarnings("Explain loops to a beginner in 2025").isEmpty)
    }

    @Test func feedbackFlagsAThinTask() {
        var draft = PromptDraft()
        draft.task = "write poem"
        let items = PromptCheck.feedback(draft)
        #expect(items.first { $0.id == "task" }?.ok == false)
        #expect(items.first { $0.id == "privacy" }?.ok == true)
    }

    @Test func drillContentIsWellFormed() {
        for item in ClaimChecks.all { #expect(item.options.indices.contains(item.best)) }
        for item in BugHunts.all { #expect(item.lines.indices.contains(item.buggyLine)) }
        #expect(Set(ClaimChecks.all.map(\.id)).count == ClaimChecks.all.count)
        #expect(Set(BugHunts.all.map(\.id)).count == BugHunts.all.count)
    }

    @Test func everyOfferHasASampleLesson() {
        let lessonsByTrack = ["Go": [lesson("go-1", "Goroutine", track: "Go")]]
        #expect(PaywallOffer.aiSkills.sampleLesson(in: [:])?.category == PaidContent.aiTrack)
        #expect(PaywallOffer.professional.sampleLesson(in: [:])?.category == PaidContent.professionalTrack)
        #expect(PaywallOffer.pro.sampleLesson(in: lessonsByTrack)?.id == "go-1")
    }

    @Test func introOfferPeriodsReadNaturally() {
        #expect(IntroOffer.periodText(value: 1, unit: .week) == "1 week")
        #expect(IntroOffer.periodText(value: 3, unit: .month) == "3 months")
    }
}
