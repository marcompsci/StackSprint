import Testing
import Foundation
import SwiftUI
@testable import StackSprint

private var utc: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}

private func lesson(_ id: String, _ term: String, track: String = "T") -> Lesson {
    Lesson(id: id, term: term, category: track, clue: "clue", definition: "def", code: "", difficulty: nil)
}

@Suite("Brain dump")
@MainActor
struct BrainDumpTests {
    @Test func findsTermsInFreeText() {
        let r = BrainDump.score(text: "Loops repeat code. A varible stores data. Also pull requests!",
                                terms: ["Loop", "Variable", "Pull request", "Closure"])
        #expect(r.recalled == ["Loop", "Variable", "Pull request"])
        #expect(r.missed == ["Closure"])
        #expect(r.percent == 75)
    }

    @Test func emptyTextRecallsNothing() {
        let r = BrainDump.score(text: "", terms: ["Loop"])
        #expect(r.recalled.isEmpty && r.percent == 0)
        #expect(BrainDump.score(text: "x", terms: []).percent == 0)
    }
}

@Suite("Solid lessons")
@MainActor
struct SolidTests {
    private func r(_ day: Int, _ score: Int) -> LessonQuizRecord {
        LessonQuizRecord(date: Date(timeIntervalSince1970: 1_800_000_000 + Double(day) * 86_400), score: score, total: 5, missed: [])
    }

    @Test func needsThreeDifferentGoodDays() {
        #expect(Solid.goodDays([r(0, 5), r(0, 4), r(1, 4)], calendar: utc) == 2)
        #expect(!Solid.isSolid([r(0, 5), r(0, 4), r(1, 4), r(2, 3)], calendar: utc))
        #expect(Solid.isSolid([r(0, 5), r(3, 4), r(9, 5)], calendar: utc))
        #expect(Solid.solidCount(["a": [r(0, 5), r(3, 4), r(9, 5)], "b": [r(0, 5)]], calendar: utc) == 1)
    }
}

@Suite("Week, certificates and appearance")
@MainActor
struct WeekCertificateTests {
    @Test func weekInReviewKeepsTheLastSevenDays() {
        let cal = utc
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        func key(_ daysAgo: Int) -> String { StreakMath.key(cal.date(byAdding: .day, value: -daysAgo, to: now)!, cal) }
        let ids = WeekInReview.lessonIDs(activity: ["\(key(0))|a", "\(key(6))|b", "\(key(7))|c"], now: now, calendar: cal)
        #expect(Set(ids) == ["a", "b"])
    }

    @Test func closestCertificatePicksFewestRemaining() throws {
        let byTrack = ["A": [lesson("a1", "A1", track: "A"), lesson("a2", "A2", track: "A")],
                       "B": (1...4).map { lesson("b\($0)", "B\($0)", track: "B") },
                       "C": [lesson("c1", "C1", track: "C")]]
        let best: [String: Int] = ["a1": 5, "b1": 5, "b2": 5, "b3": 5]
        let goal = try #require(NextCertificate.closest(lessonsByTrack: byTrack, locked: ["C"],
                                                        completed: ["a1", "b1", "b2", "b3"], best: { best[$0] }))
        #expect(goal == CertificateGoal(track: "A", remaining: 1, total: 2))
        #expect(NextCertificate.message(goal) == "1 lesson to go for your A certificate.")
        #expect(NextCertificate.closest(lessonsByTrack: byTrack, locked: [], completed: [], best: { _ in nil }) == nil)
    }

    @Test func appearanceModes() {
        #expect(AppearanceMode.scheme("system") == nil)
        #expect(AppearanceMode.scheme("light") == .light)
        #expect(AppearanceMode.scheme("dark") == .dark)
        #expect(AppearanceMode.scheme("anything") == .dark)
    }
}

@Suite("Prompt library and review drills")
@MainActor
struct PromptLibraryTests {
    @Test func savesNewestFirstAndRefusesPrivateDetails() {
        let library = PromptLibrary(defaults: UserDefaults(suiteName: "prompt-tests-\(UUID())")!)
        library.eraseAll()
        #expect(library.save(title: "", text: "Explain loops simply", date: Date(timeIntervalSince1970: 1)))
        #expect(library.save(title: "Recipe", text: "Plan dinner", date: Date(timeIntervalSince1970: 2)))
        #expect(!library.save(title: "", text: "Email me at a@b.com"))
        #expect(!library.save(title: "", text: "   "))
        #expect(library.prompts.map(\.title) == ["Recipe", "Explain loops simply"])
        library.delete(library.prompts[0].id)
        #expect(library.prompts.count == 1)
        library.eraseAll()
    }

    @Test func drillsAreWellFormed() {
        for item in CodeReviewDrills.reviews + CodeReviewDrills.commits {
            #expect(item.options.indices.contains(item.best))
        }
        let ids = (CodeReviewDrills.reviews + CodeReviewDrills.commits).map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func newAchievements() {
        var e = AchievementContext.Extras()
        e.solidLessons = 10
        e.bestBrainDump = 79
        #expect(LearningAchievements.condition("rock-solid", e) == true)
        #expect(LearningAchievements.condition("total-recall", e) == false)
    }
}
