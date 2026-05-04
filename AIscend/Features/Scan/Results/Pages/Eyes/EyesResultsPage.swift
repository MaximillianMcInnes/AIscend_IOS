//
//  EyesResultsPage.swift
//  AIscend
//

import SwiftUI

struct EyesResultsPage: View {
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
            keywords: ["eye", "brow", "canthal", "orbital", "eyelid", "spacing", "tilt"],
            fallbackExplanation: "A descriptive trait from the scan. Use it as guidance rather than a fixed label."
        )
        self.isPaid = isPaid
        self.step = step
        self.total = total
        self.goNext = goNext
        self.onUpgrade = onUpgrade
    }

    var body: some View {
        ResultsFullscreenShell(
            title: "Eyes & Brows",
            subtitle: "Eye area + eyebrow traits",
            step: step,
            total: total,
            topRight: {
                ScanResultsAccessPill(isPaid: isPaid, onUpgrade: onUpgrade)
            },
            bottomCTA: {
                ResultsNextButton(title: "Next: Lips & jaw", systemImage: "arrow.right", action: goNext)
            },
            content: {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    ScanResultsFeatureIntroPanel(
                        title: isPaid ? "Full eye read" : "Preview mode",
                        copy: isPaid
                        ? "Tap any trait for a short explanation. Brows are one of the fastest visual improvements."
                        : "Preview mode: key eye metrics are shown. Unlock Pro for the full eye + brow report.",
                        systemImage: "eye"
                    )

                    ScanResultsTraitRowsPanel(
                        title: nil,
                        rows: displayedRows,
                        isPaid: isPaid,
                        freeKeys: Self.freeKeys,
                        lockedDetail: "Get the full eye + brow report",
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

        if text.contains("spacing") {
            return "Eye spacing affects harmony; one-eye-width spacing is typical."
        }

        if text.contains("canthal") || text.contains("tilt") {
            return "Canthal tilt is the angle between the inner and outer corners."
        }

        if text.contains("brow") || text.contains("eyebrow") {
            return "Brows frame the eyes and can shift the whole upper-face read quickly."
        }

        return row.explanation.isEmpty ? "A descriptive trait from the scan. Use it as guidance." : row.explanation
    }

    private static let freeKeys: Set<String> = [
        "eyespacing",
        "canthaltilt",
        "type",
        "eyespacing",
        "canthaltilt"
    ]

    private static let fallbackRows: [PremiumResultTrait] = [
        PremiumResultTrait(
            id: "eye_spacing",
            key: "eye_spacing",
            label: "Eye Spacing",
            value: "N/A",
            explanation: "Eye spacing affects harmony; one-eye-width spacing is typical.",
            locked: false
        ),
        PremiumResultTrait(
            id: "canthal_tilt",
            key: "canthal_tilt",
            label: "Canthal Tilt",
            value: "N/A",
            explanation: "Canthal tilt is the angle between the inner and outer corners.",
            locked: false
        ),
        PremiumResultTrait(
            id: "eyebrow_frame",
            key: "eyebrow_frame",
            label: "Eyebrow frame",
            value: "N/A",
            explanation: "Brows frame the eyes and can shift the whole upper-face read quickly.",
            locked: false
        )
    ]
}
