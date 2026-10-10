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

// MARK: - Splash Screen

struct SplashView: View {
    let onComplete: () -> Void

    @State private var bitScale: CGFloat = 0.25
    @State private var bitOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var ringOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 18
    @State private var taglineCount: Int = 0
    @State private var auroraPhase: CGFloat = 0
    @State private var particleDrift: CGFloat = 0
    @State private var exitOpacity: Double = 1

    private let tagline = "Code. Learn. Sprint."
    private let codeSymbols = ["{}", "</>", "//", "=>", "fn()", "var", "let", "::", "&&", "λ"]

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.05, green: 0.08, blue: 0.15).ignoresSafeArea()

            // Aurora glow blobs
            auroraBackground

            // Floating code particles
            GeometryReader { geo in
                ForEach(0..<14, id: \.self) { i in codeParticle(i, geo: geo) }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Center stage
            VStack(spacing: 0) {
                Spacer()

                // Bit + orbit ring
                ZStack {
                    // Outer spinning gradient ring
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [.clear, .mint.opacity(0.9), .cyan.opacity(0.55),
                                         .purple.opacity(0.4), .clear],
                                center: .center
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 158, height: 158)
                        .rotationEffect(.degrees(ringRotation))
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // Inner soft ring pulse
                    Circle()
                        .stroke(Color.mint.opacity(0.15), lineWidth: 1)
                        .frame(width: 122, height: 122)
                        .scaleEffect(pulseScale)
                        .opacity(ringOpacity)

                    // Glow halo — blurred Bit behind the mascot
                    BiteAvatar()
                        .frame(width: 88, height: 110)
                        .blur(radius: 22)
                        .opacity(glowOpacity)
                        .scaleEffect(pulseScale * 0.95)

                    // Bit mascot
                    BiteAvatar()
                        .frame(width: 88, height: 110)
                        .scaleEffect(bitScale)
                        .opacity(bitOpacity)
                }
                .frame(width: 180, height: 180)
                .padding(.bottom, 30)

                // "STACK" white + "SPRINT" mint→cyan
                HStack(spacing: 1) {
                    Text("STACK")
                        .font(.system(size: 33, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("SPRINT")
                        .font(.system(size: 33, weight: .heavy, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.mint, Color(red: 0.3, green: 0.9, blue: 1.0)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                }
                .opacity(titleOpacity)
                .offset(y: titleOffset)
                .padding(.bottom, 10)

                // Typewriter tagline
                Text(String(tagline.prefix(taglineCount)))
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.42))
                    .frame(height: 20)

                Spacer()

                // Build footnote
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.caption2).foregroundStyle(.mint.opacity(0.35))
                    Text("v1.0  ·  Season 1")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.18))
                }
                .opacity(titleOpacity)
                .padding(.bottom, 50)
            }
        }
        .opacity(exitOpacity)
        .onAppear { runSequence() }
    }

    // MARK: Aurora

    @ViewBuilder private var auroraBackground: some View {
        Ellipse()
            .fill(RadialGradient(colors: [.mint.opacity(0.24), .clear],
                                 center: .center, startRadius: 0, endRadius: 230))
            .frame(width: 430, height: 310)
            .offset(x: -95, y: -190 + auroraPhase * 35)
            .blur(radius: 38)
        Ellipse()
            .fill(RadialGradient(colors: [.purple.opacity(0.19), .clear],
                                 center: .center, startRadius: 0, endRadius: 210))
            .frame(width: 370, height: 270)
            .offset(x: 115, y: 80 - auroraPhase * 22)
            .blur(radius: 46)
        Ellipse()
            .fill(RadialGradient(colors: [Color(red: 1.0, green: 0.55, blue: 0.3).opacity(0.11), .clear],
                                 center: .center, startRadius: 0, endRadius: 165))
            .frame(width: 310, height: 230)
            .offset(x: -55, y: 220 - auroraPhase * 14)
            .blur(radius: 52)
    }

    // MARK: Particle

    @ViewBuilder
    private func codeParticle(_ index: Int, geo: GeometryProxy) -> some View {
        let s      = Double(index * 17 + 5)
        let x      = CGFloat(s.truncatingRemainder(dividingBy: 9) / 9) * geo.size.width
        let baseY  = CGFloat((s * 1.9).truncatingRemainder(dividingBy: 11) / 11) * geo.size.height
        let speed  = CGFloat(0.35 + Double(index % 6) * 0.09)
        let raw    = baseY - particleDrift * speed
        let wrapped = raw < -20 ? raw + geo.size.height + 40 : raw
        let sym    = codeSymbols[index % codeSymbols.count]
        let alpha  = 0.05 + Double(index % 5) * 0.025
        let size   = 10.0 + Double(index % 4) * 1.5

        Text(sym)
            .font(.system(size: size, design: .monospaced))
            .foregroundStyle(Color.mint.opacity(alpha))
            .position(x: x, y: wrapped)
    }

    // MARK: Animation Sequence

    private func runSequence() {
        // Aurora breathes
        withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) { auroraPhase = 1 }
        // Particles drift upward
        withAnimation(.linear(duration: 22).repeatForever(autoreverses: false)) { particleDrift = 1200 }

        // 0.15s: Bit springs in with overshoot
        withAnimation(.spring(response: 0.52, dampingFraction: 0.48).delay(0.15)) {
            bitScale = 1.0; bitOpacity = 1.0
        }
        // 0.45s: Ring expands + starts spinning
        withAnimation(.easeOut(duration: 0.55).delay(0.45)) {
            ringOpacity = 1.0; ringScale = 1.0
        }
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false).delay(0.45)) {
            ringRotation = 360
        }
        // 0.45s: Glow pulse loop
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.45)) {
            pulseScale = 1.07; glowOpacity = 0.55
        }
        // 0.7s: Title slides up
        withAnimation(.easeOut(duration: 0.4).delay(0.7)) {
            titleOpacity = 1.0; titleOffset = 0
        }
        // 1.05s: Typewriter tagline
        let typeStart = 1.05
        for i in 0...tagline.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + typeStart + Double(i) * 0.058) {
                taglineCount = i
            }
        }
        // Fade out + call completion
        let exitAt = typeStart + Double(tagline.count) * 0.058 + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + exitAt) {
            withAnimation(.easeInOut(duration: 0.45)) { exitOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { onComplete() }
        }
    }
}
