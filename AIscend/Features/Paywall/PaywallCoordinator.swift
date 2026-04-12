//
//  PaywallCoordinator.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation
import SwiftUI

enum PaywallVariant: String, Identifiable, Hashable, Sendable {
    case lockedInsight
    case rewardLoop
    case glowUpGate
    case deepReport

    var id: String { rawValue }

    var badgeTitle: String {
        switch self {
        case .lockedInsight:
            "Premium Insight"
        case .rewardLoop:
            "Level Up"
        case .glowUpGate:
            "Glow-Up Gate"
        case .deepReport:
            "Full Report"
        }
    }

    var title: String {
        switch self {
        case .lockedInsight:
            "The rest of this feature is behind the premium layer"
        case .rewardLoop:
            "Your next level is already visible"
        case .glowUpGate:
            "Glow-up planning sits behind the full AIScend layer"
        case .deepReport:
            "The complete report is ready to open"
        }
    }

    var subtitle: String {
        switch self {
        case .lockedInsight:
            "You have the preview. Premium reveals the deeper guidance, the sharper interpretation, and the premium-only action points."
        case .rewardLoop:
            "You have seen enough of the scan to know the upside is real. Premium is where the deeper report, better coaching, and more persuasive accountability begin."
        case .glowUpGate:
            "The routine plan, premium report layers, and stronger execution loop sit together. This is where preview mode stops."
        case .deepReport:
            "Jaw detail, side profile reads, skin context, premium routine depth, and stronger advisor support unlock immediately."
        }
    }

    var benefits: [String] {
        switch self {
        case .lockedInsight:
            [
                "Unlock full trait explanations and feature-by-feature coaching",
                "Open the jaw, skin, and side-profile layers",
                "Carry the result into the premium glow-up path"
            ]
        case .rewardLoop:
            [
                "See the premium-only report pages the free layer cannot reach",
                "Start the daily accountability loop with stronger guidance",
                "Turn the scan into a real improvement system, not a one-off reveal"
            ]
        case .glowUpGate:
            [
                "Open the premium routine blueprint tied to this scan",
                "Keep streaks, daily check-ins, and plan execution aligned",
                "Get deeper advisor help when deciding what to fix first"
            ]
        case .deepReport:
            [
                "Instant access to jaw, skin, and profile detail",
                "Reward-loop guidance designed to sustain consistency",
                "Stronger premium archive and future scan progression"
            ]
        }
    }

    var primaryTitle: String {
        "Start Free Trial"
    }

    var secondaryTitle: String? {
        switch self {
        case .lockedInsight, .rewardLoop, .deepReport:
            "Maybe Later"
        case .glowUpGate:
            "Return To Results"
        }
    }

    var signalLine: String {
        switch self {
        case .lockedInsight:
            "Unlock the premium interpretation layer"
        case .rewardLoop:
            "The next level is already available"
        case .glowUpGate:
            "Full execution starts here"
        case .deepReport:
            "Everything worth seeing is one layer deeper"
        }
    }
}

struct PaywallPresentation: Identifiable, Hashable, Sendable {
    let id = UUID()
    let variant: PaywallVariant
    let isDismissable: Bool
}

@MainActor
final class PaywallCoordinator: ObservableObject {
    @Published var activePresentation: PaywallPresentation?

    private var shownKeys = Set<String>()

    func present(
        _ variant: PaywallVariant,
        dismissable: Bool = true,
        sourceKey: String? = nil,
        force: Bool = false
    ) {
        if let sourceKey, !force, shownKeys.contains(sourceKey) {
            return
        }

        if let sourceKey {
            shownKeys.insert(sourceKey)
        }

        activePresentation = PaywallPresentation(
            variant: variant,
            isDismissable: dismissable
        )
    }

    func dismiss() {
        activePresentation = nil
    }
}
