//
//  SideProfileResultsPage.swift
//  AIscend
//

import SwiftUI

struct SideProfileResultsPage: View {
    private let sections: [SideProfileSection]
    private let isPaid: Bool
    private let step: Int
    private let total: Int
    private let goNext: () -> Void
    private let onUpgrade: () -> Void

    @State private var revealSections = false

    init(
        traits: [ScanTraitRowModel],
        isPaid: Bool,
        step: Int,
        total: Int,
        goNext: @escaping () -> Void,
        onUpgrade: @escaping () -> Void
    ) {
        let rows = ScanResultsPremiumPageSupport.rows(from: traits)
        let noseRows = rows.filter(Self.isNoseRow)
        let harmonyRows = rows.filter { !Self.isNoseRow($0) }
        self.sections = Self.sections(
            faceRows: harmonyRows,
            noseRows: noseRows,
            extraSections: []
        )
        self.isPaid = isPaid
        self.step = step
        self.total = total
        self.goNext = goNext
        self.onUpgrade = onUpgrade
    }

    init(
        sideProfile: [String: ScanJSONValue],
        isPaid: Bool,
        step: Int,
        total: Int,
        goNext: @escaping () -> Void,
        onUpgrade: @escaping () -> Void
    ) {
        let facePayload = sideProfile["face"]?.objectValue ?? sideProfile
        let nosePayload = sideProfile["nose"]?.objectValue ?? [:]
        let knownSectionKeys = Set(["face", "nose"])
        let extraSections = sideProfile
            .filter { knownSectionKeys.contains($0.key) == false && $0.value.objectValue != nil }
            .map { key, value in
                SideProfileSection(
                    id: "extra-\(key)",
                    title: Self.prettifiedSectionTitle(key),
                    subtitle: "Additional profile signals returned by the scan. Use them as supporting context around the main face and nose reads.",
                    rows: Self.rows(from: value.objectValue ?? [:], fallbackExplanation: "This is an additional side-profile signal from the scan.")
                )
            }

        self.sections = Self.sections(
            faceRows: Self.rows(
                from: facePayload,
                fallbackExplanation: "This describes how the structural profile line reads from the side."
            ),
            noseRows: Self.rows(
                from: nosePayload,
                fallbackExplanation: "Nose and brow-ridge details shape the central side-profile silhouette."
            ),
            extraSections: extraSections
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
                ResultsNextButton(title: "Continue", systemImage: "arrow.right", action: goNext)
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
                    .opacity(revealSections ? 1 : 0)
                    .offset(y: revealSections ? 0 : 14)

                    ForEach(Array(displayedSections.enumerated()), id: \.element.id) { index, section in
                        SideProfileSectionPanel(
                            section: section,
                            index: index,
                            isPaid: isPaid,
                            reveal: revealSections,
                            explanation: explanation(for:),
                            onUpgrade: onUpgrade
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        )
        .onAppear {
            withAnimation(.smooth(duration: 0.42)) {
                revealSections = true
            }
        }
    }

    private var displayedSections: [SideProfileSection] {
        sections.isEmpty ? Self.fallbackSections : sections
    }

    private func explanation(for row: PremiumResultTrait) -> String {
        let text = ScanResultsPremiumPageSupport.normalize(row.key + " " + row.label)

        if text.contains("ramus") {
            return "Ramus height affects how tall and supported the back of the lower jaw appears from the side."
        }

        if text.contains("mandible") {
            return "Mandible position describes how the lower jaw sits in the side profile and how much structural support it gives the face."
        }

        if text.contains("maxilla") {
            return "Maxilla read is a directional estimate of midface support and forward growth from the profile angle."
        }

        if text.contains("chinprojection") || text.contains("chin") {
            return "Chin projection affects whether the lower profile line feels supported, recessed, or over-pronounced."
        }

        if text.contains("gonial") {
            return "Gonial angle describes the jaw-corner angle. It influences whether the side profile reads sharper or softer."
        }

        if text.contains("facialconvexity") || text.contains("convexity") {
            return "Facial convexity looks at the curve from forehead to midface to chin, which shapes overall profile harmony."
        }

        if text.contains("nosebump") {
            return "Nose bump checks whether the bridge has a visible raised contour from the side."
        }

        if text.contains("noseshape") {
            return "Nose shape describes the profile silhouette of the nose, including whether it reads straight, convex, or softer."
        }

        if text.contains("browridge") {
            return "Brow-ridge prominence affects the upper profile frame and how strongly the eyes and nose bridge are anchored."
        }

        if text.contains("nose") || text.contains("nasal") {
            return "Nose shape and projection affect side-profile harmony and the central silhouette."
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

    private static func sections(
        faceRows: [PremiumResultTrait],
        noseRows: [PremiumResultTrait],
        extraSections: [SideProfileSection]
    ) -> [SideProfileSection] {
        var output: [SideProfileSection] = []

        if !faceRows.isEmpty {
            output.append(
                SideProfileSection(
                    id: "face-structure",
                    title: "Face structure",
                    subtitle: "Jaw, chin, maxilla, ramus, and convexity signals that define the side-profile line.",
                    rows: ordered(faceRows, preferredKeys: [
                        "ramus",
                        "mandible",
                        "maxilla",
                        "chinprojection",
                        "gonialangle",
                        "facialconvexityangle",
                        "facialconvexity"
                    ])
                )
            )
        }

        if !noseRows.isEmpty {
            output.append(
                SideProfileSection(
                    id: "nose-brow",
                    title: "Nose and brow",
                    subtitle: "Nose bridge, shape, bump, and brow-ridge signals that shape the central profile silhouette.",
                    rows: ordered(noseRows, preferredKeys: [
                        "nosebump",
                        "noseshape",
                        "browridgeprominence",
                        "noseprojection"
                    ])
                )
            )
        }

        output.append(contentsOf: extraSections.filter { !$0.rows.isEmpty })
        return output
    }

    private static func rows(
        from payload: [String: ScanJSONValue],
        fallbackExplanation: String
    ) -> [PremiumResultTrait] {
        flattenedEntries(payload)
            .compactMap { entry in
                guard entry.value.displayString != nil else {
                    return nil
                }

                return PremiumResultTrait(
                    id: entry.key,
                    key: entry.key,
                    label: ScanResultsPremiumPageSupport.prettifyKey(entry.key),
                    value: ScanResultsPremiumPageSupport.renderValue(entry.value.displayString),
                    explanation: entry.value.objectValue?["description"]?.stringValue
                        ?? entry.value.objectValue?["why"]?.stringValue
                        ?? entry.value.objectValue?["notes"]?.stringValue
                        ?? fallbackExplanation,
                    locked: false
                )
            }
    }

    private static func flattenedEntries(
        _ payload: [String: ScanJSONValue],
        prefix: String = ""
    ) -> [(key: String, value: ScanJSONValue)] {
        payload.flatMap { key, value in
            let composedKey = prefix.isEmpty ? key : "\(prefix).\(key)"

            if let object = value.objectValue {
                let display = value.displayString
                if display != nil {
                    return [(composedKey, value)]
                }

                return flattenedEntries(object, prefix: composedKey)
            }

            if let array = value.arrayValue {
                return array.enumerated().compactMap { index, item in
                    guard item.displayString != nil else {
                        return nil
                    }

                    return ("\(composedKey).\(index + 1)", item)
                }
            }

            return [(composedKey, value)]
        }
    }

    private static func ordered(
        _ rows: [PremiumResultTrait],
        preferredKeys: [String]
    ) -> [PremiumResultTrait] {
        rows.sorted { lhs, rhs in
            let leftKey = ScanResultsPremiumPageSupport.normalize(lhs.key + lhs.label)
            let rightKey = ScanResultsPremiumPageSupport.normalize(rhs.key + rhs.label)
            let leftIndex = preferredKeys.firstIndex { leftKey.contains($0) } ?? preferredKeys.count
            let rightIndex = preferredKeys.firstIndex { rightKey.contains($0) } ?? preferredKeys.count

            if leftIndex != rightIndex {
                return leftIndex < rightIndex
            }

            return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
        }
    }

    private static func prettifiedSectionTitle(_ key: String) -> String {
        ScanResultsPremiumPageSupport.prettifyKey(key)
    }

    private static let fallbackSections: [SideProfileSection] = [
        SideProfileSection(
            id: "fallback-face",
            title: "Face structure",
            subtitle: "Jaw, chin, and midface signals that define the side-profile line.",
            rows: [
                PremiumResultTrait(
                    id: "profile_harmony",
                    key: "profile_harmony",
                    label: "Profile harmony",
                    value: "N/A",
                    explanation: "Profile harmony depends on posture, lens distance, and how the nose, chin, and jaw read together.",
                    locked: false
                )
            ]
        ),
        SideProfileSection(
            id: "fallback-nose",
            title: "Nose and brow",
            subtitle: "Nose bridge and brow-ridge details that shape the central profile silhouette.",
            rows: [
                PremiumResultTrait(
                    id: "nose_profile",
                    key: "nose_profile",
                    label: "Nose profile",
                    value: "N/A",
                    explanation: "Nose traits affect side-profile harmony and central balance.",
                    locked: false
                )
            ]
        )
    ]
}

private struct SideProfileSection: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let rows: [PremiumResultTrait]
}

private struct SideProfileSectionPanel: View {
    let section: SideProfileSection
    let index: Int
    let isPaid: Bool
    let reveal: Bool
    let explanation: (PremiumResultTrait) -> String
    let onUpgrade: () -> Void

    var body: some View {
        ResultsAuroraPanel(intensity: .standard, cornerRadius: 30) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                        Text(section.title)
                            .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)

                        Text(section.subtitle)
                            .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: AIscendTheme.Spacing.small)

                    Text("\(section.rows.count)")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                        .monospacedDigit()
                        .padding(.horizontal, AIscendTheme.Spacing.small)
                        .padding(.vertical, 7)
                        .background(Capsule(style: .continuous).fill(AIscendTheme.Colors.accentGlow.opacity(0.14)))
                        .overlay(Capsule(style: .continuous).stroke(AIscendTheme.Colors.accentGlow.opacity(0.26), lineWidth: 1))
                }

                VStack(spacing: AIscendTheme.Spacing.small) {
                    ForEach(Array(section.rows.enumerated()), id: \.element.id) { rowIndex, row in
                        rowView(row)
                            .opacity(reveal ? 1 : 0)
                            .offset(y: reveal ? 0 : 10)
                            .animation(
                                .smooth(duration: 0.34).delay(Double(index) * 0.06 + Double(rowIndex) * 0.035),
                                value: reveal
                            )
                    }
                }
            }
        }
        .opacity(reveal ? 1 : 0)
        .offset(y: reveal ? 0 : 18)
        .animation(.smooth(duration: 0.38).delay(Double(index) * 0.08), value: reveal)
    }

    @ViewBuilder
    private func rowView(_ row: PremiumResultTrait) -> some View {
        if isPaid {
            ResultsTraitRow(
                label: row.label,
                value: row.value,
                explanation: explanation(row),
                status: ScanResultsPremiumPageSupport.status(for: row)
            )
        } else {
            ResultsLockedRow(
                label: row.label,
                value: "Unlock with Premium",
                detail: "Reveal full side profile",
                pillTitle: "Unlock with Premium",
                onTap: onUpgrade
            )
        }
    }
}
