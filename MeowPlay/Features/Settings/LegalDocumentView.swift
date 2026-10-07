import SwiftUI

enum LegalDocument: String, Identifiable {
    case privacy = "Privacy"
    case terms = "Terms"

    var id: String { rawValue }
}

struct LegalDocumentView: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(document.rawValue)
                    .font(.largeTitle.bold())
                Text("Draft — last updated September 14, 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if document == .privacy {
                    privacyContent
                } else {
                    termsContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(document.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private var privacyContent: some View {
        Group {
            section("Summary", "MeowPlay does not require an account and does not collect, transmit, sell, or use your activity for tracking. Favorites, playback history, and cat reactions stay in the app's local storage on your device.")
            section("Permissions", "The app does not request microphone, camera, location, contacts, or advertising-tracking permission.")
            section("Purchases", "Apple processes subscriptions and related transaction information under Apple's privacy terms. The app reads verified subscription status from StoreKit to decide whether Premium features are available.")
            section("Support", "If you contact support, the publisher will receive the information you voluntarily include in that message. The final public policy must describe its retention and deletion process before release.")
            section("Children", "The app is intended for a general audience and is not directed to children under 13.")
            section("Changes", "Material changes will be reflected in the public Privacy Policy and its effective date.")
        }
    }

    private var termsContent: some View {
        Group {
            section("Entertainment only", AppConfiguration.disclaimer)
            section("Animal comfort", "Use a low volume, play each sound only briefly, supervise every session, and stop immediately if an animal appears uncomfortable. Do not use the app as a substitute for veterinary or professional behavioral care.")
            section("Subscriptions", "Premium is sold as an auto-renewable monthly or annual subscription. Price, trial eligibility, and billing period are shown by Apple before purchase. Payment is charged to the Apple ID account. A subscription renews unless canceled in App Store subscription settings. Canceling preserves access through the paid entitlement period, subject to Apple's terms.")
            section("Content license", "The app and its audio are licensed for personal, non-commercial use inside the app. Copying, redistributing, extracting, or reselling the audio is not permitted.")
            section("Availability", "Features and sound packs may change as the library evolves. Already-paid access will not be intentionally removed during an active entitlement period.")
            section("Final review required", "These in-app terms are a product draft. The publisher must obtain appropriate legal review and publish final Terms and Privacy pages before App Store submission.")
        }
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(body).foregroundStyle(.secondary)
        }
    }
}

