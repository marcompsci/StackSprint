import Combine
import Foundation
import SwiftUI

struct Lesson: Codable, Identifiable {
    let id: String
    let term: String
    let category: String
    let clue: String
    let definition: String
    let code: String
    let difficulty: String?
}

struct Question: Codable, Identifiable {
    let id: String
    let question: String
    let choices: [String]
    let answer: Int
    let explanation: String
}

struct Curriculum: Codable {
    let lessons: [Lesson]
    let questions: [Question]

    static func load() throws -> Curriculum {
        guard let url = Bundle.main.url(forResource: "curriculum", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
    }
}

// MARK: - Remote Curriculum Loader

enum CurriculumLoader {
    private static let cacheKey = "ss.curriculum.cache"

    /// Returns a previously-fetched remote curriculum if one is cached.
    static func cachedCurriculum() -> Curriculum? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let curriculum = try? JSONDecoder().decode(Curriculum.self, from: data),
              !curriculum.lessons.isEmpty
        else { return nil }
        return curriculum
    }

    /// Fetches a remote curriculum from the configured URL and caches it on success.
    static func fetchRemote(urlString: String) async -> Curriculum? {
        guard !urlString.isEmpty,
              let url = URL(string: urlString),
              url.scheme == "https"
        else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let curriculum = try JSONDecoder().decode(Curriculum.self, from: data)
            guard !curriculum.lessons.isEmpty else { return nil }
            UserDefaults.standard.set(data, forKey: cacheKey)
            return curriculum
        } catch {
            return nil
        }
    }
}

struct ProgressRow: Codable {
    let user_id: String
    let lesson_id: String
}

@MainActor final class LearningStore: ObservableObject {
    @Published var completed: Set<String> = []
    @Published private(set) var practicedDays: Set<String> = []
    @Published private(set) var correctRecallAnswers: Set<String> = []
    @Published var curriculum: Curriculum?
    @Published var error: String?
    private var namespace = "guest"
    var onPractice: (() -> Void)?

    init() {
        // Bundled JSON is always the safety net
        do { curriculum = try Curriculum.load() } catch { self.error = "Lesson content could not load: \(error.localizedDescription)" }
        // Override with a cached remote version if one exists (it's more up to date)
        if let cached = CurriculumLoader.cachedCurriculum() { curriculum = cached }
        switchUser(nil)
    }

    /// Fetches a fresh curriculum from the remote URL configured in BackendConfig.json.
    /// Call once on app launch from a Task so it doesn't block startup.
    func refreshCurriculumIfNeeded() async {
        guard let urlString = BackendConfig.remoteCurriculumURL else { return }
        if let remote = await CurriculumLoader.fetchRemote(urlString: urlString) {
            curriculum = remote
        }
    }

    func switchUser(_ id: String?) {
        namespace = id ?? "guest"
        completed = Set(UserDefaults.standard.stringArray(forKey: "native.completed.\(namespace)") ?? [])
        practicedDays = Set(UserDefaults.standard.stringArray(forKey: "native.practiceDays.\(namespace)") ?? [])
        correctRecallAnswers = Set(UserDefaults.standard.stringArray(forKey: "native.dailyRecall.\(namespace)") ?? [])
    }

    func complete(_ id: String) {
        guard !completed.contains(id) else { return }
        completed.insert(id)
        practicedDays.insert(Self.dayKey(Date()))
        persist()
        onPractice?()
    }

    func recordDailyRecall(_ questionID: String) {
        correctRecallAnswers.insert("\(Self.dayKey(Date()))|\(questionID)")
        practicedDays.insert(Self.dayKey(Date()))
        persist()
    }

    func recalledToday(_ questionID: String) -> Bool {
        correctRecallAnswers.contains("\(Self.dayKey(Date()))|\(questionID)")
    }

    var practiceXP: Int { completed.count * 10 + correctRecallAnswers.count * 5 }

    func merge(_ rows: [ProgressRow]) { completed.formUnion(rows.map(\.lesson_id)); persist() }

    func mergeFromCloud(completed: Set<String>, practicedDays: Set<String>, recallAnswers: Set<String>) {
        self.completed.formUnion(completed)
        self.practicedDays.formUnion(practicedDays)
        self.correctRecallAnswers.formUnion(recallAnswers)
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(Array(completed), forKey: "native.completed.\(namespace)")
        UserDefaults.standard.set(Array(practicedDays), forKey: "native.practiceDays.\(namespace)")
        UserDefaults.standard.set(Array(correctRecallAnswers), forKey: "native.dailyRecall.\(namespace)")
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        var date = calendar.startOfDay(for: Date())
        var count = 0
        while practicedDays.contains(Self.dayKey(date)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }
        return count
    }

    private static func dayKey(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
