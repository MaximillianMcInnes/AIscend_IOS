//
//  JawResultsPage.swift
//  AIscend
//

import SwiftUI

struct JawResultsPage: View {
    private let rows: [PremiumResultTrait]
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
        self.rows = ScanResultsPremiumPageSupport.rows(from: traits)
        self.isPaid = isPaid
        self.step = step
        self.total = total
        self.goNext = goNext
        self.onUpgrade = onUpgrade
    }

    init(
        face: [String: ScanJSONValue],
        isPaid: Bool,
        step: Int,
        total: Int,
        goNext: @escaping () -> Void,
        onUpgrade: @escaping () -> Void
    ) {
        self.rows = ScanResultsPremiumPageSupport.rows(
            from: face,
            keywords: ["jaw", "chin", "mandible", "lower", "hollow"],
            fallbackExplanation: "A descriptive jaw trait from the scan. Treat it as guidance."
        )
        self.isPaid = isPaid
        self.step = step
        self.total = total
        self.goNext = goNext
        self.onUpgrade = onUpgrade
    }

    var body: some View {
        ResultsFullscreenShell(
            title: "Jaw & Chin",
            subtitle: "Definition • proportions • structure",
            step: step,
            total: total,
            topRight: {
                ScanResultsAccessPill(isPaid: isPaid, onUpgrade: onUpgrade)
            },
            bottomCTA: {
                ResultsNextButton(title: "Next: Side profile", systemImage: "arrow.right", action: goNext)
            },
            content: {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    ScanResultsFeatureIntroPanel(
                        title: isPaid ? "Full jaw read" : "Pro section",
                        copy: isPaid
                        ? "Tap any trait for a quick explanation. Jaw perception changes a lot with posture + lighting."
                        : "Jaw & chin details are Pro. Unlock to see the full jaw report.",
                        systemImage: "viewfinder"
                    )

                    ScanResultsTraitRowsPanel(
                        title: nil,
                        rows: displayedRows,
                        isPaid: isPaid,
                        freeKeys: [],
                        lockedDetail: "Reveal your jaw + chin report",
                        explanation: explanation(for:),
                        onUpgrade: onUpgrade
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        )
    }

    private var displayedRows: [PremiumResultTrait] {
        rows.isEmpty ? Self.fallbackRows : rows
    }

    private func explanation(for row: PremiumResultTrait) -> String {
        let text = ScanResultsPremiumPageSupport.normalize(row.key + " " + row.label)

        if text.contains("visibility") || text.contains("definition") {
            return "Jaw visibility shifts with lighting, posture, and body-fat level."
        }

        if text.contains("width") {
            return "Jaw width can be balanced visually with haircut, beard shape, and framing."
        }

        if text.contains("chin") {
            return "Chin structure influences lower-face proportions and profile support."
        }

        if text.contains("hollow") {
            return "Hollowing is affected by body fat, lighting, and capture angle."
        }

        return row.explanation.isEmpty ? "A descriptive jaw trait from the scan. Treat it as guidance." : row.explanation
    }

    private static let fallbackRows: [PremiumResultTrait] = [
        PremiumResultTrait(
            id: "jaw_visibility",
            key: "jaw_visibility",
            label: "Jaw visibility",
            value: "N/A",
            explanation: "Jaw visibility shifts with lighting, posture, and body-fat level.",
            locked: false
        ),
        PremiumResultTrait(
            id: "chin_support",
            key: "chin_support",
            label: "Chin support",
            value: "N/A",
            explanation: "Chin structure influences lower-face proportions and profile support.",
            locked: false
        )
    ]
}
