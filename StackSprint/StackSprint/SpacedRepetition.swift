import Combine
import SwiftUI

// MARK: - SM-2 Card

struct SM2Card: Codable {
    var lessonID: String
    var interval: Int        // days until next review
    var easeFactor: Double   // starts at 2.5
    var repetitions: Int     // consecutive correct answers
    var dueDate: Date

    static func initial(lessonID: String) -> SM2Card {
        SM2Card(lessonID: lessonID, interval: 1, easeFactor: 2.5, repetitions: 0, dueDate: Date())
    }

    /// Update card using SM-2 algorithm. Quality: 1=failed, 3=hard, 5=easy
    mutating func update(quality: Int) {
        let q = min(5, max(0, quality))
        if q < 3 {
            interval = 1
            repetitions = 0
        } else {
            switch repetitions {
            case 0: interval = 1
            case 1: interval = 6
            default: interval = Int(Double(interval) * easeFactor)
            }
            repetitions += 1
        }
        easeFactor = max(1.3, easeFactor + 0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02))
        dueDate = Calendar.current.date(byAdding: .day, value: interval, to: Date()) ?? Date()
    }

    var isDueToday: Bool { dueDate <= Date() }
    var daysUntilDue: Int { max(0, Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0) }
}

// MARK: - SM-2 Engine

@MainActor final class SM2Engine: ObservableObject {
    static let shared = SM2Engine()

    @Published private(set) var cards: [String: SM2Card] = [:]

    private static let key = "ss.sm2.cards"

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode([String: SM2Card].self, from: data) {
            cards = decoded
        }
    }

    func recordReview(lessonID: String, quality: Int) {
        var card = cards[lessonID] ?? SM2Card.initial(lessonID: lessonID)
        card.update(quality: quality)
        cards[lessonID] = card
        persist()
    }

    func card(for lessonID: String) -> SM2Card? { cards[lessonID] }

    func dueCards(in curriculum: [Lesson]) -> [Lesson] {
        curriculum.filter { lesson in
            guard let card = cards[lesson.id] else { return false }
            return card.isDueToday
        }
        .sorted { (cards[$0.id]?.dueDate ?? .distantFuture) < (cards[$1.id]?.dueDate ?? .distantFuture) }
    }

    func intervalLabel(for lessonID: String) -> String? {
        guard let card = cards[lessonID] else { return nil }
        switch card.daysUntilDue {
        case 0:    return "Due now"
        case 1:    return "Due tomorrow"
        case let d: return "Due in \(d)d"
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(cards) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}

// MARK: - Due Today Section View

struct DueTodaySectionView: View {
    @EnvironmentObject var store: LearningStore
    @StateObject private var engine = SM2Engine.shared

    var body: some View {
        let due = engine.dueCards(in: store.curriculum?.lessons ?? [])
        if !due.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Due for review · \(due.count)", systemImage: "clock.badge.exclamationmark.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                    .accessibilityLabel("\(due.count) lessons due for spaced-repetition review")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(due) { lesson in
                            NavigationLink(destination: LessonView(lesson: lesson)) {
                                DueCard(lesson: lesson)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("due-card-\(lesson.id)")
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }
}

private struct DueCard: View {
    let lesson: Lesson
    private var engine: SM2Engine { SM2Engine.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.caption).foregroundStyle(.orange)
                Text(engine.intervalLabel(for: lesson.id) ?? "Due now")
                    .font(.caption.bold()).foregroundStyle(.orange)
            }
            Text(lesson.term).font(.subheadline.bold()).lineLimit(2)
            Text(lesson.category).font(.caption).foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 160, alignment: .leading)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.3), lineWidth: 1))
    }
}
