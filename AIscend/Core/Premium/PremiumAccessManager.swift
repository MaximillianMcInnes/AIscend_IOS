//
//  PremiumAccessManager.swift
//  AIscend
//

import Foundation
import Observation
import StoreKit
import UIKit

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

@MainActor
final class PremiumAccessManager: ObservableObject {
    static let shared = PremiumAccessManager()

    @Published private(set) var isPremium = false
    @Published private(set) var subscriptionStatus: AIScendSubscriptionStatus = .free
    @Published private(set) var premiumProductID: String?
    @Published private(set) var premiumExpiresAt: Date?
    @Published private(set) var premiumTransactionID: String?
    @Published private(set) var premiumOriginalTransactionID: String?
    @Published private(set) var premiumLastVerifiedAt: Date?
    @Published private(set) var scansLeft: Int?
    @Published private(set) var monthlyChatsLeft: Int?
    @Published private(set) var products: [Product] = []
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var isSyncing = false

    private let productIDs: [String]
    private var entitlementListenerTask: Task<Void, Never>?
    private var syncedUserID: String?
    private var syncedEmail: String?

    private init() {
        productIDs = Self.configuredProductIDs
    }

    deinit {
        entitlementListenerTask?.cancel()
    }

    func start(userID: String?, email: String?) async {
        syncedUserID = normalizedUserID(userID)
        syncedEmail = normalizedEmail(email)
        startListeningForTransactionsIfNeeded()
        await loadProducts()
        await syncEntitlementsToFirestore()
    }

    func refresh(userID: String?, email: String?) async {
        syncedUserID = normalizedUserID(userID)
        syncedEmail = normalizedEmail(email)
        await syncEntitlementsToFirestore()
    }

    func purchase(productID: String) async -> Bool {
        let normalizedProductID = productID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedProductID.isEmpty else {
            return false
        }

        if products.isEmpty {
            await loadProducts()
        }

        guard let product = products.first(where: { $0.id == normalizedProductID }) else {
            lastErrorMessage = "This Premium product is not available yet."
            return false
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await syncEntitlementsToFirestore()
                return isPremium
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            await syncEntitlementsToFirestore()
            return false
        }
    }

    func restorePurchases() async -> Bool {
        do {
            try await AppStore.sync()
            await syncEntitlementsToFirestore()
            return isPremium
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    func canStartScan() -> Bool {
        if isPremium {
            return true
        }

        guard let scansLeft else {
            return true
        }

        return scansLeft > 0
    }

    func recordFreeScanUsedIfNeeded() async {
        guard !isPremium else {
            return
        }

        guard let userID = syncedUserID, !userID.isEmpty else {
            return
        }

        #if canImport(FirebaseFirestore)
        do {
            try await setData(
                [
                    "scansLeft": FieldValue.increment(Int64(-1)),
                    "premiumLastSyncedAt": FieldValue.serverTimestamp()
                ],
                on: Firestore.firestore().collection("Users").document(userID),
                merge: true
            )
            if let scansLeft {
                self.scansLeft = max(scansLeft - 1, 0)
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
        #endif
    }

    func openManageSubscriptions() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else {
            return
        }

        UIApplication.shared.open(url)
    }

    private func loadProducts() async {
        guard !productIDs.isEmpty else {
            return
        }

        do {
            products = try await Product.products(for: productIDs)
                .sorted {
                    let lhsIndex = productIDs.firstIndex(of: $0.id) ?? Int.max
                    let rhsIndex = productIDs.firstIndex(of: $1.id) ?? Int.max
                    return lhsIndex < rhsIndex
                }
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func syncEntitlementsToFirestore() async {
        isSyncing = true
        defer { isSyncing = false }

        let entitlement = await currentStoreKitEntitlement()
        apply(entitlement)
        AIScendSuperwallAnalytics.updateSubscriptionStatus(isPremium: entitlement.isPremium)
        await mirrorToFirestore(entitlement)
        await loadFirestoreCompatibilityFields()
    }

    private func currentStoreKitEntitlement() async -> PremiumEntitlementSnapshot {
        var activeTransactions: [StoreKit.Transaction] = []
        let now = Date()

        for await result in StoreKit.Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else {
                continue
            }

            guard productIDs.contains(transaction.productID) else {
                continue
            }

            guard transaction.revocationDate == nil else {
                continue
            }

            if let expirationDate = transaction.expirationDate, expirationDate <= now {
                continue
            }

            activeTransactions.append(transaction)
        }

        guard let transaction = activeTransactions.sorted(by: {
            ($0.expirationDate ?? $0.purchaseDate) > ($1.expirationDate ?? $1.purchaseDate)
        }).first else {
            return PremiumEntitlementSnapshot(
                isPremium: false,
                status: .expired,
                productID: premiumProductID,
                expiresAt: premiumExpiresAt,
                transactionID: premiumTransactionID,
                originalTransactionID: premiumOriginalTransactionID,
                verifiedAt: now
            )
        }

        return PremiumEntitlementSnapshot(
            isPremium: true,
            status: .active,
            productID: transaction.productID,
            expiresAt: transaction.expirationDate,
            transactionID: String(transaction.id),
            originalTransactionID: String(transaction.originalID),
            verifiedAt: now
        )
    }

    private func apply(_ entitlement: PremiumEntitlementSnapshot) {
        isPremium = entitlement.isPremium
        subscriptionStatus = entitlement.status
        premiumProductID = entitlement.productID
        premiumExpiresAt = entitlement.expiresAt
        premiumTransactionID = entitlement.transactionID
        premiumOriginalTransactionID = entitlement.originalTransactionID
        premiumLastVerifiedAt = entitlement.verifiedAt
    }

    private func mirrorToFirestore(_ entitlement: PremiumEntitlementSnapshot) async {
        guard let userID = syncedUserID, !userID.isEmpty else {
            return
        }

        #if canImport(FirebaseFirestore)
        var payload: [String: Any] = [
            "subscription": entitlement.isPremium ? "Paid" : "Free",
            "isPremium": entitlement.isPremium,
            "subscriptionStatus": entitlement.status.rawValue,
            "premiumSource": "storekit2",
            "premiumLastVerifiedAt": Timestamp(date: entitlement.verifiedAt),
            "premiumLastSyncedAt": FieldValue.serverTimestamp()
        ]

        if let productID = entitlement.productID {
            payload["premiumProductId"] = productID
        }

        if let expiresAt = entitlement.expiresAt {
            payload["premiumExpiresAt"] = Timestamp(date: expiresAt)
        }

        if let transactionID = entitlement.transactionID {
            payload["premiumTransactionId"] = transactionID
        }

        if let originalTransactionID = entitlement.originalTransactionID {
            payload["premiumOriginalTransactionId"] = originalTransactionID
        }

        do {
            try await setData(payload, on: Firestore.firestore().collection("Users").document(userID), merge: true)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
        #endif
    }

    private func loadFirestoreCompatibilityFields() async {
        guard let userID = syncedUserID, !userID.isEmpty else {
            scansLeft = nil
            monthlyChatsLeft = nil
            return
        }

        #if canImport(FirebaseFirestore)
        do {
            let snapshot = try await getDocument(Firestore.firestore().collection("Users").document(userID))
            let data = snapshot.data() ?? [:]
            scansLeft = Self.intValue(for: ["scansLeft", "ScansLeft"], in: data)
            monthlyChatsLeft = Self.intValue(for: ["monthlyChatsLeft", "MonthlyChatsLeft"], in: data)

            if !isPremium {
                let mirroredPremium: Bool
                if let explicitPremium = Self.boolValue(for: ["isPremium"], in: data) {
                    mirroredPremium = explicitPremium
                } else {
                    mirroredPremium = Self.stringValue(for: ["subscription"], in: data)?
                        .caseInsensitiveCompare("Paid") == .orderedSame
                }
                if mirroredPremium == true {
                    await mirrorToFirestore(PremiumEntitlementSnapshot.free(verifiedAt: Date()))
                }
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
        #endif
    }

    private func startListeningForTransactionsIfNeeded() {
        guard entitlementListenerTask == nil else {
            return
        }

        entitlementListenerTask = Task.detached { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self else {
                    return
                }

                if let transaction = try? await self.checkVerified(result) {
                    await transaction.finish()
                }

                await self.syncEntitlementsToFirestore()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw error
        }
    }

    private func normalizedUserID(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func normalizedEmail(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed.lowercased()
    }

    private static var configuredProductIDs: [String] {
        let configured = stringValue(for: "AISCEND_PREMIUM_PRODUCT_IDS")?
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let configured, !configured.isEmpty {
            return configured
        }

        return [
            stringValue(for: "AISCEND_PREMIUM_MONTHLY_PRODUCT_ID") ?? "aiscend_premium_monthly",
            stringValue(for: "AISCEND_PREMIUM_YEARLY_PRODUCT_ID") ?? "aiscend_premium_yearly"
        ]
    }

    private static func stringValue(for key: String) -> String? {
        if let environmentValue = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !environmentValue.isEmpty
        {
            return environmentValue
        }

        if let infoValue = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmed = infoValue.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        return nil
    }
}

enum AIScendSubscriptionStatus: String, Sendable {
    case active
    case trialing
    case expired
    case free
}

private struct PremiumEntitlementSnapshot: Sendable {
    let isPremium: Bool
    let status: AIScendSubscriptionStatus
    let productID: String?
    let expiresAt: Date?
    let transactionID: String?
    let originalTransactionID: String?
    let verifiedAt: Date

    static func free(verifiedAt: Date) -> PremiumEntitlementSnapshot {
        PremiumEntitlementSnapshot(
            isPremium: false,
            status: .free,
            productID: nil,
            expiresAt: nil,
            transactionID: nil,
            originalTransactionID: nil,
            verifiedAt: verifiedAt
        )
    }
}

#if canImport(FirebaseFirestore)
private extension PremiumAccessManager {
    func getDocument(_ reference: DocumentReference) async throws -> DocumentSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            reference.getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: NSError(domain: "AIscendPremium", code: -1))
                }
            }
        }
    }

    func setData(_ data: [String: Any], on reference: DocumentReference, merge: Bool) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.setData(data, merge: merge) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    static func stringValue(for keys: [String], in data: [String: Any]) -> String? {
        for key in keys {
            if let value = data[key] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }

        return nil
    }

    static func intValue(for keys: [String], in data: [String: Any]) -> Int? {
        for key in keys {
            if let value = data[key] as? Int {
                return value
            }

            if let value = data[key] as? NSNumber {
                return value.intValue
            }

            if let value = data[key] as? String, let intValue = Int(value) {
                return intValue
            }
        }

        return nil
    }

    static func boolValue(for keys: [String], in data: [String: Any]) -> Bool? {
        for key in keys {
            if let value = data[key] as? Bool {
                return value
            }

            if let value = data[key] as? NSNumber {
                return value.boolValue
            }

            if let value = data[key] as? String {
                switch value.lowercased() {
                case "true", "1", "yes", "active", "premium", "paid":
                    return true
                case "false", "0", "no", "free", "inactive", "expired":
                    return false
                default:
                    break
                }
            }
        }

        return nil
    }
}
#endif
