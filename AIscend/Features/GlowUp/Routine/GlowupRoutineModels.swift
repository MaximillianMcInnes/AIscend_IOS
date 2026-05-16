//
//  GlowupRoutineModels.swift
//  AIscend
//

import Foundation

enum GlowupSectionKey: String, CaseIterable, Codable, Hashable, Sendable {
    case haircut
    case eyebrow
    case jaw
    case lip
    case side
    case skin
    case general
}

struct GlowupScanSignal: Identifiable, Hashable, Sendable {
    let id: String
    let label: String
    let value: String
    let detail: String?
}

struct GlowupGoalSubSection: Identifiable, Hashable, Sendable {
    let title: String
    let goal: String
    let actions: [String]
    let personalisedTips: [String]

    var id: String {
        "\(title)|\(goal)"
    }
}

struct GlowupRoutineSection: Identifiable, Hashable, Sendable {
    let key: GlowupSectionKey
    let title: String
    let goal: String
    let summary: String
    let goals: [GlowupGoalSubSection]
    let observedSignals: [GlowupScanSignal]
    let actions: [String]
    let personalisedTips: [String]
    let snapshotChips: [String]
    let avoid: [String]
    let symbol: String
    let accent: RoutineAccent

    var id: String { key.rawValue }
}

struct GlowupRoutineInput: Hashable, Sendable {
    let scanId: String?
    let source: String
    let fingerprint: String
    let overallScore: Double
    let potentialScore: Double
    let generatedFromSummary: String
    let sections: [GlowupRoutineSection]

    var firestoreSections: [GlowupSectionKey: GlowupSectionPayload] {
        sections.reduce(into: [GlowupSectionKey: GlowupSectionPayload]()) { partialResult, section in
            partialResult[section.key] = GlowupSectionPayload(
                title: section.title,
                goal: section.goal,
                summary: section.summary,
                goals: section.goals.isEmpty
                    ? [
                        GlowupGoalSubSection(
                            title: section.title,
                            goal: section.goal,
                            actions: section.actions,
                            personalisedTips: section.personalisedTips
                        )
                    ]
                    : section.goals,
                observedSignals: section.observedSignals.map { "\($0.label): \($0.value)" },
                actions: section.actions,
                personalisedTips: section.personalisedTips,
                snapshotChips: section.snapshotChips,
                avoid: section.avoid,
                scanId: scanId,
                source: source,
                fingerprint: fingerprint
            )
        }
    }
}

struct GlowupSectionPayload: Hashable, Sendable {
    let title: String
    let goal: String
    let summary: String
    let goals: [GlowupGoalSubSection]
    let observedSignals: [String]
    let actions: [String]
    let personalisedTips: [String]
    let snapshotChips: [String]
    let avoid: [String]
    let scanId: String?
    let source: String
    let fingerprint: String

    var displaySectionKeyFallback: GlowupSectionKey {
        GlowupSectionKey.allCases.first { title.lowercased().contains($0.rawValue) } ?? .general
    }
}

struct GlowupRoutinePresentation: Identifiable, Hashable {
    let id: String
    let scanResult: PersistedScanRecord?

    init(scanResult: PersistedScanRecord?) {
        self.scanResult = scanResult
        guard let scanResult else {
            self.id = "saved-glowup-routine"
            return
        }

        let trimmedScanID = scanResult.meta.scanId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.id = trimmedScanID.isEmpty ? scanResult.saveFingerprint : trimmedScanID
    }

    static let saved = GlowupRoutinePresentation(scanResult: nil)
}

extension GlowupRoutinePresentation {
    init(scanResult: PersistedScanRecord) {
        self.init(scanResult: Optional(scanResult))
    }
}
