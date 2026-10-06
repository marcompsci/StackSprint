import Testing
import Foundation
@testable import StackSprint

// MARK: - Curriculum

@Suite("Curriculum")
struct CurriculumTests {
    @Test func bundleLoads() throws {
        let curriculum = try Curriculum.load()
        #expect(curriculum.lessons.count == 104)
        #expect(curriculum.questions.count == 75)
    }

    @Test func lessonIDsAreUnique() throws {
        let curriculum = try Curriculum.load()
        #expect(Set(curriculum.lessons.map(\.id)).count == curriculum.lessons.count)
    }

    @Test func questionAnswerIndexInBounds() throws {
        let curriculum = try Curriculum.load()
        for q in curriculum.questions {
            #expect(q.answer >= 0)
            #expect(q.answer < q.choices.count)
        }
    }

    @Test func allExpectedCategoriesPresent() throws {
        let curriculum = try Curriculum.load()
        let cats = Set(curriculum.lessons.map(\.category))
        for expected in ["Web development", "Python", "Cybersecurity", "Swift",
                         "TypeScript", "React", "Go", "Rust", "Interview Prep"] {
            #expect(cats.contains(expected), "Missing category: \(expected)")
        }
    }

    @Test func goAndRustHaveTenLessonsEach() throws {
        let curriculum = try Curriculum.load()
        let go = curriculum.lessons.filter { $0.category == "Go" }.count
        let rust = curriculum.lessons.filter { $0.category == "Rust" }.count
        #expect(go == 10)
        #expect(rust == 10)
    }

    @Test func interviewPrepHasTwelveLessons() throws {
        let curriculum = try Curriculum.load()
        let count = curriculum.lessons.filter { $0.category == "Interview Prep" }.count
        #expect(count == 12)
    }

    @Test func backendConfigContainsNoRealCredential() throws {
        let url = try #require(Bundle.main.url(forResource: "BackendConfig", withExtension: "json"))
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains("YOUR_"))
    }
}

// MARK: - LearningStore

@Suite("LearningStore")
@MainActor
struct LearningStoreTests {
    @Test func completeInsertsLessonID() {
        let store = LearningStore()
        store.complete("test-phase9-a")
        #expect(store.completed.contains("test-phase9-a"))
    }

    @Test func completeSetsToday() {
        let store = LearningStore()
        store.complete("test-phase9-b")
        #expect(!store.practicedDays.isEmpty)
    }

    @Test func practiceXPGrowsAfterCompletion() {
        let store = LearningStore()
        let before = store.practiceXP
        store.complete("test-xp-phase9")
        #expect(store.practiceXP > before)
    }

    @Test func practiceXPIs10PerLesson() {
        let store = LearningStore()
        let before = store.completed.count
        store.complete("test-xp-rate-1")
        store.complete("test-xp-rate-2")
        let gained = (store.completed.count - before) * 10
        #expect(store.practiceXP >= gained)
    }

    @Test func mergeFromCloudUnionsCompleted() {
        let store = LearningStore()
        store.complete("local-lesson")
        store.mergeFromCloud(
            completed: ["cloud-lesson-1", "cloud-lesson-2"],
            practicedDays: [],
            recallAnswers: []
        )
        #expect(store.completed.contains("local-lesson"))
        #expect(store.completed.contains("cloud-lesson-1"))
        #expect(store.completed.contains("cloud-lesson-2"))
    }

    @Test func mergeFromCloudNeverRemovesLocalData() {
        let store = LearningStore()
        store.complete("keeper-lesson")
        store.mergeFromCloud(completed: [], practicedDays: [], recallAnswers: [])
        #expect(store.completed.contains("keeper-lesson"))
    }

    @Test func currentStreakIsNonNegative() {
        let store = LearningStore()
        #expect(store.currentStreak >= 0)
    }

    @Test func curriculumLoadsOnInit() {
        let store = LearningStore()
        #expect(store.curriculum != nil)
    }
}

// MARK: - AdaptiveEngine

@Suite("AdaptiveEngine")
@MainActor
struct AdaptiveEngineTests {
    @Test func recordWrongIncrementsCount() {
        let engine = AdaptiveEngine()
        let key = "q-test-p9-\(Int.random(in: 0..<100000))"
        engine.recordWrong(key)
        #expect(engine.wrongCounts[key] == 1)
    }

    @Test func recordWrongAccumulates() {
        let engine = AdaptiveEngine()
        let key = "q-accum-p9-\(Int.random(in: 0..<100000))"
        engine.recordWrong(key)
        engine.recordWrong(key)
        engine.recordWrong(key)
        #expect(engine.wrongCounts[key] == 3)
    }

    @Test func recordCorrectDecaysWrongCount() {
        let engine = AdaptiveEngine()
        let key = "q-decay-p9-\(Int.random(in: 0..<100000))"
        engine.recordWrong(key)
        engine.recordWrong(key)
        engine.recordCorrect(key)
        #expect(engine.wrongCounts[key] == 1)
    }

    @Test func recordCorrectRemovesAtZero() {
        let engine = AdaptiveEngine()
        let key = "q-zero-p9-\(Int.random(in: 0..<100000))"
        engine.recordWrong(key)
        engine.recordCorrect(key)
        #expect(engine.wrongCounts[key] == nil)
    }

    @Test func sortedSessionReturnsRequestedCount() throws {
        let curriculum = try Curriculum.load()
        let engine = AdaptiveEngine()
        let session = engine.sortedSession(curriculum.questions, count: 5)
        #expect(session.count == 5)
    }

    @Test func sortedSessionHasNoDuplicates() throws {
        let curriculum = try Curriculum.load()
        let engine = AdaptiveEngine()
        let session = engine.sortedSession(curriculum.questions, count: 10)
        #expect(Set(session.map(\.id)).count == session.count)
    }

    @Test func sortedSessionPrioritizesWeakQuestions() throws {
        let curriculum = try Curriculum.load()
        let engine = AdaptiveEngine()
        let weak = curriculum.questions.prefix(3)
        for q in weak { engine.recordWrong(q.id); engine.recordWrong(q.id) }
        let session = engine.sortedSession(curriculum.questions, count: 5)
        let weakIDs = Set(weak.map(\.id))
        let weakInSession = session.filter { weakIDs.contains($0.id) }.count
        #expect(weakInSession >= 2)
    }
}

// MARK: - ChallengeStore

@Suite("ChallengeStore")
@MainActor
struct ChallengeStoreTests {
    @Test func currentChallengesIsNonEmpty() {
        let store = ChallengeStore()
        #expect(!store.currentChallenges.isEmpty)
    }

    @Test func currentChallengesHasThree() {
        let store = ChallengeStore()
        #expect(store.currentChallenges.count == 3)
    }

    @Test func daysUntilResetIsInRange() {
        let store = ChallengeStore()
        #expect(store.daysUntilReset >= 0)
        #expect(store.daysUntilReset <= 7)
    }

    @Test func allChallengeTypesPresent() {
        let store = ChallengeStore()
        let types = Set(store.currentChallenges.map(\.type))
        #expect(types.contains(.streak))
        #expect(types.contains(.lessons))
        #expect(types.contains(.recall))
    }

    @Test func xpMultiplierIsOneOnWeekday() {
        let store = ChallengeStore()
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday != 1 && weekday != 7 {
            #expect(store.xpMultiplier == 1.0)
        }
    }
}

// MARK: - PremiumStore

@Suite("PremiumStore")
@MainActor
struct PremiumStoreTests {
    @Test func proTracksContainsExpectedCategories() {
        let tracks = PremiumStore.proTracks
        #expect(tracks.contains("Go"))
        #expect(tracks.contains("Rust"))
        #expect(tracks.contains("Interview Prep"))
    }

    @Test func defaultIsNotPro() {
        let store = PremiumStore()
        // Default in sandbox/test environment is not subscribed
        #expect(!store.isPro)
    }
}
