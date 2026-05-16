//
//  AIScendSuperwallAnalytics.swift
//  AIscend
//

import Foundation

#if canImport(SuperwallKit)
import SuperwallKit
#endif

enum AIScendSuperwallAnalytics {
    static func configureFromBundle() {
        #if canImport(SuperwallKit)
        guard !Superwall.isInitialized else {
            return
        }

        guard let apiKey = configuredAPIKey else {
            print("Superwall skipped: add SUPERWALL_API_KEY to .env or Info.plist to enable analytics placements.")
            return
        }

        Superwall.configure(apiKey: apiKey)
        #endif
    }

    static func updateSubscriptionStatus(isPremium: Bool) {
        #if canImport(SuperwallKit)
        guard Superwall.isInitialized else {
            return
        }

        Superwall.shared.subscriptionStatus = isPremium
            ? .active([Entitlement(id: "premium")])
            : .inactive
        #endif
    }

    static func track(_ placement: String, params: [String: Any] = [:]) {
        print("AIScend Superwall placement:", placement, params)

        #if canImport(SuperwallKit)
        guard Superwall.isInitialized else {
            return
        }

        Superwall.shared.register(
            placement: placement,
            params: sanitized(params)
        )
        #endif
    }

    static func trackPaywallRequest(
        feature: AIScendPremiumFeature,
        accessPlan: AIScendUserAccessPlan,
        source: String? = nil
    ) {
        var params = feature.analyticsParams
        params["access_plan"] = accessPlan.rawValue

        if let source, !source.isEmpty {
            params["source"] = source
        }

        track(feature.superwallPlacement, params: params)
    }

    static func trackPlacementIfKnown(
        _ placement: String?,
        feature: AIScendPremiumFeature,
        accessPlan: AIScendUserAccessPlan
    ) {
        guard let placement, Self.hardGatePlacements.contains(placement) else {
            return
        }

        track(
            placement,
            params: [
                "feature": feature.rawValue,
                "access_plan": accessPlan.rawValue
            ]
        )
    }

    private static var configuredAPIKey: String? {
        let keys = [
            "SUPERWALL_API_KEY",
            "AISCEND_SUPERWALL_API_KEY"
        ]

        for key in keys {
            if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
               let cleaned = cleanedValue(value) {
                return cleaned
            }
        }

        return nil
    }

    private static let hardGatePlacements: Set<String> = [
        "chat_limit_reached",
        "scan_results_premium_gate",
        "previous_scan_locked",
        "scan_limit_reached"
    ]

    private static func cleanedValue(_ value: String) -> String? {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty, !cleaned.hasPrefix("$(") else {
            return nil
        }

        return cleaned
    }

    private static func sanitized(_ params: [String: Any]) -> [String: Any] {
        params.reduce(into: [String: Any]()) { result, pair in
            guard !pair.key.hasPrefix("$") else {
                return
            }

            switch pair.value {
            case let value as String:
                result[pair.key] = value
            case let value as Bool:
                result[pair.key] = value
            case let value as Int:
                result[pair.key] = value
            case let value as Double:
                result[pair.key] = value
            case let value as Float:
                result[pair.key] = Double(value)
            case let value as Date:
                result[pair.key] = value
            case let value as URL:
                result[pair.key] = value
            default:
                result[pair.key] = String(describing: pair.value)
            }
        }
    }
}

#if canImport(SuperwallKit)
enum AIScendSuperwallDeepLinkHandler {
    static func handle(_ url: URL) -> Bool {
        Superwall.handleDeepLink(url)
    }
}
#endif
