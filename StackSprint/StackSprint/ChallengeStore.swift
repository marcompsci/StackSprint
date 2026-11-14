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
            WeeklyChallenge(id: "c1-streak",  emoji: "flame.fill", title: "Stay lit",       description: "Keep a 3-day streak",          goal: 3,  type: .streak,  xpReward: 30),
            WeeklyChallenge(id: "c1-lessons", emoji: "books.vertical.fill", title: "Five-a-week",    description: "Practice 5 days this week",    goal: 5,  type: .lessons, xpReward: 50),
            WeeklyChallenge(id: "c1-recall",  emoji: "brain.head.profile", title: "Recall sprint",  description: "Answer 10 recall questions",   goal: 10, type: .recall,  xpReward: 25),
        ],
        [
            WeeklyChallenge(id: "c2-streak",  emoji: "bolt.fill", title: "Power week",     description: "Practice 5 days in a row",     goal: 5,  type: .streak,  xpReward: 50),
            WeeklyChallenge(id: "c2-lessons", emoji: "paperplane.fill", title: "Deep dive",      description: "Practice 7 days this week",    goal: 7,  type: .lessons, xpReward: 80),
            WeeklyChallenge(id: "c2-recall",  emoji: "scope", title: "Precision",      description: "Answer 20 recall questions",   goal: 20, type: .recall,  xpReward: 40),
        ],
        [
            WeeklyChallenge(id: "c3-streak",  emoji: "water.waves", title: "Flow state",     description: "Keep a 4-day streak",          goal: 4,  type: .streak,  xpReward: 40),
            WeeklyChallenge(id: "c3-lessons", emoji: "trophy.fill", title: "Gold rush",      description: "Practice every day this week", goal: 7,  type: .lessons, xpReward: 60),
            WeeklyChallenge(id: "c3-recall",  emoji: "lightbulb.fill", title: "Bright sparks",  description: "Answer 15 recall questions",   goal: 15, type: .recall,  xpReward: 30),
        ],
        [
            WeeklyChallenge(id: "c4-streak",  emoji: "shield.lefthalf.filled", title: "Resilient",      description: "Keep a 3-day streak",          goal: 3,  type: .streak,  xpReward: 30),
            WeeklyChallenge(id: "c4-lessons", emoji: "magnifyingglass", title: "Explorer",       description: "Practice 6 days this week",    goal: 6,  type: .lessons, xpReward: 70),
            WeeklyChallenge(id: "c4-recall",  emoji: "star.fill", title: "Star pupil",      description: "Answer 12 recall questions",   goal: 12, type: .recall,  xpReward: 35),
        ],
    ]

    var currentChallenges: [WeeklyChallenge] {
        let week = Calendar.current.component(.weekOfYear, from: Date())
        return Self.pools[week % 4]
    }

    // There used to be an "XP Weekend" that promised double XP; nothing ever doubled it, so it's gone.

    /// Days left in the calendar week the challenges count (the same week their progress uses).
    var daysUntilReset: Int {
        let cal = Calendar.current
        guard let end = cal.dateInterval(of: .weekOfYear, for: Date())?.end else { return 7 }
        return max(1, cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: end).day ?? 7)
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

    /// Marks the challenge claimed and pays its reward into the season pass and this week's XP.
    /// (Claiming used to pay nothing.)
    func claim(_ challenge: WeeklyChallenge, store: LearningStore, season: SeasonStore) {
        guard isCompleted(challenge, store: store), !isClaimed(challenge) else { return }
        UserDefaults.standard.set(true, forKey: claimedKey(challenge))
        season.recordXP(challenge.xpReward)
        WeeklyXPStore.shared.recordXP(challenge.xpReward)
        HapticManager.shared.notification(.success)
        objectWillChange.send()
    }

    private func claimedKey(_ challenge: WeeklyChallenge) -> String {
        let parts = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return "challenge.claimed.\(challenge.id).\(parts.yearForWeekOfYear ?? 0)w\(parts.weekOfYear ?? 0)"
    }

    private func weekDayKeys() -> [String] { Array(WeeklyGoalMath.weekKeys(containing: Date())) }

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
                Image(systemName: "scope").font(.title2).symbolRenderingMode(.hierarchical).foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Weekly challenges").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                    }
                    Text("\(completed)/\(active.count) done \u{B7} resets in \(challenges.daysUntilReset)d")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if claimable > 0 {
                    Text("\(claimable) to claim")
                        .font(.caption.bold())
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.orange.opacity(0.18), in: Capsule())
                        .foregroundStyle(.orange)
                }
                Image(systemName: "chevron.right").foregroundStyle(.secondary).font(.caption)
            }
            .padding(14)
            .background(Color.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.orange.opacity(0.18)))
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
                    ForEach(challenges.currentChallenges) { challenge in
                        ChallengeCard(challenge: challenge)
                    }
                    Text("Challenges reset when a new week starts \u{B7} \(challenges.daysUntilReset) \(challenges.daysUntilReset == 1 ? "day" : "days") left. Rewards go to your season pass.")
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

}

private struct ChallengeCard: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var challenges: ChallengeStore
    @EnvironmentObject var seasonStore: SeasonStore
    let challenge: WeeklyChallenge

    var body: some View {
        let prog   = challenges.progress(for: challenge, store: store)
        let done   = challenges.isCompleted(challenge, store: store)
        let claimed = challenges.isClaimed(challenge)
        let pct    = min(Double(prog) / Double(max(challenge.goal, 1)), 1.0)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: challenge.emoji).font(.title2).symbolRenderingMode(.hierarchical).foregroundStyle(.tint).frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title).font(.headline)
                    Text(challenge.description).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("+\(challenge.xpReward) season XP")
                    .font(.caption.bold()).foregroundStyle(.orange)
            }
            ProgressView(value: pct).tint(done ? .mint : .orange)
                .animation(.smooth(duration: 0.4), value: pct)
            HStack {
                Text("\(prog) / \(challenge.goal)").font(.caption.monospaced()).foregroundStyle(.secondary)
                Spacer()
                if done && !claimed {
                    Button("Claim reward") { challenges.claim(challenge, store: store, season: seasonStore) }
                        .font(.caption.bold()).buttonStyle(.borderedProminent).tint(.mint)
                } else if claimed {
                    Label("Claimed", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold()).foregroundStyle(.mint)
                }
            }
        }
        .padding(16)
        .background(done ? Color.mint.opacity(0.07) : SprintPalette.card,
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(done ? Color.mint.opacity(0.3) : Color.secondary.opacity(0.12)))
    }
}
