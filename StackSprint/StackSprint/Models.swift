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
        do { curriculum = try Curriculum.load() } catch { self.error = "Lesson content could not load: \(error.localizedDescription)" }
        switchUser(nil)
    }

    func switchUser(_ id: String?) {
        namespace = id ?? "guest"
        completed = Set(UserDefaults.standard.stringArray(forKey: "native.completed.\(namespace)") ?? [])
        practicedDays = Set(UserDefaults.standard.stringArray(forKey: "native.practiceDays.\(namespace)") ?? [])
        correctRecallAnswers = Set(UserDefaults.standard.stringArray(forKey: "native.dailyRecall.\(namespace)") ?? [])
    }

    func complete(_ id: String) { completed.insert(id); practicedDays.insert(Self.dayKey(Date())); persist(); onPractice?() }

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
