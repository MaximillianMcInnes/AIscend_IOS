//
//  AIScendPremiumAccess.swift
//  AIscend
//

import Foundation

enum AIScendUserAccessPlan: String {
    case free
    case premium

    var isPremium: Bool {
        self == .premium
    }

    func canOpen(_ feature: AIScendPremiumFeature) -> Bool {
        isPremium || !feature.requiresPremium
    }
}

enum AIScendPremiumFeature: String, CaseIterable, Identifiable {
    case lockedScanDiagnostics
    case scanTransformation
    case glowUpRoutine
    case glowUpProgress
    case previousScanHistory
    case aiRoadmap
    case dailyPhotoProgress
    case nutritionStrategy
    case chatQuota

    var id: String { rawValue }

    var requiresPremium: Bool {
        switch self {
        case .lockedScanDiagnostics,
             .scanTransformation,
             .glowUpRoutine,
             .glowUpProgress,
             .previousScanHistory,
             .aiRoadmap,
             .dailyPhotoProgress,
             .nutritionStrategy,
             .chatQuota:
            true
        }
    }

    var paywallVariant: AIScendPremiumPaywallVariant {
        switch self {
        case .lockedScanDiagnostics, .previousScanHistory:
            .diagnostics
        case .scanTransformation:
            .transformation
        case .glowUpRoutine,
             .glowUpProgress,
             .aiRoadmap,
             .dailyPhotoProgress,
             .nutritionStrategy:
            .progress
        case .chatQuota:
            .chat
        }
    }

    var paywallOffer: AIScendPremiumPaywallOffer {
        switch self {
        case .lockedScanDiagnostics, .scanTransformation, .glowUpRoutine, .glowUpProgress, .previousScanHistory, .aiRoadmap, .dailyPhotoProgress, .nutritionStrategy, .chatQuota:
            .threeDayTrial
        }
    }

    var superwallPlacement: String {
        switch self {
        case .chatQuota:
            return "chat_limit_reached"
        case .lockedScanDiagnostics:
            return "scan_results_premium_gate"
        case .previousScanHistory:
            return "previous_scan_locked"
        default:
            break
        }

        return "aiscend_paywall_\(rawValue)"
    }

    var analyticsParams: [String: Any] {
        [
            "feature": rawValue,
            "requires_premium": requiresPremium,
            "paywall_variant": paywallVariant.rawValue,
            "offer": paywallOffer.rawValue
        ]
    }
}
