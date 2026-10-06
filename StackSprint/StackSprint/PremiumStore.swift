import Combine
import StoreKit
import SwiftUI

// MARK: - Product IDs

enum ProProductID: String, CaseIterable {
    case monthly = "com.stacksprint.pro.monthly"
    case yearly  = "com.stacksprint.pro.yearly"
}

// MARK: - Premium Store

@MainActor final class PremiumStore: ObservableObject {
    @Published var isPro = false
    @Published var products: [Product] = []
    @Published var purchaseError: String?
    @Published var isPurchasing = false

    static let proTracks: Set<String> = ["Go", "Rust", "Interview Prep"]

    init() {
        Task { await loadProducts(); await refreshEntitlements() }
        Task(priority: .background) {
            for await result in StoreKit.Transaction.updates { await handle(result) }
        }
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: ProProductID.allCases.map(\.rawValue))
                .sorted { $0.price < $1.price }
        } catch {
            purchaseError = "Could not load products."
        }
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil
        do {
            switch try await product.purchase() {
            case .success(let verification): await handle(verification)
            case .pending: purchaseError = "Purchase is pending approval."
            case .userCancelled: break
            @unknown default: break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
        isPurchasing = false
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            purchaseError = "Restore failed: \(error.localizedDescription)"
        }
    }

    private func refreshEntitlements() async {
        var active = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let tx) = result, ProProductID(rawValue: tx.productID) != nil {
                active = true
            }
        }
        isPro = active
    }

    private func handle(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let tx) = result else { return }
        await tx.finish()
        await refreshEntitlements()
    }
}

// MARK: - Pro Paywall

struct ProPaywallView: View {
    @EnvironmentObject var premiumStore: PremiumStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    paywallHeader
                    featureList
                    productSection
                    if let err = premiumStore.purchaseError {
                        Text(err).font(.caption).foregroundStyle(.red).multilineTextAlignment(.center)
                    }
                    Button {
                        Task { await premiumStore.restorePurchases() }
                    } label: {
                        Text("Restore purchases").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    Text("Subscription auto-renews unless cancelled at least 24 hours before renewal. Manage in Settings.")
                        .font(.caption2).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal)
                }
                .padding(24)
            }
            .navigationTitle("StackSprint Pro")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(SprintTheme())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }
                }
            }
        }
    }

    private var paywallHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.mint, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                Image(systemName: "crown.fill").font(.system(size: 36)).foregroundStyle(.white)
            }
            Text("Unlock everything").font(.system(.title, design: .rounded, weight: .bold))
            Text("Go deeper with Pro tracks, remove all limits, and climb the leaderboard.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
    }

    private var featureList: some View {
        VStack(spacing: 10) {
            ProFeatureRow("Go & Rust language tracks", icon: "chevron.left.forwardslash.chevron.right", color: .mint)
            ProFeatureRow("Interview Prep track", icon: "briefcase.fill", color: .blue)
            ProFeatureRow("Bit AI Tutor (unlimited chats)", icon: "sparkles", color: .purple)
            ProFeatureRow("Pro crown in Leaderboard", icon: "crown.fill", color: .yellow)
            ProFeatureRow("2\u{D7} XP Weekend boosts", icon: "bolt.fill", color: .orange)
        }
    }

    @ViewBuilder
    private var productSection: some View {
        if premiumStore.products.isEmpty {
            ProgressView("Loading offers\u{2026}").padding(.vertical, 20)
        } else {
            VStack(spacing: 12) {
                ForEach(premiumStore.products, id: \.id) { product in
                    PaywallProductButton(product: product)
                }
            }
        }
    }
}

private struct ProFeatureRow: View {
    let title: String
    let icon: String
    let color: Color
    init(_ title: String, icon: String, color: Color) {
        self.title = title; self.icon = icon; self.color = color
    }
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.body).foregroundStyle(color)
            }
            Text(title).font(.subheadline.bold())
            Spacer()
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.mint)
        }
        .padding(.horizontal, 4)
    }
}

private struct PaywallProductButton: View {
    @EnvironmentObject var premiumStore: PremiumStore
    let product: Product

    private var isYearly: Bool { product.id == ProProductID.yearly.rawValue }

    var body: some View {
        Button {
            HapticManager.shared.impact(.medium)
            Task { await premiumStore.purchase(product) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(product.displayName).font(.headline)
                        if isYearly {
                            Text("BEST VALUE").font(.caption2.bold())
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.mint.opacity(0.15), in: Capsule())
                                .foregroundStyle(.mint)
                        }
                    }
                    Text(isYearly ? "Save ~33% vs monthly" : "Cancel anytime")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice).font(.title3.bold())
                    Text(isYearly ? "/year" : "/month").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(isYearly ? Color.mint.opacity(0.08) : SprintPalette.card,
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(isYearly ? Color.mint.opacity(0.5) : Color.secondary.opacity(0.15)))
        }
        .buttonStyle(.plain)
        .disabled(premiumStore.isPurchasing)
        .overlay(premiumStore.isPurchasing
                 ? RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.2))
                 : nil)
    }
}

// MARK: - Pro Badge

struct ProBadge: View {
    var body: some View {
        Label("PRO", systemImage: "crown.fill")
            .font(.caption2.bold())
            .foregroundStyle(.yellow)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Color.yellow.opacity(0.12), in: Capsule())
    }
}

// MARK: - Pro Lock Cell (for locked track tabs)

struct ProLockedCategoryChip: View {
    let name: String
    let icon: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption)
                Text(name).font(.subheadline.bold())
                Image(systemName: "lock.fill").font(.caption2)
            }
            .padding(.horizontal, 15).padding(.vertical, 11)
            .foregroundStyle(Color.secondary)
            .background(SprintPalette.card.opacity(0.6), in: Capsule())
            .overlay(Capsule().stroke(Color.secondary.opacity(0.18), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}
