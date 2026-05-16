//
//  SubscriptionManager.swift
//  AIscend
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
final class SubscriptionManager: ObservableObject {

    static let shared = SubscriptionManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPremium = false
    @Published private(set) var isLoading = false
    @Published private(set) var isPurchasing = false
    @Published var errorMessage: String?

    enum ProductID {
        // These must EXACTLY match App Store Connect:
        // Monetization -> Subscriptions -> AIscend subs -> Product ID
        static let monthly = "AIscend_Monthly"
        static let yearly = "AIscend_Pro_Yearly"

        static let all = [
            monthly,
            yearly
        ]
    }

    private var transactionListenerTask: Task<Void, Never>?

    private init() {
        transactionListenerTask = Task { [weak self] in
            await self?.listenForTransactions()
        }

        Task {
            await loadProducts()
            await updatePremiumStatus()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    var monthlyProduct: Product? {
        product(for: ProductID.monthly)
    }

    var yearlyProduct: Product? {
        product(for: ProductID.yearly)
    }

    func product(for productID: String) -> Product? {
        products.first { $0.id == productID }
    }

    func displayPrice(for productID: String, fallback: String) -> String {
        product(for: productID)?.displayPrice ?? fallback
    }

    // MARK: - Load Products

    func loadProducts() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let loadedProducts = try await Product.products(for: ProductID.all)

            products = loadedProducts.sorted { lhs, rhs in
                let lhsIndex = ProductID.all.firstIndex(of: lhs.id) ?? 999
                let rhsIndex = ProductID.all.firstIndex(of: rhs.id) ?? 999
                return lhsIndex < rhsIndex
            }

            print("✅ StoreKit products loaded:", products.map(\.id))

            if products.isEmpty {
                print("""
                ⚠️ StoreKit returned zero products.
                Check:
                1. Product IDs are exactly AIscend_Monthly and AIscend_Pro_Yearly.
                2. Xcode target has In-App Purchase capability.
                3. Local Xcode uses a .storekit config OR TestFlight uses App Store Connect products.
                4. Paid Apps Agreement, tax, and banking are complete.
                5. Bundle ID matches the App Store Connect app.
                """)
            }
        } catch {
            errorMessage = "Could not load subscription products."
            print("❌ Failed loading StoreKit products:", error)
        }
    }

    // MARK: - Purchase

    func purchase(productID: String) async {
        print("🔥 SubscriptionManager.purchase called:", productID)

        if products.isEmpty {
            await loadProducts()
        }

        guard let product = product(for: productID) else {
            errorMessage = "Subscription product unavailable: \(productID)"
            print("❌ Product not found:", productID)
            print("Loaded products:", products.map(\.id))
            return
        }

        guard !isPurchasing else {
            print("⚠️ Purchase ignored because another purchase is already running.")
            return
        }

        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            print("🛒 Starting Apple purchase sheet for:", product.id)

            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                print("✅ Purchase verified:", transaction.productID)

                await transaction.finish()
                await updatePremiumStatus()

                if isPremium {
                    print("⭐ Premium unlocked.")
                }

            case .userCancelled:
                print("⚠️ Purchase cancelled by user")

            case .pending:
                errorMessage = "Purchase pending approval."
                print("⏳ Purchase pending")

            @unknown default:
                errorMessage = "Unknown purchase result."
                print("❓ Unknown purchase result")
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
            print("❌ Purchase failed:", error)
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        errorMessage = nil

        do {
            print("🔁 Starting restore purchases")
            try await AppStore.sync()
            await updatePremiumStatus()
            print("✅ Restore complete. Premium:", isPremium)
        } catch {
            errorMessage = "Restore failed. Please try again."
            print("❌ Restore failed:", error)
        }
    }

    // MARK: - Premium Status

    func updatePremiumStatus() async {
        var premiumActive = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                guard ProductID.all.contains(transaction.productID) else {
                    continue
                }

                if let expirationDate = transaction.expirationDate, expirationDate < Date() {
                    continue
                }

                if transaction.revocationDate != nil {
                    continue
                }

                premiumActive = true
            } catch {
                print("❌ Entitlement verification failed:", error)
            }
        }

        isPremium = premiumActive
        print("⭐ Premium active:", premiumActive)
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)

                print("🔄 Transaction update received:", transaction.productID)

                await transaction.finish()
                await updatePremiumStatus()
            } catch {
                print("❌ Transaction listener verification failed:", error)
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.failedVerification
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
