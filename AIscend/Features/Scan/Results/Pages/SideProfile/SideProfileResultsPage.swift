//
//  SideProfileResultsPage.swift
//  AIscend
//

import SwiftUI

struct SideProfileResultsPage: View {
    private let noseRows: [PremiumResultTrait]
    private let harmonyRows: [PremiumResultTrait]
    private let isPaid: Bool
    private let step: Int
    private let total: Int
    private let goNext: () -> Void
    private let onUpgrade: () -> Void

    init(
        traits: [ScanTraitRowModel],
        isPaid: Bool,
        step: Int,
        total: Int,
        goNext: @escaping () -> Void,
        onUpgrade: @escaping () -> Void
    ) {
        let rows = ScanResultsPremiumPageSupport.rows(from: traits)
        self.noseRows = rows.filter(Self.isNoseRow)
        self.harmonyRows = rows.filter { !Self.isNoseRow($0) }
        self.isPaid = isPaid
        self.step = step
        self.total = total
        self.goNext = goNext
        self.onUpgrade = onUpgrade
    }

    init(
        nose: [String: ScanJSONValue],
        harmony: [String: ScanJSONValue],
        isPaid: Bool,
        step: Int,
        total: Int,
        goNext: @escaping () -> Void,
        onUpgrade: @escaping () -> Void
    ) {
        self.noseRows = ScanResultsPremiumPageSupport.rows(
            from: nose,
            keywords: ["nose", "nasal"],
            fallbackExplanation: "Nose traits affect side-profile harmony and central balance."
        )
        self.harmonyRows = ScanResultsPremiumPageSupport.rows(
            from: harmony,
            keywords: ["profile", "side", "chin", "jaw", "maxilla", "mandible", "projection", "convexity", "harmony"],
            fallbackExplanation: "Profile harmony depends on posture, lens distance, and how the nose, chin, and jaw read together."
        )
        self.isPaid = isPaid
        self.step = step
        self.total = total
        self.goNext = goNext
        self.onUpgrade = onUpgrade
    }

    var body: some View {
        ResultsFullscreenShell(
            title: "Side Profile",
            subtitle: "Nose + profile harmony",
            step: step,
            total: total,
            topRight: {
                ScanResultsAccessPill(isPaid: isPaid, onUpgrade: onUpgrade)
            },
            bottomCTA: {
                ResultsNextButton(title: "Back to overview", systemImage: "arrow.uturn.left", action: goNext)
            },
            content: {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    ScanResultsFeatureIntroPanel(
                        title: isPaid ? "Profile harmony" : "Pro section",
                        copy: isPaid
                        ? "Profile balance can look different depending on posture and camera lens. Treat this as guidance."
                        : "Side profile is Pro. Unlock to see the full profile harmony report.",
                        systemImage: "person.crop.square"
                    )

                    ScanResultsTraitRowsPanel(
                        title: "Nose",
                        rows: displayedNoseRows,
                        isPaid: isPaid,
                        freeKeys: [],
                        lockedDetail: "Reveal full side profile",
                        explanation: explanation(for:),
                        onUpgrade: onUpgrade
                    )

                    ScanResultsTraitRowsPanel(
                        title: "Harmony",
                        rows: displayedHarmonyRows,
                        isPaid: isPaid,
                        freeKeys: [],
                        lockedDetail: "Reveal full side profile",
                        explanation: explanation(for:),
                        onUpgrade: onUpgrade
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        )
    }

    private var displayedNoseRows: [PremiumResultTrait] {
        noseRows.isEmpty ? Self.fallbackNoseRows : noseRows
    }

    private var displayedHarmonyRows: [PremiumResultTrait] {
        harmonyRows.isEmpty ? Self.fallbackHarmonyRows : harmonyRows
    }

    private func explanation(for row: PremiumResultTrait) -> String {
        let text = ScanResultsPremiumPageSupport.normalize(row.key + " " + row.label)

        if text.contains("nose") || text.contains("nasal") {
            return "Nose shape and projection affect profile harmony."
        }

        if text.contains("jaw") || text.contains("chin") {
            return "Jaw and chin reads can shift with posture, body fat, lighting, and capture angle."
        }

        if text.contains("maxilla") || text.contains("mandible") {
            return "This is a relative forward-growth and structure estimate from the scan."
        }

        return row.explanation.isEmpty ? "Profile harmony depends on posture, lens distance, and how the features read together." : row.explanation
    }

    private static func isNoseRow(_ row: PremiumResultTrait) -> Bool {
        let text = ScanResultsPremiumPageSupport.normalize(row.key + " " + row.label)
        return text.contains("nose") || text.contains("nasal")
    }

    private static let fallbackNoseRows: [PremiumResultTrait] = [
        PremiumResultTrait(
            id: "nose_profile",
            key: "nose_profile",
            label: "Nose profile",
            value: "N/A",
            explanation: "Nose traits affect side-profile harmony and central balance.",
            locked: false
        )
    ]

    private static let fallbackHarmonyRows: [PremiumResultTrait] = [
        PremiumResultTrait(
            id: "profile_harmony",
            key: "profile_harmony",
            label: "Profile harmony",
            value: "N/A",
            explanation: "Profile harmony depends on posture, lens distance, and how the nose, chin, and jaw read together.",
            locked: false
        )
    ]
}
