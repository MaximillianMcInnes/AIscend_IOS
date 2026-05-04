//
//  ScanResultsPremiumPageSupport.swift
//  AIscend
//

import SwiftUI

struct PremiumResultTrait: Identifiable, Hashable {
    let id: String
    let key: String
    let label: String
    let value: String
    let explanation: String
    let locked: Bool
}

enum ScanResultsPremiumPageSupport {
    static func rows(from traits: [ScanTraitRowModel]) -> [PremiumResultTrait] {
        traits
            .map { trait in
                PremiumResultTrait(
                    id: trait.id,
                    key: trait.id,
                    label: trait.label,
                    value: renderValue(trait.value),
                    explanation: trait.explanation,
                    locked: trait.locked
                )
            }
            .sorted { lhs, rhs in
                lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
            }
    }

    static func rows(
        from payload: [String: ScanJSONValue],
        keywords: [String],
        fallbackExplanation: String
    ) -> [PremiumResultTrait] {
        let normalizedKeywords = keywords.map(normalize)

        return flattenedEntries(payload)
            .filter { entry in
                let searchable = normalize(entry.key + " " + prettifyKey(entry.key))
                return normalizedKeywords.contains { searchable.contains($0) }
            }
            .compactMap { entry in
                let label = prettifyKey(entry.key)
                let explanation = entry.value.objectValue?["description"]?.stringValue
                    ?? entry.value.objectValue?["why"]?.stringValue
                    ?? entry.value.objectValue?["notes"]?.stringValue
                    ?? fallbackExplanation

                return PremiumResultTrait(
                    id: entry.key,
                    key: entry.key,
                    label: label,
                    value: renderValue(entry.value.displayString),
                    explanation: explanation,
                    locked: false
                )
            }
            .sorted { lhs, rhs in
                lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
            }
    }

    static func prettifyKey(_ key: String) -> String {
        PersistedScanRecord.normalizedLabel(for: key.components(separatedBy: ".").last ?? key)
    }

    static func renderValue(_ value: String?) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed = trimmed, !trimmed.isEmpty else {
            return "N/A"
        }

        return trimmed
    }

    static func normalize(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
    }

    static func matches(_ row: PremiumResultTrait, keys: Set<String>) -> Bool {
        let key = normalize(row.key)
        let label = normalize(row.label)
        return keys.contains { freeKey in
            key == freeKey
            || label == freeKey
            || key.hasSuffix(freeKey)
            || label.hasSuffix(freeKey)
        }
    }

    static func status(for row: PremiumResultTrait) -> ResultsTraitStatus {
        let text = (row.label + " " + row.value).lowercased()

        if text.contains("strong")
            || text.contains("balanced")
            || text.contains("defined")
            || text.contains("ideal")
            || text.contains("full") {
            return .strong
        }

        if text.contains("focus")
            || text.contains("weak")
            || text.contains("low")
            || text.contains("asym")
            || text.contains("thin")
            || text.contains("recessed") {
            return .focus
        }

        return .neutral
    }

    private static func flattenedEntries(
        _ payload: [String: ScanJSONValue],
        prefix: String = ""
    ) -> [(key: String, value: ScanJSONValue)] {
        payload.flatMap { key, value in
            let composedKey = prefix.isEmpty ? key : "\(prefix).\(key)"

            if let object = value.objectValue {
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
}

struct ScanResultsAccessPill: View {
    let isPaid: Bool
    let onUpgrade: () -> Void

    var body: some View {
        if isPaid {
            HStack(spacing: 7) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))

                Text("Pro")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
            }
            .padding(.horizontal, AIscendTheme.Spacing.small)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(AIscendTheme.Colors.accentGlow.opacity(0.16))
                    .background(.ultraThinMaterial, in: Capsule(style: .continuous))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AIscendTheme.Colors.accentGlow.opacity(0.34), lineWidth: 1)
            )
        } else {
            Button(action: onUpgrade) {
                HStack(spacing: 7) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 11, weight: .bold))

                    Text("Unlock")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                }
                .padding(.horizontal, AIscendTheme.Spacing.small)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(AIscendTheme.Colors.accentGlow.opacity(0.18))
                        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(AIscendTheme.Colors.accentGlow.opacity(0.34), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

struct ScanResultsFeatureIntroPanel: View {
    let title: String
    let copy: String
    var systemImage: String = "sparkles"

    var body: some View {
        ResultsAuroraPanel(intensity: .hero, cornerRadius: 30) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(AIscendTheme.Colors.accentGlow.opacity(0.18))
                        .frame(width: 48, height: 48)
                        .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.36), radius: 18, x: 0, y: 0)

                    Image(systemName: systemImage)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    Text(title)
                        .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)

                    Text(copy)
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct ScanResultsTraitRowsPanel: View {
    let title: String?
    let rows: [PremiumResultTrait]
    let isPaid: Bool
    let freeKeys: Set<String>
    let lockedDetail: String
    let explanation: (PremiumResultTrait) -> String
    let onUpgrade: () -> Void

    var body: some View {
        ResultsAuroraPanel(intensity: .standard, cornerRadius: 30) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                if let title {
                    Text(title)
                        .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                VStack(spacing: AIscendTheme.Spacing.small) {
                    ForEach(rows) { row in
                        rowView(row)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func rowView(_ row: PremiumResultTrait) -> some View {
        let canView = isPaid || (!row.locked && ScanResultsPremiumPageSupport.matches(row, keys: freeKeys))

        if canView {
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
                detail: lockedDetail,
                pillTitle: "Unlock with Premium",
                onTap: onUpgrade
            )
        }
    }
}
