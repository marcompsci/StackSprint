import Combine
import SwiftUI

// MARK: - Challenge Model

struct WeeklyChallenge: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let description: String
    let goal: Int
    let type: ChallengeType
    let xpReward: Int

    enum ChallengeType { case streak, lessons, recall }
}

// MARK: - Challenge Store

@MainActor final class ChallengeStore: ObservableObject {
    // Four rotating weekly pools (based on ISO week % 4)
    private static let pools: [[WeeklyChallenge]] = [
        [
            WeeklyChallenge(id: "c1-streak",  emoji: "\u{1F525}", title: "Stay lit",       description: "Keep a 3-day streak",          goal: 3,  type: .streak,  xpReward: 30),
            WeeklyChallenge(id: "c1-lessons", emoji: "\u{1F4DA}", title: "Five-a-week",    description: "Practice 5 days this week",    goal: 5,  type: .lessons, xpReward: 50),
            WeeklyChallenge(id: "c1-recall",  emoji: "\u{1F9E0}", title: "Recall sprint",  description: "Answer 10 recall questions",   goal: 10, type: .recall,  xpReward: 25),
        ],
        [
            WeeklyChallenge(id: "c2-streak",  emoji: "\u{26A1}", title: "Power week",     description: "Practice 5 days in a row",     goal: 5,  type: .streak,  xpReward: 50),
            WeeklyChallenge(id: "c2-lessons", emoji: "\u{1F680}", title: "Deep dive",      description: "Practice 7 days this week",    goal: 7,  type: .lessons, xpReward: 80),
            WeeklyChallenge(id: "c2-recall",  emoji: "\u{1F3AF}", title: "Precision",      description: "Answer 20 recall questions",   goal: 20, type: .recall,  xpReward: 40),
        ],
        [
            WeeklyChallenge(id: "c3-streak",  emoji: "\u{1F30A}", title: "Flow state",     description: "Keep a 4-day streak",          goal: 4,  type: .streak,  xpReward: 40),
            WeeklyChallenge(id: "c3-lessons", emoji: "\u{1F3C6}", title: "Gold rush",      description: "Practice every day this week", goal: 7,  type: .lessons, xpReward: 60),
            WeeklyChallenge(id: "c3-recall",  emoji: "\u{1F4A1}", title: "Bright sparks",  description: "Answer 15 recall questions",   goal: 15, type: .recall,  xpReward: 30),
        ],
        [
            WeeklyChallenge(id: "c4-streak",  emoji: "\u{1F9BE}", title: "Resilient",      description: "Keep a 3-day streak",          goal: 3,  type: .streak,  xpReward: 30),
            WeeklyChallenge(id: "c4-lessons", emoji: "\u{1F52C}", title: "Explorer",       description: "Practice 6 days this week",    goal: 6,  type: .lessons, xpReward: 70),
            WeeklyChallenge(id: "c4-recall",  emoji: "\u{2B50}", title: "Star pupil",      description: "Answer 12 recall questions",   goal: 12, type: .recall,  xpReward: 35),
        ],
    ]

    var currentChallenges: [WeeklyChallenge] {
        let week = Calendar.current.component(.weekOfYear, from: Date())
        return Self.pools[week % 4]
    }

    var activeEventName: String? {
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday == 7 || weekday == 1 { return "XP Weekend \u{1F680}" }
        return nil
    }

    var xpMultiplier: Double { activeEventName != nil ? 2.0 : 1.0 }

    var daysUntilReset: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let nextMonday = cal.nextDate(after: today, matching: DateComponents(weekday: 2),
                                            matchingPolicy: .nextTime) else { return 7 }
        return cal.dateComponents([.day], from: today, to: nextMonday).day ?? 7
    }

    func progress(for challenge: WeeklyChallenge, store: LearningStore) -> Int {
        switch challenge.type {
        case .streak:  return store.currentStreak
        case .lessons: return practiceDaysThisWeek(store: store)
        case .recall:  return recallThisWeek(store: store)
        }
    }

    func isCompleted(_ challenge: WeeklyChallenge, store: LearningStore) -> Bool {
        progress(for: challenge, store: store) >= challenge.goal
    }

    func isClaimed(_ challenge: WeeklyChallenge) -> Bool {
        UserDefaults.standard.bool(forKey: claimedKey(challenge))
    }

    func markClaimed(_ challenge: WeeklyChallenge) {
        UserDefaults.standard.set(true, forKey: claimedKey(challenge))
        objectWillChange.send()
    }

    private func claimedKey(_ challenge: WeeklyChallenge) -> String {
        let week = Calendar.current.component(.weekOfYear, from: Date())
        return "challenge.claimed.\(challenge.id).w\(week)"
    }

    private func weekDayKeys() -> [String] {
        let cal = Calendar.current
        guard let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }.map { date in
            let c = cal.dateComponents([.year, .month, .day], from: date)
            return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        }
    }

    private func practiceDaysThisWeek(store: LearningStore) -> Int {
        let keys = weekDayKeys()
        return store.practicedDays.filter { keys.contains($0) }.count
    }

    private func recallThisWeek(store: LearningStore) -> Int {
        let keys = weekDayKeys()
        return store.correctRecallAnswers.filter { answer in keys.contains(where: { answer.hasPrefix($0) }) }.count
    }
}

// MARK: - Challenge Banner (compact, shown in LearnView)

struct ChallengeBanner: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var challenges: ChallengeStore
    @State private var showSheet = false

    var body: some View {
        let active = challenges.currentChallenges
        let completed = active.filter { challenges.isCompleted($0, store: store) }.count
        let claimable = active.filter { challenges.isCompleted($0, store: store) && !challenges.isClaimed($0) }.count

        Button { showSheet = true } label: {
            HStack(spacing: 12) {
                Text("\u{1F3AF}").font(.title2)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("WEEKLY CHALLENGES").font(.caption.bold()).foregroundStyle(.orange)
                        if let event = challenges.activeEventName {
                            Text(event).font(.caption.bold())
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.2), in: Capsule())
                        }
                    }
                    Text("\(completed)/\(active.count) done \u{B7} resets in \(challenges.daysUntilReset)d")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if claimable > 0 {
                    Text("+\(claimable) XP")
                        .font(.caption.bold())
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.orange.opacity(0.18), in: Capsule())
                        .foregroundStyle(.orange)
                }
                Image(systemName: "chevron.right").foregroundStyle(.secondary).font(.caption)
            }
            .padding(14)
            .background(Color.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.18)))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) { ChallengesSheet() }
    }
}

// MARK: - Challenges Sheet

struct ChallengesSheet: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var challenges: ChallengeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let event = challenges.activeEventName {
                        eventBanner(event)
                    }
                    ForEach(challenges.currentChallenges) { challenge in
                        ChallengeCard(challenge: challenge)
                    }
                    Text("Challenges reset every Monday \u{B7} \(challenges.daysUntilReset) days left")
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
                .padding(20)
            }
            .navigationTitle("Weekly Challenges")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(SprintTheme())
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func eventBanner(_ name: String) -> some View {
        HStack(spacing: 12) {
            Text("\u{1F680}").font(.title)
            VStack(alignment: .leading, spacing: 3) {
                Text(name).font(.headline)
                Text("All XP rewards doubled this weekend!").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.yellow.opacity(0.3)))
    }
}

private struct ChallengeCard: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var challenges: ChallengeStore
    let challenge: WeeklyChallenge

    var body: some View {
        let prog   = challenges.progress(for: challenge, store: store)
        let done   = challenges.isCompleted(challenge, store: store)
        let claimed = challenges.isClaimed(challenge)
        let pct    = min(Double(prog) / Double(max(challenge.goal, 1)), 1.0)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(challenge.emoji).font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title).font(.headline)
                    Text(challenge.description).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("+\(Int(Double(challenge.xpReward) * challenges.xpMultiplier)) XP")
                        .font(.caption.bold()).foregroundStyle(.orange)
                    if challenges.xpMultiplier > 1 {
                        Text("2\u{D7} boost!").font(.caption2).foregroundStyle(.yellow)
                    }
                }
            }
            ProgressView(value: pct).tint(done ? .mint : .orange)
                .animation(.easeOut(duration: 0.4), value: pct)
            HStack {
                Text("\(prog) / \(challenge.goal)").font(.caption.monospaced()).foregroundStyle(.secondary)
                Spacer()
                if done && !claimed {
                    Button("Claim reward") { challenges.markClaimed(challenge) }
                        .font(.caption.bold()).buttonStyle(.borderedProminent).tint(.mint)
                } else if claimed {
                    Label("Claimed", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold()).foregroundStyle(.mint)
                }
            }
        }
        .padding(16)
        .background(done ? Color.mint.opacity(0.07) : SprintPalette.card,
                    in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18)
            .stroke(done ? Color.mint.opacity(0.3) : Color.secondary.opacity(0.12)))
    }
}
