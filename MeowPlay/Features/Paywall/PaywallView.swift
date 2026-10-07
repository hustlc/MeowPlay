import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlements: EntitlementStore
    @State private var selectedProductID = AppConfiguration.annualProductID
    @State private var legalDocument: LegalDocument?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.purple)
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text("MeowPlay Premium")
                            .font(.largeTitle.bold())
                        Text("All current sounds, unlimited favorites, full reaction history, and future sound packs.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }

                    if entitlements.products.isEmpty {
                        if entitlements.isLoading {
                            ProgressView("Loading App Store offers…")
                        } else {
                            ContentUnavailableView(
                                "Offers unavailable",
                                systemImage: "wifi.exclamationmark",
                                description: Text("You can keep using the free library and try again later.")
                            )
                        }
                    } else {
                        VStack(spacing: 12) {
                            ForEach(entitlements.products) { product in
                                productRow(product)
                            }
                        }

                        if let selectedProduct {
                            Button {
                                Task { await entitlements.purchase(selectedProduct) }
                            } label: {
                                Group {
                                    if entitlements.isLoading {
                                        ProgressView()
                                    } else {
                                        Text(purchaseButtonTitle(selectedProduct))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(entitlements.isLoading)

                            Text(renewalDisclosure(selectedProduct))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Button("Restore Purchases") {
                        Task { await entitlements.restorePurchases() }
                    }
                    .disabled(entitlements.isLoading)

                    HStack {
                        Button("Privacy") { legalDocument = .privacy }
                        Text("•").foregroundStyle(.secondary)
                        Button("Terms") { legalDocument = .terms }
                    }
                    .font(.footnote)

                    Text(AppConfiguration.disclaimer)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("App Store", isPresented: messageBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(entitlements.message ?? "")
            }
            .sheet(item: $legalDocument) { document in
                NavigationStack { LegalDocumentView(document: document) }
            }
            .onChange(of: entitlements.hasPremium) { _, hasPremium in
                if hasPremium { dismiss() }
            }
        }
    }

    private var selectedProduct: SubscriptionProduct? {
        entitlements.products.first { $0.id == selectedProductID } ?? entitlements.products.first
    }

    private var messageBinding: Binding<Bool> {
        Binding(
            get: { entitlements.message != nil },
            set: { if !$0 { entitlements.message = nil } }
        )
    }

    private func productRow(_ product: SubscriptionProduct) -> some View {
        Button {
            selectedProductID = product.id
        } label: {
            HStack {
                Image(systemName: selectedProductID == product.id ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(.purple)
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.id == AppConfiguration.annualProductID ? "Annual" : "Monthly")
                        .font(.headline)
                    if product.id == AppConfiguration.annualProductID && product.isEligibleForIntroductoryOffer {
                        Text("Your account is eligible for 7 days free")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(product.displayPrice).font(.headline)
                    Text(product.billingPeriod).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selectedProductID == product.id ? Color.purple : Color.clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }

    private func purchaseButtonTitle(_ product: SubscriptionProduct) -> String {
        product.id == AppConfiguration.annualProductID && product.isEligibleForIntroductoryOffer
            ? "Start 7-Day Free Trial"
            : "Subscribe for \(product.displayPrice)"
    }

    private func renewalDisclosure(_ product: SubscriptionProduct) -> String {
        let trial = product.id == AppConfiguration.annualProductID && product.isEligibleForIntroductoryOffer
            ? "7 days free, then "
            : ""
        return "\(trial)\(product.displayPrice) \(product.billingPeriod). Payment is charged to your Apple ID. Auto-renews until canceled. Cancel anytime in App Store subscription settings."
    }
}

