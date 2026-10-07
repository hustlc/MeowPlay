import Foundation
import XCTest
@testable import MeowPlay

@MainActor
final class EntitlementStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName = ""

    override func setUp() {
        super.setUp()
        suiteName = "EntitlementStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = ""
        super.tearDown()
    }

    func testVerifiedUnexpiredEntitlementUnlocksPremium() async {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let client = FakeSubscriptionClient()
        client.entitlements = [
            VerifiedEntitlement(
                productID: AppConfiguration.annualProductID,
                verifiedAt: now,
                accessUntil: now.addingTimeInterval(3_600)
            )
        ]
        let store = EntitlementStore(client: client, defaults: defaults, now: { now })

        await store.refreshEntitlements()

        XCTAssertTrue(store.hasPremium)
    }

    func testExpiredEntitlementDoesNotUnlockPremium() async {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let client = FakeSubscriptionClient()
        client.entitlements = [
            VerifiedEntitlement(
                productID: AppConfiguration.monthlyProductID,
                verifiedAt: now.addingTimeInterval(-7_200),
                accessUntil: now.addingTimeInterval(-3_600)
            )
        ]
        let store = EntitlementStore(client: client, defaults: defaults, now: { now })

        await store.refreshEntitlements()

        XCTAssertFalse(store.hasPremium)
    }

    func testPendingPurchaseDoesNotUnlockPremium() async {
        let client = FakeSubscriptionClient()
        client.purchaseOutcome = .pending
        let store = EntitlementStore(client: client, defaults: defaults)
        let product = FakeSubscriptionClient.monthlyProduct

        await store.purchase(product)

        XCTAssertFalse(store.hasPremium)
        XCTAssertEqual(store.message, "Purchase pending. Premium will unlock after App Store approval.")
    }

    func testAuthoritativeEmptyRefreshRevokesCachedAccess() async {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let client = FakeSubscriptionClient()
        client.entitlements = [
            VerifiedEntitlement(
                productID: AppConfiguration.annualProductID,
                verifiedAt: now,
                accessUntil: now.addingTimeInterval(3_600)
            )
        ]
        let store = EntitlementStore(client: client, defaults: defaults, now: { now })
        await store.refreshEntitlements()
        XCTAssertTrue(store.hasPremium)

        client.entitlements = []
        await store.refreshEntitlements()

        XCTAssertFalse(store.hasPremium)
    }

    func testRestoreRefreshesVerifiedEntitlement() async {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let client = FakeSubscriptionClient()
        client.entitlements = [
            VerifiedEntitlement(
                productID: AppConfiguration.annualProductID,
                verifiedAt: now,
                accessUntil: now.addingTimeInterval(86_400)
            )
        ]
        let store = EntitlementStore(client: client, defaults: defaults, now: { now })

        await store.restorePurchases()

        XCTAssertTrue(client.didSync)
        XCTAssertTrue(store.hasPremium)
        XCTAssertEqual(store.message, "Purchases restored.")
    }

    func testValidVerifiedSnapshotWorksOfflineUntilExpiration() async {
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        let onlineClient = FakeSubscriptionClient()
        onlineClient.entitlements = [
            VerifiedEntitlement(
                productID: AppConfiguration.annualProductID,
                verifiedAt: base,
                accessUntil: base.addingTimeInterval(3_600)
            )
        ]
        let onlineStore = EntitlementStore(client: onlineClient, defaults: defaults, now: { base })
        await onlineStore.refreshEntitlements()

        let offlineClient = FakeSubscriptionClient()
        let offlineStore = EntitlementStore(
            client: offlineClient,
            defaults: defaults,
            now: { base.addingTimeInterval(1_800) }
        )

        XCTAssertTrue(offlineStore.hasPremium)
    }

    func testStoreKitFailurePreservesUnexpiredOfflineSnapshot() async {
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        let client = FakeSubscriptionClient()
        client.entitlements = [
            VerifiedEntitlement(
                productID: AppConfiguration.annualProductID,
                verifiedAt: base,
                accessUntil: base.addingTimeInterval(3_600)
            )
        ]
        let store = EntitlementStore(client: client, defaults: defaults, now: { base })
        await store.refreshEntitlements()
        XCTAssertTrue(store.hasPremium)

        client.entitlementError = FakeError.storeUnavailable
        await store.refreshEntitlements()

        XCTAssertTrue(store.hasPremium)
    }
}

private enum FakeError: Error {
    case storeUnavailable
}

@MainActor
private final class FakeSubscriptionClient: SubscriptionClient {
    static let monthlyProduct = SubscriptionProduct(
        id: AppConfiguration.monthlyProductID,
        displayName: "Premium Monthly",
        displayPrice: "$4.99",
        billingPeriod: "every 1 month",
        isEligibleForIntroductoryOffer: false
    )

    var products = [monthlyProduct]
    var entitlements: [VerifiedEntitlement] = []
    var purchaseOutcome: SubscriptionPurchaseOutcome = .cancelled
    var didSync = false
    var continuation: AsyncStream<Void>.Continuation?
    var entitlementError: Error?

    func loadProducts() async throws -> [SubscriptionProduct] { products }

    func purchase(productID: String) async throws -> SubscriptionPurchaseOutcome {
        purchaseOutcome
    }

    func currentEntitlements() async throws -> [VerifiedEntitlement] {
        if let entitlementError { throw entitlementError }
        return entitlements
    }

    func sync() async throws { didSync = true }

    func updates() -> AsyncStream<Void> {
        AsyncStream { continuation = $0 }
    }
}
