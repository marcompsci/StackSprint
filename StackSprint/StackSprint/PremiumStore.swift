import Combine
import StoreKit
import SwiftUI

// MARK: - Product IDs

enum ProProductID: String, CaseIterable {
    case monthly = "com.stacksprint.pro.monthly"
    case yearly  = "com.stacksprint.pro.yearly"
}

/// Everything sold in the app.
enum StoreProductID: String, CaseIterable {
    case proMonthly = "com.stacksprint.pro.monthly"
    case proYearly = "com.stacksprint.pro.yearly"
    case aiMonthly = "com.stacksprint.ai.monthly"
    case aiYearly = "com.stacksprint.ai.yearly"
    case professionalPack = "com.stacksprint.pack.professional"

    var offer: PaywallOffer {
        switch self {
        case .proMonthly, .proYearly: return .pro
        case .aiMonthly, .aiYearly: return .aiSkills
        case .professionalPack: return .professional
        }
    }
}

/// The three things a learner can buy.
enum PaywallOffer: String, CaseIterable, Identifiable {
    case pro, aiSkills, professional
    var id: String { rawValue }

    var title: String {
        switch self {
        case .pro: return "StackSprint Pro"
        case .aiSkills: return "AI Skills"
        case .professional: return "Professional Practice"
        }
    }
    var shortTitle: String {
        switch self {
        case .pro: return "Pro"
        case .aiSkills: return "AI Skills"
        case .professional: return "Professional"
        }
    }
    var icon: String {
        switch self {
        case .pro: return "crown.fill"
        case .aiSkills: return "sparkles"
        case .professional: return "briefcase.fill"
        }
    }
    var tagline: String {
        switch self {
        case .pro: return "Three extra lesson tracks, on top of everything that's already free."
        case .aiSkills: return "Learn to prompt AI clearly, check what it tells you, and use it safely and fairly. Short lessons, plain words."
        case .professional: return "How working developers use Git, tests, reviews and debugging. Buy once, keep it."
        }
    }
    var features: [(String, String)] {
        switch self {
        case .pro: return [("Go and Rust lesson tracks", "chevron.left.forwardslash.chevron.right"),
                           ("Interview Prep track", "briefcase.fill"), ("Pro season collectibles", "rosette")]
        case .aiSkills: return [("\(PaidContent.ai.count) lessons on prompting, checking and safe use", "text.bubble.fill"),
                                ("Prompt makeover practice", "wand.and.stars"), ("New AI lessons as they're added", "plus.circle.fill")]
        case .professional: return [("\(PaidContent.professional.count) lessons: Git, reviews, tests, CI, debugging", "hammer.fill"),
                                    ("5-question quiz after every lesson", "checkmark.circle.fill"), ("One purchase, no subscription", "infinity")]
        }
    }
    var tracks: Set<String> {
        switch self {
        case .pro: return PremiumStore.proTracks
        case .aiSkills: return [PaidContent.aiTrack]
        case .professional: return [PaidContent.professionalTrack]
        }
    }
    var isSubscription: Bool { self != .professional }
}

// MARK: - Premium Store

@MainActor final class PremiumStore: ObservableObject {
    @Published var isPro = false
    @Published var hasAISkills = false
    @Published var hasProfessional = false
    /// Which offer the paywall should open on (set just before showing it).
    @Published var requestedOffer: PaywallOffer = .pro
    @Published var products: [Product] = []
    @Published var purchaseError: String?
    @Published var isPurchasing = false
    /// True once a product request has finished, whether or not it returned products.
    @Published var productsLoaded = false

    static let proTracks: Set<String> = ["Go", "Rust", "Interview Prep"]
    /// Every track that needs a purchase. Content meant for anyone (friend challenges,
    /// Study Room, daily questions) comes only from the other tracks.
    static let paidTracks: Set<String> = Set(PaywallOffer.allCases.flatMap(\.tracks))

    /// Tracks this learner hasn't unlocked.
    nonisolated static func lockedTracks(pro: Bool, ai: Bool, professional: Bool) -> Set<String> {
        var locked: Set<String> = []
        if !pro { locked.formUnion(["Go", "Rust", "Interview Prep"]) }
        if !ai { locked.insert("AI Skills") }
        if !professional { locked.insert("Professional Practice") }
        return locked
    }

    var lockedTracks: Set<String> { Self.lockedTracks(pro: isPro, ai: hasAISkills, professional: hasProfessional) }
    func isLocked(_ track: String) -> Bool { lockedTracks.contains(track) }

    static func offer(for track: String) -> PaywallOffer {
        PaywallOffer.allCases.first { $0.tracks.contains(track) } ?? .pro
    }

    /// Call before showing the paywall from a locked track.
    func preparePaywall(for track: String) { requestedOffer = Self.offer(for: track) }

    func products(for offer: PaywallOffer) -> [Product] {
        products.filter { StoreProductID(rawValue: $0.id)?.offer == offer }
    }

    func owns(_ offer: PaywallOffer) -> Bool {
        switch offer {
        case .pro: return isPro
        case .aiSkills: return hasAISkills
        case .professional: return hasProfessional
        }
    }

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
            products = try await Product.products(for: StoreProductID.allCases.map(\.rawValue))
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
        var owned: Set<PaywallOffer> = []
        for await result in StoreKit.Transaction.currentEntitlements {
            // Refunded or revoked purchases carry a revocation date and don't count.
            if case .verified(let tx) = result, tx.revocationDate == nil,
               let id = StoreProductID(rawValue: tx.productID) {
                owned.insert(id.offer)
            }
        }
        isPro = owned.contains(.pro)
        hasAISkills = owned.contains(.aiSkills)
        hasProfessional = owned.contains(.professional)
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
    @EnvironmentObject var store: LearningStore
    @Environment(\.dismiss) private var dismiss
    @State private var offer: PaywallOffer = .pro
    @State private var didSetOffer = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    paywallHeader
                    featureList
                    sampleLink
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
                    Text(offer.isSubscription
                         ? "Payment is charged to your Apple Account at confirmation. The subscription renews automatically at the price shown unless you cancel at least 24 hours before the end of the current period. Manage or cancel in Settings → Apple Account → Subscriptions."
                         : "A one-time purchase, charged to your Apple Account at confirmation. It's yours to keep, and Restore Purchases brings it back on a new device.")
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
            .navigationTitle(offer.title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !didSetOffer { offer = premiumStore.requestedOffer; didSetOffer = true }
            }
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
            Picker("Plan", selection: $offer) {
                ForEach(PaywallOffer.allCases) { Text($0.shortTitle).tag($0) }
            }
            .pickerStyle(.segmented)
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.mint, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                Image(systemName: offer.icon).font(.system(size: 36)).foregroundStyle(.white)
            }
            .accessibilityHidden(true)
            Text(offer.title).font(.title.bold())
            Text(offer.tagline)
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if premiumStore.owns(offer) {
                Label("You have this", systemImage: "checkmark.seal.fill").font(.headline).foregroundStyle(.green)
            }
        }
    }

    private var featureList: some View {
        VStack(spacing: 10) {
            ForEach(offer.features, id: \.0) { feature in
                ProFeatureRow(feature.0, icon: feature.1, color: .mint)
            }
        }
    }

    /// One free lesson from this offer, so you can see what you'd get.
    @ViewBuilder
    private var sampleLink: some View {
        if !premiumStore.owns(offer), let sample = offer.sampleLesson(in: store.lessonsByTrack) {
            NavigationLink { LessonView(lesson: sample) } label: {
                Label("Try a free lesson: \(sample.term)", systemImage: "play.circle.fill")
                    .font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 10)
            }
            .buttonStyle(.bordered).tint(.mint)
        }
    }

    @ViewBuilder
    private var productSection: some View {
        let offerProducts = premiumStore.products(for: offer)
        if offerProducts.isEmpty && !premiumStore.productsLoaded {
            ProgressView("Loading offers\u{2026}").padding(.vertical, 20)
        } else if offerProducts.isEmpty {
            VStack(spacing: 10) {
                Text("\(offer.title) isn't available right now.").font(.subheadline.weight(.semibold))
                Text("Everything outside the paid tracks stays free to use.").font(.caption).foregroundStyle(.secondary)
                Button("Try again") { Task { await premiumStore.loadProducts() } }
                    .buttonStyle(.bordered)
            }
            .multilineTextAlignment(.center)
            .padding(.vertical, 12)
        } else {
            VStack(spacing: 12) {
                ForEach(offerProducts, id: \.id) { product in
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
    @State private var introOffer: String?

    private var isYearly: Bool { product.id == ProProductID.yearly.rawValue || product.id == StoreProductID.aiYearly.rawValue }

    /// The billing period as the App Store reports it, e.g. "per month".
    private var periodLabel: String {
        guard let period = product.subscription?.subscriptionPeriod else { return product.type == .nonConsumable ? "one time" : "" }
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
                    Text(product.description.isEmpty ? (product.type == .nonConsumable ? "Yours to keep" : "Cancel anytime") : product.description)
                        .font(.caption).foregroundStyle(.secondary)
                    if let introOffer {
                        Text(introOffer).font(.caption.bold()).foregroundStyle(.mint)
                    }
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
        .task(id: product.id) { introOffer = await IntroOffer.label(for: product) }
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
