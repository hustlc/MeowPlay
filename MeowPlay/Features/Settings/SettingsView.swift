import StoreKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var entitlements: EntitlementStore
    @State private var isShowingPaywall = false

    var body: some View {
        NavigationStack {
            List {
                Section("Premium") {
                    HStack {
                        Label(entitlements.hasPremium ? "Premium active" : "Free plan", systemImage: entitlements.hasPremium ? "checkmark.seal.fill" : "pawprint.fill")
                        Spacer()
                        if entitlements.isLoading { ProgressView() }
                    }

                    if !entitlements.hasPremium {
                        Button("See Premium options") { isShowingPaywall = true }
                    }

                    Button("Restore Purchases") {
                        Task { await entitlements.restorePurchases() }
                    }
                    .disabled(entitlements.isLoading)

                    Link("Manage Subscription", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                }

                Section("About your data") {
                    Label("No account", systemImage: "person.crop.circle.badge.xmark")
                    Label("Activity stays on this device", systemImage: "iphone")
                    Label("No microphone or tracking", systemImage: "hand.raised.fill")
                }

                Section("Legal & support") {
                    NavigationLink("Privacy") { LegalDocumentView(document: .privacy) }
                    NavigationLink("Terms") { LegalDocumentView(document: .terms) }
                    Link("Support", destination: AppConfiguration.supportURL)
                }

                Section("Important") {
                    Text(AppConfiguration.disclaimer)
                        .font(.footnote)
                    Text("Begin at low volume and stop if your cat seems uncomfortable.")
                        .font(.footnote)
                }

                Section {
                    Text("Version \(appVersion)")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $isShowingPaywall) { PaywallView() }
            .alert("App Store", isPresented: messageBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(entitlements.message ?? "")
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    private var messageBinding: Binding<Bool> {
        Binding(
            get: { entitlements.message != nil },
            set: { if !$0 { entitlements.message = nil } }
        )
    }
}

