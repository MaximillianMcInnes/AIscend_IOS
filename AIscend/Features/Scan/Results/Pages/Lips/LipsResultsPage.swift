//
//  LipsResultsPage.swift
//  AIscend
//

import SwiftUI

struct LipsResultsPage: View {
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
            keywords: ["lip", "mouth", "philtrum", "smile", "fullness", "cupid", "colour", "color"],
            fallbackExplanation: "A descriptive lip trait from the scan. Use it as practical guidance."
        )
        self.isPaid = isPaid
        self.step = step
        self.total = total
        self.goNext = goNext
        self.onUpgrade = onUpgrade
    }

    var body: some View {
        ResultsFullscreenShell(
            title: "Lips",
            subtitle: "Shape • fullness • details",
            step: step,
            total: total,
            topRight: {
                ScanResultsAccessPill(isPaid: isPaid, onUpgrade: onUpgrade)
            },
            bottomCTA: {
                ResultsNextButton(title: "Next: Jaw & chin", systemImage: "arrow.right", action: goNext)
            },
            content: {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    ScanResultsFeatureIntroPanel(
                        title: isPaid ? "Full lip read" : "Preview mode",
                        copy: isPaid
                        ? "Tap any trait for a short explanation. Lip care + grooming are quick wins."
                        : "Preview mode: key lip traits are shown. Unlock Pro for the full lip report.",
                        systemImage: "mouth"
                    )

                    ScanResultsTraitRowsPanel(
                        title: nil,
                        rows: displayedRows,
                        isPaid: isPaid,
                        freeKeys: Self.freeKeys,
                        lockedDetail: "See the full lip report",
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

        if text.contains("fullness") {
            return "Fullness affects perceived balance and softness in the lower centre face."
        }

        if text.contains("type") {
            return "Type is the general lip shape read from the scan."
        }

        if text.contains("cupid") {
            return "Cupid's bow definition changes how crisp the lip shape appears."
        }

        if text.contains("width") {
            return "Width is a proportion trait that affects how grounded the mouth area feels."
        }

        if text.contains("colour") || text.contains("color") {
            return "Lip colour can shift with sleep, circulation, lighting, and overall health."
        }

        return row.explanation.isEmpty ? "A descriptive lip trait from the scan. Use it as practical guidance." : row.explanation
    }

    private static let freeKeys: Set<String> = [
        "type",
        "fullness"
    ]

    private static let fallbackRows: [PremiumResultTrait] = [
        PremiumResultTrait(
            id: "type",
            key: "type",
            label: "Type",
            value: "N/A",
            explanation: "Type is the general lip shape read from the scan.",
            locked: false
        ),
        PremiumResultTrait(
            id: "fullness",
            key: "fullness",
            label: "Fullness",
            value: "N/A",
            explanation: "Fullness affects perceived balance and softness in the lower centre face.",
            locked: false
        ),
        PremiumResultTrait(
            id: "cupid_bow",
            key: "cupid_bow",
            label: "Cupid's bow",
            value: "N/A",
            explanation: "Cupid's bow definition changes how crisp the lip shape appears.",
            locked: false
        )
    ]
}
