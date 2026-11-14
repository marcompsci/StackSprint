import SwiftUI

// MARK: - Privacy policy, terms and support
//
// The privacy policy ships inside the app so it is always reachable, even offline.
// Keep it in sync with docs/privacy-policy.md and the App Privacy answers in
// App Store Connect whenever data handling changes.

enum LegalLinks {
    /// Apple's standard licensed application end user license agreement.
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    /// Where testers and customers reach a person. Must be set before any TestFlight
    /// or App Store submission (scripts/compliance-check.sh fails while it's empty).
    static let supportEmail = ""
    static var supportMailURL: URL? {
        supportEmail.isEmpty ? nil : URL(string: "mailto:\(supportEmail)?subject=StackSprint%20support")
    }
    static let policyUpdated = "November 12, 2026"
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Last updated \(LegalLinks.policyUpdated)").font(.footnote).foregroundStyle(.secondary)
                section("The short version",
                        "StackSprint works without an account. Your lessons, streaks, code and projects are stored on your device. We don’t sell data, show ads, or track you across apps or websites.")
                section("What stays on your device",
                        "Lesson progress, quiz scores, streaks, XP, season progress, Studio missions, free-build projects, code drafts and settings are saved locally on this device. Deleting the app deletes them. If you save a backup file from Account, it goes only where you choose to save it; we never receive it.")
                section("Sign in with Apple",
                        "If you choose Sign in with Apple, Apple shares an identifier and, the first time only, the name and email you choose to share. StackSprint keeps these on your device to label your progress. They aren’t sent to us. Signing out removes them.")
                section("Optional cloud account",
                        "If cloud accounts are turned on in your version of the app and you create one, your email address, an account ID and the IDs of lessons you’ve completed are stored with our database provider (Supabase) so you can sync progress. You can delete the account and all of its server data from Account → Delete account.")
                section("Game Center",
                        "Study Room races use Apple’s Game Center. Game Center shows your Game Center name to the player you race and sends only your race score. Apple’s privacy policy covers Game Center.")
                section("On-device AI",
                        "Bit the tutor and generated lessons use Apple Intelligence on your device. Your questions are processed on the device and aren’t sent to us.")
                section("Python lessons",
                        "The first time you run Python, the app downloads the open-source Pyodide runtime from the jsDelivr network. Like any web request, this shares your IP address with jsDelivr. Your code runs on your device and isn’t uploaded.")
                section("Purchases",
                        "Subscriptions are handled by Apple. We receive no payment details. The app checks your subscription status with the App Store.")
                section("Notifications",
                        "Reminders are scheduled on your device only if you allow notifications. We don’t send push notifications.")
                section("Sharing",
                        "When you share a streak, a challenge link, a portfolio or an exported page, you choose where it goes through the iOS share sheet. Challenge links contain the lesson IDs, your score and the name you entered.")
                section("Children",
                        "StackSprint isn’t directed at children under 13 and doesn’t knowingly collect personal information from them.")
                if !LegalLinks.supportEmail.isEmpty {
                    section("Contact", "Questions or deletion requests: \(LegalLinks.supportEmail).")
                }
            }
            .padding(24)
            .frame(maxWidth: 700, alignment: .leading)
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(body).foregroundStyle(.secondary)
        }
    }
}

/// Privacy policy, terms and support, for Account and any screen that sells something.
struct LegalLinksSection: View {
    var body: some View {
        Section("Help and legal") {
            NavigationLink { PrivacyPolicyView() } label: {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }
            Link(destination: LegalLinks.termsOfUse) {
                Label("Terms of Use (EULA)", systemImage: "doc.text")
            }
            if let mail = LegalLinks.supportMailURL {
                Link(destination: mail) {
                    Label("Contact support", systemImage: "envelope")
                }
            }
        }
    }
}
