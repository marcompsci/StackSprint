import Testing
import Foundation
@testable import StackSprint

private func lesson(_ id: String, _ term: String, track: String = "T", definition: String? = nil) -> Lesson {
    Lesson(id: id, term: term, category: track, clue: "Clue for \(term)",
           definition: definition ?? "\(term) does a distinct job number \(id) in programs.", code: "", difficulty: nil)
}

@Suite("Placement and answers")
@MainActor
struct PlacementTests {
    @Test func lessonIDComesFromQuestionID() {
        let q = LessonQuizQuestion(id: "pro-commit-meaning", kind: .meaning, prompt: "", choices: ["a"], answer: 0, explanation: "")
        #expect(LessonQuizBuilder.lessonID(of: q) == "pro-commit")
        let d = LessonQuizQuestion(id: "ai-x-discrimination", kind: .discrimination, prompt: "", choices: ["a"], answer: 0, explanation: "")
        #expect(LessonQuizBuilder.lessonID(of: d) == "ai-x")
    }

    @Test func candidatesSkipFinishedAndKnown() {
        let track = (1...10).map { lesson("l\($0)", "Term\($0)") }
        let picked = Placement.candidates(track: track, completed: ["l1"], known: ["l2"], limit: 3).map(\.id)
        #expect(picked == ["l3", "l4", "l5"])
    }

    @Test func placementAsksOneMeaningQuestionPerLesson() {
        let track = (1...6).map { lesson("l\($0)", "Term\($0)") }
        let qs = Placement.questions(for: Array(track.prefix(4)), track: track)
        #expect(qs.count == 4)
        #expect(qs.allSatisfy { $0.kind == .meaning })
    }

    @Test func guessesDontCountAsKnown() {
        func q(_ id: String) -> LessonQuizQuestion {
            LessonQuizQuestion(id: "\(id)-meaning", kind: .meaning, prompt: "", choices: ["a", "b"], answer: 0, explanation: "")
        }
        let answers = [QuizAnswer(question: q("a"), chosen: 0, confidence: .sure),
                       QuizAnswer(question: q("b"), chosen: 0, confidence: .guessing),
                       QuizAnswer(question: q("c"), chosen: 1, confidence: .sure),
                       QuizAnswer(question: q("d"), chosen: 0, confidence: nil)]
        #expect(Placement.knownLessons(from: answers) == ["a", "d"])
    }

    @Test func continueSkipsKnownLessons() {
        let lessons = [lesson("a", "A"), lesson("b", "B"), lesson("c", "C")]
        let next = LessonFlow.continueLesson(in: lessons, completed: ["a"], preferredTrack: "T", locked: [], known: ["b"])
        #expect(next?.id == "c")
    }
}

@Suite("Glossary and notes")
@MainActor
struct GlossaryTests {
    let lessons = [lesson("1", "loop"), lesson("2", "Array"), lesson("3", "API", track: "U"), lesson("4", "2FA")]

    @Test func sortedSearchAndTrackFilter() {
        #expect(Glossary.entries(lessons).map(\.term) == ["2FA", "API", "Array", "loop"])
        #expect(Glossary.entries(lessons, track: "U").map(\.term) == ["API"])
        #expect(Glossary.entries(lessons, query: "arr").map(\.term) == ["Array"])
    }

    @Test func sectionsPutSymbolsLast() {
        let sections = Glossary.sections(Glossary.entries(lessons))
        #expect(sections.map(\.letter) == ["A", "L", "#"])
        #expect(sections.first?.lessons.count == 2)
    }

    @Test func notesExportIncludesOnlyWrittenLessons() {
        let md = StudyNotesExport.markdown(lessons: lessons, notes: ["1": "Remember the exit"], explanations: ["2": "A list of items"])
        #expect(md.contains("### loop"))
        #expect(md.contains("**Note:** Remember the exit"))
        #expect(md.contains("**In my words:** A list of items"))
        #expect(!md.contains("### API"))
        #expect(StudyNotesExport.markdown(lessons: lessons, notes: [:], explanations: [:]).contains("No notes yet"))
    }
}

@Suite("Calibration and drills")
@MainActor
struct CalibrationTests {
    private func record(_ sure: Int?, wrong: Int?, daysAgo: Double = 0) -> LessonQuizRecord {
        LessonQuizRecord(date: Date(timeIntervalSince1970: 1_800_000_000 - daysAgo * 86_400), score: 4, total: 5, missed: [],
                         confidentMisses: wrong, sureAnswers: sure)
    }

    @Test func calibrationNeedsTenSureAnswers() {
        #expect(MasteryStore.calibration(records: ["a": [record(4, wrong: 1)]]) == nil)
        let value = MasteryStore.calibration(records: ["a": [record(6, wrong: 1)], "b": [record(4, wrong: 0)]])
        #expect(value == 0.9)
    }

    @Test func confidentMistakesNewestFirst() {
        let records = ["old": [record(5, wrong: 1, daysAgo: 3)], "new": [record(5, wrong: 2)],
                       "fixed": [record(5, wrong: 1, daysAgo: 5), record(5, wrong: 0)]]
        #expect(MasteryStore.confidentMistakes(records: records) == ["new", "old"])
    }

    @Test func drillPicksTheRequestedKind() {
        let all = (1...6).map { lesson("l\($0)", "Term\($0)") }
        let qs = TargetedDrill.questions(kind: .recall, lessons: Array(all.prefix(3)), all: all)
        #expect(qs.count == 3 && qs.allSatisfy { $0.kind == .recall })
    }

    @Test func quickReviewIsThreeQuestionsDueFirst() {
        let all = (1...6).map { lesson("l\($0)", "Term\($0)") }
        let qs = TargetedDrill.quickReview(due: [all[4]], recent: [all[0], all[4], all[1]], all: all)
        #expect(qs.count == 3)
        #expect(LessonQuizBuilder.lessonID(of: qs[0]) == "l5")
    }

    @Test func recentLessonIDsNewestDayFirst() {
        let ids = TargetedDrill.recentLessonIDs(["2026-11-01|a", "2026-11-03|b", "2026-11-02|a", "bad"])
        #expect(ids == ["b", "a"])
    }
}

@Suite("Focus timer")
@MainActor
struct FocusTests {
    @Test func progressAndRemaining() {
        let start = Date(timeIntervalSince1970: 0)
        #expect(FocusMath.progress(start: start, minutes: 10, now: start.addingTimeInterval(300)) == 0.5)
        #expect(FocusMath.progress(start: start, minutes: 10, now: start.addingTimeInterval(9_999)) == 1)
        #expect(FocusMath.remainingText(start: start, minutes: 10, now: start.addingTimeInterval(61)) == "8:59")
        #expect(FocusMath.focusedMinutes(start: start, minutes: 10, now: start.addingTimeInterval(9_999)) == 10)
        #expect(FocusMath.focusedMinutes(start: start, minutes: 10, now: start.addingTimeInterval(119)) == 1)
    }

    @Test func retestCopyNamesTheLesson() {
        #expect(ReminderCopy.retest("Closures").contains("Closures"))
    }
}
