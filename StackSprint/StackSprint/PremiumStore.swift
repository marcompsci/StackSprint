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
    /// True once a product request has finished, whether or not it returned products.
    @Published var productsLoaded = false

    static let proTracks: Set<String> = ["Go", "Rust", "Interview Prep"]

    init() {
        Task { await loadProducts(); await refreshEntitlements() }
        Task(priority: .background) {
            for await result in StoreKit.Transaction.updates { await handle(result) }
        }
    }

    func loadProducts() async {
        productsLoaded = false
        defer { productsLoaded = true }
        do {
            products = try await Product.products(for: ProProductID.allCases.map(\.rawValue))
                .sorted { $0.price < $1.price }
            if !products.isEmpty { purchaseError = nil }
        } catch {
            purchaseError = "Could not reach the App Store."
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
                    Text("Payment is charged to your Apple Account at confirmation. The subscription renews automatically at the price shown unless you cancel at least 24 hours before the end of the current period. Manage or cancel in Settings → Apple Account → Subscriptions.")
                        .font(.caption2).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal)
                    HStack(spacing: 18) {
                        Link("Terms of Use", destination: LegalLinks.termsOfUse)
                        NavigationLink("Privacy Policy") { PrivacyPolicyView() }
                    }
                    .font(.caption.weight(.semibold))
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
            Text("StackSprint Pro").font(.title.bold())
            Text("Three extra lesson tracks, on top of everything that's already free.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
    }

    private var featureList: some View {
        VStack(spacing: 10) {
            ProFeatureRow("Go and Rust lesson tracks", icon: "chevron.left.forwardslash.chevron.right", color: .mint)
            ProFeatureRow("Interview Prep track", icon: "briefcase.fill", color: .blue)
            ProFeatureRow("Pro season collectibles", icon: "rosette", color: .orange)
        }
    }

    @ViewBuilder
    private var productSection: some View {
        if premiumStore.products.isEmpty && !premiumStore.productsLoaded {
            ProgressView("Loading offers\u{2026}").padding(.vertical, 20)
        } else if premiumStore.products.isEmpty {
            VStack(spacing: 10) {
                Text("Subscriptions aren't available right now.").font(.subheadline.weight(.semibold))
                Text("Everything outside the Pro tracks stays free to use.").font(.caption).foregroundStyle(.secondary)
                Button("Try again") { Task { await premiumStore.loadProducts() } }
                    .buttonStyle(.bordered)
            }
            .multilineTextAlignment(.center)
            .padding(.vertical, 12)
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

    /// The billing period as the App Store reports it, e.g. "per month".
    private var periodLabel: String {
        guard let period = product.subscription?.subscriptionPeriod else { return "" }
        let unit: String
        switch period.unit {
        case .day: unit = "day"
        case .week: unit = "week"
        case .month: unit = "month"
        case .year: unit = "year"
        @unknown default: unit = "period"
        }
        return period.value == 1 ? "per \(unit)" : "every \(period.value) \(unit)s"
    }

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
                    Text(product.description.isEmpty ? "Cancel anytime" : product.description)
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice).font(.title3.bold())
                    Text(periodLabel).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(isYearly ? Color.mint.opacity(0.08) : SprintPalette.card,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isYearly ? Color.mint.opacity(0.5) : Color.secondary.opacity(0.15)))
        }
        .buttonStyle(.plain)
        .disabled(premiumStore.isPurchasing)
        .overlay(premiumStore.isPurchasing
                 ? RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.black.opacity(0.2))
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
