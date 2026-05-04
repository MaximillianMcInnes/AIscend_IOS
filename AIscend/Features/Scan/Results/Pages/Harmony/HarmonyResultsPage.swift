//
//  HarmonyResultsPage.swift
//  AIscend
//

import Foundation
import SwiftUI

struct HarmonyResultsPage: View {
    private let face: [String: HarmonyPayloadValue]
    private let isPaid: Bool
    private let step: Int
    private let total: Int
    private let goNext: () -> Void
    private let onUpgrade: () -> Void

    init(
        face: [String: Any],
        isPaid: Bool,
        step: Int,
        total: Int,
        goNext: @escaping () -> Void,
        onUpgrade: @escaping () -> Void
    ) {
        self.face = face.mapValues(HarmonyPayloadValue.init(any:))
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
        self.face = face.mapValues(HarmonyPayloadValue.init(scanValue:))
        self.isPaid = isPaid
        self.step = step
        self.total = total
        self.goNext = goNext
        self.onUpgrade = onUpgrade
    }

    var body: some View {
        ResultsFullscreenShell(
            title: "Facial Harmony",
            subtitle: "Proportions • balance • midface",
            step: step,
            total: total,
            topRight: {
                topRightControl
            },
            bottomCTA: {
                ResultsNextButton(title: "Next: Eyes & brows", systemImage: "arrow.right") {
                    goNext()
                }
            },
            content: {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    harmonyIntro

                    harmonyGroup(title: "Core proportions", rows: Self.coreRows)
                    harmonyGroup(title: "Balance", rows: Self.balanceRows)
                    harmonyGroup(title: "Midface", rows: Self.midfaceRows)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        )
    }

    private var harmonyIntro: some View {
        ResultsAuroraPanel(intensity: .hero, cornerRadius: 30) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
                    ZStack {
                        Circle()
                            .fill(AIscendTheme.Colors.accentGlow.opacity(0.18))
                            .frame(width: 48, height: 48)
                            .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.36), radius: 18, x: 0, y: 0)

                        Image(systemName: "scope")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Harmony read")
                            .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)

                        Text(isPaid ? "Full proportional map unlocked" : "Core traits visible")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    }

                    Spacer(minLength: AIscendTheme.Spacing.small)
                }

                Text("A compact look at how facial width, thirds, symmetry, and midface ratios work together.")
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func harmonyGroup(title: String, rows: [HarmonyRowSpec]) -> some View {
        ResultsAuroraPanel(intensity: .standard, cornerRadius: 30) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
                    Text(title)
                        .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Spacer()

                    Text("\(visibleCount(in: rows))/\(rows.count)")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        .monospacedDigit()
                }

                VStack(spacing: AIscendTheme.Spacing.small) {
                    ForEach(rows) { row in
                        harmonyRow(row)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func harmonyRow(_ row: HarmonyRowSpec) -> some View {
        let canView = isPaid || !row.isPremium

        if canView {
            if let ratio = row.ratio, let numericValue = numericValue(for: row) {
                ResultsTraitRow(
                    label: row.label,
                    value: formattedRatio(numericValue),
                    explanation: row.explanation,
                    status: status(for: numericValue, config: ratio)
                ) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                        BellCurveMini(
                            percentile: percentile(for: numericValue, config: ratio),
                            typicalRange: typicalPercentileRange(for: ratio),
                            label: "Placement P\(Int(percentile(for: numericValue, config: ratio).rounded()))"
                        )

                        RangeZoneBar(
                            value: numericValue,
                            domain: ratio.domain,
                            idealRange: ratio.ideal,
                            warningRanges: ratio.warningRanges,
                            valueLabel: "You: \(formattedRatio(numericValue))",
                            targetLabel: "Ideal \(formattedRatio(ratio.ideal.lowerBound))-\(formattedRatio(ratio.ideal.upperBound))"
                        )
                    }
                }
            } else {
                ResultsTraitRow(
                    label: row.label,
                    value: displayValue(for: row) ?? "Not detected",
                    explanation: row.explanation,
                    status: status(for: row)
                )
            }
        } else {
            ResultsLockedRow(
                label: row.label,
                value: row.ratio == nil ? "Premium insight" : "Bell curve available",
                detail: row.ratio == nil ? "Unlock the full harmony read." : "Upgrade to reveal ratio placement.",
                pillTitle: "Unlock",
                onTap: onUpgrade
            )
        }
    }

    @ViewBuilder
    private var topRightControl: some View {
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

    private func visibleCount(in rows: [HarmonyRowSpec]) -> Int {
        if isPaid {
            return rows.count
        }

        return rows.filter { !$0.isPremium }.count
    }

    private func displayValue(for row: HarmonyRowSpec) -> String? {
        guard let value = payloadValue(for: row) else {
            return nil
        }

        return value.displayString
    }

    private func numericValue(for row: HarmonyRowSpec) -> Double? {
        payloadValue(for: row)?.numberValue
    }

    private func payloadValue(for row: HarmonyRowSpec) -> HarmonyPayloadValue? {
        firstPayloadValue(for: row.keys, in: face)
    }

    private func firstPayloadValue(
        for keys: [String],
        in payload: [String: HarmonyPayloadValue]
    ) -> HarmonyPayloadValue? {
        for key in keys {
            if let value = payload[key], !value.isNull {
                return value
            }
        }

        let normalizedKeys = Set(keys.map(normalizedKey))

        for (key, value) in payload where normalizedKeys.contains(normalizedKey(key)) && !value.isNull {
            return value
        }

        for value in payload.values {
            if case .object(let nested) = value,
               let found = firstPayloadValue(for: keys, in: nested) {
                return found
            }
        }

        return nil
    }

    private func status(for row: HarmonyRowSpec) -> ResultsTraitStatus {
        let text = (displayValue(for: row) ?? "").lowercased()

        if text.contains("strong")
            || text.contains("balanced")
            || text.contains("defined")
            || text.contains("ideal")
            || text.contains("high") {
            return .strong
        }

        if text.contains("focus")
            || text.contains("weak")
            || text.contains("low")
            || text.contains("asym")
            || text.contains("wide")
            || text.contains("narrow")
            || text.contains("long")
            || text.contains("short") {
            return .focus
        }

        return .neutral
    }

    private func status(for value: Double, config: HarmonyRatioConfig) -> ResultsTraitStatus {
        if config.ideal.contains(value) {
            return .strong
        }

        if config.warningRanges.contains(where: { $0.contains(value) }) {
            return .neutral
        }

        return .focus
    }

    private func percentile(for value: Double, config: HarmonyRatioConfig) -> Double {
        guard config.sd > 0 else {
            return 50
        }

        let zScore = (value - config.mean) / config.sd
        let logisticCDF = 1 / (1 + exp(-1.702 * zScore))
        return min(max(logisticCDF * 100, 0), 100)
    }

    private func typicalPercentileRange(for config: HarmonyRatioConfig) -> ClosedRange<Double> {
        let lower = percentile(for: config.ideal.lowerBound, config: config)
        let upper = percentile(for: config.ideal.upperBound, config: config)
        return min(lower, upper)...max(lower, upper)
    }

    private func normalizedKey(_ key: String) -> String {
        key
            .lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
    }

    private func formattedRatio(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.005 {
            return "\(Int(value.rounded()))"
        }

        return String(format: "%.2f", value)
    }
}

private struct HarmonyRowSpec: Identifiable {
    let id: String
    let label: String
    let keys: [String]
    let explanation: String
    let isPremium: Bool
    let ratio: HarmonyRatioConfig?
}

private struct HarmonyRatioConfig {
    let domain: ClosedRange<Double>
    let ideal: ClosedRange<Double>
    let warningRanges: [ClosedRange<Double>]
    let mean: Double
    let sd: Double
}

private enum HarmonyPayloadValue {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: HarmonyPayloadValue])
    case array([HarmonyPayloadValue])
    case null

    init(any value: Any) {
        switch value {
        case let scanValue as ScanJSONValue:
            self.init(scanValue: scanValue)
        case let string as String:
            self = .string(string)
        case let bool as Bool:
            self = .bool(bool)
        case let number as NSNumber:
            self = .number(number.doubleValue)
        case let double as Double:
            self = .number(double)
        case let float as Float:
            self = .number(Double(float))
        case let int as Int:
            self = .number(Double(int))
        case let dictionary as [String: Any]:
            self = .object(dictionary.mapValues(HarmonyPayloadValue.init(any:)))
        case let array as [Any]:
            self = .array(array.map(HarmonyPayloadValue.init(any:)))
        default:
            self = .null
        }
    }

    init(scanValue: ScanJSONValue) {
        switch scanValue {
        case .string(let value):
            self = .string(value)
        case .number(let value):
            self = .number(value)
        case .bool(let value):
            self = .bool(value)
        case .object(let value):
            self = .object(value.mapValues(HarmonyPayloadValue.init(scanValue:)))
        case .array(let value):
            self = .array(value.map(HarmonyPayloadValue.init(scanValue:)))
        case .null:
            self = .null
        }
    }

    var isNull: Bool {
        if case .null = self {
            return true
        }

        return false
    }

    var displayString: String? {
        switch self {
        case .string(let value):
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        case .number(let value):
            if abs(value.rounded() - value) < 0.005 {
                return "\(Int(value.rounded()))"
            }

            return String(format: "%.2f", value)
        case .bool(let value):
            return value ? "Yes" : "No"
        case .object(let value):
            return value["value"]?.displayString
                ?? value["label"]?.displayString
                ?? value["rating"]?.displayString
                ?? value["score"]?.displayString
                ?? value["status"]?.displayString
                ?? value["description"]?.displayString
        case .array(let value):
            let labels = value.compactMap(\.displayString)
            guard !labels.isEmpty else {
                return nil
            }

            return Array(labels.prefix(3)).joined(separator: " | ")
        case .null:
            return nil
        }
    }

    var numberValue: Double? {
        switch self {
        case .number(let value):
            return value.isFinite ? value : nil
        case .string(let value):
            let cleaned = value
                .replacingOccurrences(of: "%", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return Double(cleaned)
        case .object(let value):
            return value["value"]?.numberValue
                ?? value["ratio"]?.numberValue
                ?? value["score"]?.numberValue
                ?? value["measurement"]?.numberValue
        default:
            return nil
        }
    }
}

private extension HarmonyResultsPage {
    static let fwhrConfig = HarmonyRatioConfig(
        domain: 1.45...2.35,
        ideal: 1.75...2.02,
        warningRanges: [1.65...1.75, 2.02...2.12],
        mean: 1.88,
        sd: 0.12
    )

    static let widthHeightConfig = HarmonyRatioConfig(
        domain: 0.68...1.08,
        ideal: 0.78...0.92,
        warningRanges: [0.74...0.78, 0.92...0.97],
        mean: 0.85,
        sd: 0.06
    )

    static let noseLengthConfig = HarmonyRatioConfig(
        domain: 0.45...0.80,
        ideal: 0.52...0.64,
        warningRanges: [0.49...0.52, 0.64...0.68],
        mean: 0.58,
        sd: 0.05
    )

    static let noseWidthConfig = HarmonyRatioConfig(
        domain: 0.30...0.70,
        ideal: 0.36...0.48,
        warningRanges: [0.33...0.36, 0.48...0.52],
        mean: 0.42,
        sd: 0.06
    )

    static let philtrumChinConfig = HarmonyRatioConfig(
        domain: 1.60...3.40,
        ideal: 2.00...2.60,
        warningRanges: [1.85...2.00, 2.60...2.85],
        mean: 2.30,
        sd: 0.25
    )

    static let coreRows: [HarmonyRowSpec] = [
        HarmonyRowSpec(
            id: "face_shape",
            label: "Face shape",
            keys: ["face_shape"],
            explanation: "The overall frame that sets the first read of the face.",
            isPremium: false,
            ratio: nil
        ),
        HarmonyRowSpec(
            id: "facial_thirds",
            label: "Facial thirds",
            keys: ["facial_thirds"],
            explanation: "Upper, mid, and lower third balance across the face.",
            isPremium: false,
            ratio: nil
        ),
        HarmonyRowSpec(
            id: "FWHR",
            label: "FWHR",
            keys: ["FWHR", "FWHR_"],
            explanation: "Width versus upper-face height.",
            isPremium: true,
            ratio: fwhrConfig
        ),
        HarmonyRowSpec(
            id: "width_height",
            label: "Width / height",
            keys: ["width_height"],
            explanation: "Facial length versus width.",
            isPremium: true,
            ratio: widthHeightConfig
        )
    ]

    static let balanceRows: [HarmonyRowSpec] = [
        HarmonyRowSpec(
            id: "facial_symmetry",
            label: "Facial symmetry",
            keys: ["facial_symmetry"],
            explanation: "Left and right balance across the face.",
            isPremium: false,
            ratio: nil
        ),
        HarmonyRowSpec(
            id: "cheekbones",
            label: "Cheekbones",
            keys: ["cheekbones"],
            explanation: "Midface support and facial structure.",
            isPremium: false,
            ratio: nil
        ),
        HarmonyRowSpec(
            id: "cheekbone_prominence",
            label: "Cheekbone prominence",
            keys: ["cheekbone_prominence"],
            explanation: "How strongly the cheekbone area supports the midface.",
            isPremium: true,
            ratio: nil
        )
    ]

    static let midfaceRows: [HarmonyRowSpec] = [
        HarmonyRowSpec(
            id: "philtrum",
            label: "Philtrum",
            keys: ["philtrum"],
            explanation: "A subtle driver of mid and lower-face perception.",
            isPremium: false,
            ratio: nil
        ),
        HarmonyRowSpec(
            id: "nose_width",
            label: "Nose width",
            keys: ["nose_width"],
            explanation: "Central balance through nose width.",
            isPremium: true,
            ratio: noseWidthConfig
        ),
        HarmonyRowSpec(
            id: "nose_length_ratio",
            label: "Nose length",
            keys: ["nose_length_ratio"],
            explanation: "Central balance through nose length.",
            isPremium: true,
            ratio: noseLengthConfig
        ),
        HarmonyRowSpec(
            id: "nose_symmetry",
            label: "Nose symmetry",
            keys: ["nose_symmetry"],
            explanation: "Side-to-side nose evenness.",
            isPremium: true,
            ratio: nil
        ),
        HarmonyRowSpec(
            id: "philtrum_chin_ratio",
            label: "Philtrum / chin ratio",
            keys: ["philtrum_chin_ratio"],
            explanation: "Lower-face balance between philtrum and chin.",
            isPremium: true,
            ratio: philtrumChinConfig
        )
    ]
}
