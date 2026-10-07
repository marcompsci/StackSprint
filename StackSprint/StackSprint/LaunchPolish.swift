import Combine
import StoreKit
import SwiftUI

// MARK: - App Review Manager

@MainActor final class ReviewManager: ObservableObject {
    static let shared = ReviewManager()

    private enum Keys {
        static let reviewRequested10  = "review.done.10lessons"
        static let reviewRequested25  = "review.done.25pct"
        static let reviewRequested3day = "review.done.3day"
    }

    // Call from onPractice callback after each lesson completion.
    func checkAndRequest(store: LearningStore) {
        let completed = store.completed.count
        let streak    = store.currentStreak
        let pct       = store.curriculum.map { c in c.lessons.isEmpty ? 0 : completed * 100 / c.lessons.count } ?? 0
        let ud        = UserDefaults.standard

        if completed >= 10, !ud.bool(forKey: Keys.reviewRequested10) {
            ud.set(true, forKey: Keys.reviewRequested10)
            requestReview()
        } else if streak >= 3, !ud.bool(forKey: Keys.reviewRequested3day) {
            ud.set(true, forKey: Keys.reviewRequested3day)
            requestReview()
        } else if pct >= 25, !ud.bool(forKey: Keys.reviewRequested25) {
            ud.set(true, forKey: Keys.reviewRequested25)
            requestReview()
        }
    }

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}

// MARK: - Empty State Views

struct EmptyLearnState: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 52)).foregroundStyle(.mint.opacity(0.6))
            Text("Loading your curriculum…").font(.headline)
            Text("Lessons will appear here as soon as they load.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            ProgressView().tint(.mint)
        }
        .padding(40).frame(maxWidth: .infinity)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct EmptyStatsState: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 52)).foregroundStyle(.purple.opacity(0.6))
            Text("No data yet").font(.title3.bold())
            Text("Complete a few lessons to see your analytics and progress charts here.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(40).frame(maxWidth: .infinity)
    }
}

struct EmptyTogetherState: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "person.2.wave.2.fill")
                .font(.system(size: 52)).foregroundStyle(.blue.opacity(0.6))
            Text("Start your social journey").font(.title3.bold())
            Text("Challenge friends, climb the leaderboard, and study together.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(40).frame(maxWidth: .infinity)
    }
}

// MARK: - Skeleton Loading

struct SkeletonRow: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8).fill(shimmerGradient).frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 5).fill(shimmerGradient).frame(height: 13)
                RoundedRectangle(cornerRadius: 5).fill(shimmerGradient).frame(width: 100, height: 10)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 5).fill(shimmerGradient).frame(width: 54, height: 13)
        }
        .padding(14)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 14))
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) { phase = 1 }
        }
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.04),
                Color.white.opacity(0.14),
                Color.white.opacity(0.04)
            ],
            startPoint: UnitPoint(x: phase, y: 0.5),
            endPoint: UnitPoint(x: phase + 1, y: 0.5)
        )
    }
}

struct SkeletonLeaderboard: View {
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<5, id: \.self) { _ in SkeletonRow() }
        }
    }
}

// MARK: - Error Recovery Banner

struct ErrorRecoveryBanner: View {
    let message: String
    let retryLabel: String
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark").foregroundStyle(.red).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Something went wrong").font(.subheadline.bold())
                Text(message).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer()
            Button(retryLabel, action: onRetry).font(.caption.bold()).buttonStyle(.bordered).tint(.mint)
        }
        .padding(14)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 18)
    }
}

// MARK: - Challenge Banner in LearnView (triggered by incoming challenge URL)

struct IncomingChallengeBanner: View {
    let challenge: FriendChallenge
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill").foregroundStyle(.orange).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(challenge.creatorName) challenged you!").font(.subheadline.bold())
                Text("Beat \(challenge.creatorScore)/\(FriendChallengeStore.questionsPerChallenge) in 60 seconds")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Go!") { onAccept() }.font(.caption.bold()).buttonStyle(.borderedProminent).tint(.orange).controlSize(.small)
            Button("✕") { onDecline() }.font(.caption.bold()).foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 18)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
