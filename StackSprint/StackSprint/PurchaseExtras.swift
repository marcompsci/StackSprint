import StoreKit
import SwiftUI

// MARK: - Free sample lessons
//
// Each paid offer lets you try one lesson before buying, so the paywall shows real
// content instead of a list of promises.

extension PaywallOffer {
    /// The first lesson of the offer's first track, playable without buying.
    func sampleLesson(in lessonsByTrack: [String: [Lesson]]) -> Lesson? {
        switch self {
        case .aiSkills: return PaidContent.ai.first
        case .professional: return PaidContent.professional.first
        case .pro:
            return ["Go", "Rust", "Interview Prep"].lazy.compactMap { lessonsByTrack[$0]?.first }.first
        }
    }
}

// MARK: - Introductory offers

enum IntroOffer {
    static func periodText(value: Int, unit: Product.SubscriptionPeriod.Unit) -> String {
        let name: String
        switch unit {
        case .day: name = "day"
        case .week: name = "week"
        case .month: name = "month"
        case .year: name = "year"
        @unknown default: name = "period"
        }
        return value == 1 ? "1 \(name)" : "\(value) \(name)s"
    }

    /// What the App Store says this learner can get first, e.g. "Free for 1 week, then $4.99".
    /// Nil when there's no introductory offer or the learner has already used one.
    static func label(for product: Product) async -> String? {
        guard let subscription = product.subscription, let offer = subscription.introductoryOffer,
              await subscription.isEligibleForIntroOffer else { return nil }
        let period = periodText(value: offer.period.value, unit: offer.period.unit)
        switch offer.paymentMode {
        case .freeTrial:
            return "Free for \(period), then \(product.displayPrice)"
        case .payUpFront:
            return "\(offer.displayPrice) for the first \(period), then \(product.displayPrice)"
        case .payAsYouGo:
            return "\(offer.displayPrice) per \(periodText(value: offer.period.value, unit: offer.period.unit)) for \(offer.periodCount) \(offer.periodCount == 1 ? "period" : "periods"), then \(product.displayPrice)"
        default:
            return nil
        }
    }
}

// MARK: - Managing purchases (Account)

/// Manage subscriptions and request refunds without leaving the app.
struct OwnedPurchase: Identifiable {
    let title: String
    let transactionID: UInt64
    var id: UInt64 { transactionID }
}

struct PurchaseManagementRows: View {
    @EnvironmentObject var premiumStore: PremiumStore
    @State private var showingManage = false
    @State private var owned: [OwnedPurchase] = []
    @State private var choosingRefund = false
    @State private var refundID: UInt64?
    @State private var showingRefund = false
    @State private var redeeming = false

    var body: some View {
        Group {
            Button {
                redeeming = true
            } label: {
                Label("Redeem an offer code", systemImage: "giftcard")
            }
            if premiumStore.isPro || premiumStore.hasAISkills {
                Button {
                    showingManage = true
                } label: {
                    Label("Manage subscriptions", systemImage: "gearshape")
                }
            }
            if !owned.isEmpty {
                Button {
                    choosingRefund = true
                } label: {
                    Label("Request a refund", systemImage: "arrow.uturn.backward.circle")
                }
            }
        }
        .manageSubscriptionsSheet(isPresented: $showingManage)
        .offerCodeRedemption(isPresented: $redeeming) { _ in
            Task { await premiumStore.refreshEntitlements() }
        }
        .refundRequestSheet(for: refundID ?? 0, isPresented: $showingRefund)
        .confirmationDialog("Which purchase?", isPresented: $choosingRefund, titleVisibility: .visible) {
            ForEach(owned) { item in
                Button(item.title) {
                    refundID = item.transactionID
                    showingRefund = true
                }
            }
        } message: {
            Text("Apple reviews refund requests. You'll get an email with the decision.")
        }
        .task(id: premiumStore.isPro || premiumStore.hasAISkills || premiumStore.hasProfessional) { await loadOwned() }
    }

    private func loadOwned() async {
        var list: [OwnedPurchase] = []
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result, transaction.revocationDate == nil,
                  let id = StoreProductID(rawValue: transaction.productID) else { continue }
            list.append(OwnedPurchase(title: id.offer.title, transactionID: transaction.id))
        }
        owned = list
    }
}
