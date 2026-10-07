import Combine
import Foundation

enum PremiumAccessState: Equatable {
    case free
    case premium(expiresAt: Date)
}

private struct EntitlementSnapshot: Codable {
    let productID: String
    let verifiedAt: Date
    let accessUntil: Date
}

@MainActor
final class EntitlementStore: ObservableObject {
    @Published private(set) var products: [SubscriptionProduct] = []
    @Published private(set) var accessState: PremiumAccessState = .free
    @Published private(set) var isLoading = false
    @Published var message: String?

    var hasPremium: Bool {
        guard case .premium(let expiration) = accessState else { return false }
        return expiration > now()
    }

    private let client: SubscriptionClient
    private let defaults: UserDefaults
    private let now: () -> Date
    private let snapshotKey = "verifiedPremiumEntitlement"
    private var updatesTask: Task<Void, Never>?
    private var hasStarted = false

    init(
        client: SubscriptionClient = StoreKitSubscriptionClient(),
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = Date.init
    ) {
        self.client = client
        self.defaults = defaults
        self.now = now
        restoreValidSnapshot()
    }

    deinit {
        updatesTask?.cancel()
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        updatesTask = Task { [weak self, client] in
            for await _ in client.updates() {
                guard !Task.isCancelled else { break }
                await self?.refreshEntitlements()
            }
        }

        isLoading = true
        defer { isLoading = false }
        do {
            products = try await client.loadProducts()
        } catch {
            message = "Subscriptions are temporarily unavailable. Free sounds still work."
        }
        await refreshEntitlements()
    }

    func purchase(_ product: SubscriptionProduct) async {
        isLoading = true
        defer { isLoading = false }
        do {
            switch try await client.purchase(productID: product.id) {
            case .purchased:
                await refreshEntitlements()
                message = hasPremium ? "Premium is ready." : "Purchase received. Access is still being verified."
            case .pending:
                message = "Purchase pending. Premium will unlock after App Store approval."
            case .cancelled:
                break
            }
        } catch {
            message = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await client.sync()
            await refreshEntitlements()
            message = hasPremium ? "Purchases restored." : "No active subscription was found."
        } catch {
            message = "Purchases could not be restored: \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        let entitlements: [VerifiedEntitlement]
        do {
            entitlements = try await client.currentEntitlements()
        } catch {
            if !hasPremium {
                message = "Premium status could not be refreshed. Free sounds still work."
            }
            return
        }
        guard let best = entitlements.max(by: { $0.accessUntil < $1.accessUntil }) else {
            clearSnapshot()
            return
        }

        accessState = .premium(expiresAt: best.accessUntil)
        let snapshot = EntitlementSnapshot(
            productID: best.productID,
            verifiedAt: best.verifiedAt,
            accessUntil: best.accessUntil
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: snapshotKey)
        }
    }

    private func restoreValidSnapshot() {
        guard let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(EntitlementSnapshot.self, from: data),
              snapshot.accessUntil > now() else {
            clearSnapshot()
            return
        }
        accessState = .premium(expiresAt: snapshot.accessUntil)
    }

    private func clearSnapshot() {
        accessState = .free
        defaults.removeObject(forKey: snapshotKey)
    }
}
