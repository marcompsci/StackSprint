import Combine
import Network
import SwiftUI

// MARK: - Haptic Manager

final class HapticManager {
    static let shared = HapticManager()
    private init() {}

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}

// MARK: - Shimmer / Skeleton

struct ShimmerView: View {
    @State private var phase: CGFloat = -1.5
    var cornerRadius: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [
                    Color.secondary.opacity(0.10),
                    Color.secondary.opacity(0.22),
                    Color.secondary.opacity(0.10),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 3)
            .offset(x: phase * geo.size.width)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: false)) {
                phase = 1.5
            }
        }
    }
}

struct SkeletonLessonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ShimmerView(cornerRadius: 6).frame(width: 11, height: 11)
                ShimmerView(cornerRadius: 4).frame(width: 32, height: 12)
                Spacer()
            }
            Spacer(minLength: 8)
            ShimmerView(cornerRadius: 6).frame(height: 18)
            ShimmerView(cornerRadius: 4).frame(height: 14)
            ShimmerView(cornerRadius: 4).frame(width: 100, height: 12)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
        .background(SprintPalette.card.opacity(0.82), in: RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 48)).foregroundStyle(.secondary)
            Text(title).font(.title3.bold())
            Text(message).font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 24)
            if let label = actionLabel, let act = action {
                Button(label, action: act).buttonStyle(.borderedProminent).tint(.mint)
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 48)
    }
}

// MARK: - Offline Banner

struct OfflineBanner: View {
    @StateObject private var monitor = NetworkMonitor()

    var body: some View {
        if !monitor.isConnected {
            HStack(spacing: 10) {
                Image(systemName: "wifi.slash").font(.subheadline)
                Text("No internet \u{B7} your progress is saved on-device")
                    .font(.caption.bold())
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color.orange.opacity(0.15))
            .foregroundStyle(.orange)
        }
    }
}

private final class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ss.network", qos: .background)

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { self?.isConnected = path.status == .satisfied }
        }
        monitor.start(queue: queue)
    }
    deinit { monitor.cancel() }
}
