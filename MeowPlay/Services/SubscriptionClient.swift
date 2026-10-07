import Foundation
import StoreKit

struct SubscriptionProduct: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let displayPrice: String
    let billingPeriod: String
    let isEligibleForIntroductoryOffer: Bool

    var sortOrder: Int {
        id == AppConfiguration.monthlyProductID ? 0 : 1
    }
}

struct VerifiedEntitlement: Equatable, Sendable {
    let productID: String
    let verifiedAt: Date
    let accessUntil: Date
}

enum SubscriptionPurchaseOutcome: Equatable, Sendable {
    case purchased
    case pending
    case cancelled
}

enum SubscriptionClientError: LocalizedError {
    case productUnavailable
    case failedVerification
    case unknownPurchaseResult

    var errorDescription: String? {
        switch self {
        case .productUnavailable: "That subscription is currently unavailable."
        case .failedVerification: "The App Store could not verify this purchase."
        case .unknownPurchaseResult: "The App Store returned an unknown purchase result."
        }
    }
}

@MainActor
protocol SubscriptionClient: AnyObject {
    func loadProducts() async throws -> [SubscriptionProduct]
    func purchase(productID: String) async throws -> SubscriptionPurchaseOutcome
    func currentEntitlements() async throws -> [VerifiedEntitlement]
    func sync() async throws
    func updates() -> AsyncStream<Void>
}

@MainActor
final class StoreKitSubscriptionClient: SubscriptionClient {
    private var productsByID: [String: Product] = [:]

    func loadProducts() async throws -> [SubscriptionProduct] {
        let products = try await Product.products(for: AppConfiguration.productIDs)
        productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })

        var mapped: [SubscriptionProduct] = []
        for product in products {
            let isEligible = await product.subscription?.isEligibleForIntroOffer ?? false
            mapped.append(SubscriptionProduct(
                id: product.id,
                displayName: product.displayName,
                displayPrice: product.displayPrice,
                billingPeriod: Self.billingPeriod(for: product),
                isEligibleForIntroductoryOffer: isEligible
            ))
        }
        return mapped.sorted { $0.sortOrder < $1.sortOrder }
    }

    func purchase(productID: String) async throws -> SubscriptionPurchaseOutcome {
        if productsByID[productID] == nil {
            _ = try await loadProducts()
        }
        guard let product = productsByID[productID] else {
            throw SubscriptionClientError.productUnavailable
        }

        switch try await product.purchase() {
        case .success(let verification):
            let transaction = try Self.verified(verification)
            await transaction.finish()
            return .purchased
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            throw SubscriptionClientError.unknownPurchaseResult
        }
    }

    func currentEntitlements() async throws -> [VerifiedEntitlement] {
        let now = Date()
        var entitlements: [String: VerifiedEntitlement] = [:]

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  AppConfiguration.productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil,
                  let expirationDate = transaction.expirationDate,
                  expirationDate > now else { continue }
            entitlements[transaction.productID] = VerifiedEntitlement(
                productID: transaction.productID,
                verifiedAt: now,
                accessUntil: expirationDate
            )
        }

        if !entitlements.isEmpty {
            return Array(entitlements.values)
        }

        // Grace-period transactions can have a normal expiration in the past. StoreKit's
        // subscription status supplies the separately verified grace expiration date.
        if productsByID.isEmpty {
            _ = try await loadProducts()
        }
        for product in productsByID.values {
            guard let subscription = product.subscription else { continue }
            let statuses = try await subscription.status
            for status in statuses {
                // Billing retry alone does not extend access. If Apple still reports an
                // unexpired verified transaction, it was already accepted above. Grace
                // access is granted only through Apple's verified grace expiration.
                guard status.state == .inGracePeriod,
                      case .verified(let renewalInfo) = status.renewalInfo,
                      case .verified(let transaction) = status.transaction,
                      transaction.revocationDate == nil,
                      let graceEnd = renewalInfo.gracePeriodExpirationDate,
                      graceEnd > now else { continue }
                entitlements[product.id] = VerifiedEntitlement(
                    productID: product.id,
                    verifiedAt: now,
                    accessUntil: graceEnd
                )
            }
        }

        return Array(entitlements.values)
    }

    func sync() async throws {
        try await AppStore.sync()
    }

    func updates() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let task = Task {
                for await result in Transaction.updates {
                    guard !Task.isCancelled else { break }
                    guard case .verified(let transaction) = result else { continue }
                    await transaction.finish()
                    continuation.yield(())
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): value
        case .unverified: throw SubscriptionClientError.failedVerification
        }
    }

    private static func billingPeriod(for product: Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else { return "" }
        let unit: String
        switch period.unit {
        case .day: unit = period.value == 1 ? "day" : "days"
        case .week: unit = period.value == 1 ? "week" : "weeks"
        case .month: unit = period.value == 1 ? "month" : "months"
        case .year: unit = period.value == 1 ? "year" : "years"
        @unknown default: unit = "period"
        }
        return "every \(period.value) \(unit)"
    }
}
