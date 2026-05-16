//
//  GlowupRoutineGenerationStore.swift
//  AIscend
//

import SwiftUI

@MainActor
final class GlowupRoutineGenerationStore: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(String)
    }

    enum SaveState: Equatable {
        case idle
        case saving
        case saved
        case skipped
        case localOnly
        case failed(String)

        var title: String {
            switch self {
            case .idle:
                "Preparing routine sections"
            case .saving:
                "Saving Glow-Up sections"
            case .saved:
                "Glow-Up routine saved"
            case .skipped:
                "Routine already saved for this scan"
            case .localOnly:
                "Routine generated locally"
            case .failed(let message):
                message
            }
        }

        var symbol: String {
            switch self {
            case .idle, .saving:
                "arrow.triangle.2.circlepath"
            case .saved:
                "checkmark.seal.fill"
            case .skipped:
                "checkmark.circle.fill"
            case .localOnly:
                "iphone"
            case .failed:
                "exclamationmark.triangle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .saved, .skipped:
                AIscendTheme.Colors.accentCyan
            case .localOnly:
                AIscendTheme.Colors.accentGlow
            case .failed:
                AIscendTheme.Colors.accentAmber
            case .idle, .saving:
                AIscendTheme.Colors.textSecondary
            }
        }
    }

    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var state: SaveState = .idle
    @Published private(set) var sections: [GlowupRoutineSection] = []
    @Published private(set) var headline = "Your Glow-Up routine"
    @Published private(set) var detail = "Routine sections are loaded from your saved scan plan."

    private let repository: GlowupSectionsWriting
    private let saveCoordinator: GlowupRoutineSaveCoordinator

    init(
        repository: GlowupSectionsWriting = GlowupSectionsRepository(),
        saveCoordinator: GlowupRoutineSaveCoordinator = .shared
    ) {
        self.repository = repository
        self.saveCoordinator = saveCoordinator
    }

    func load(freshScanResult: PersistedScanRecord?, uid: String?) async {
        loadState = .loading

        if let freshScanResult {
            let input = buildGlowupInputFromScanResult(scanResult: freshScanResult)
            sections = input.sections
            headline = "Your Glow-Up routine"
            detail = "\(input.generatedFromSummary) Every section is generated from the scan that just completed."
            loadState = .loaded
            await saveIfNeeded(input: input, uid: uid)
            return
        }

        do {
            let payloads = try await repository.loadGlowupSections(uid: uid)
            let loadedSections = Self.sections(from: payloads)

            guard !loadedSections.isEmpty else {
                sections = []
                state = .idle
                loadState = .empty
                return
            }

            sections = loadedSections
            headline = "Your saved Glow-Up routine"
            detail = "Loaded from your saved Firestore routine. New scans update this plan with fresh scan signals."
            state = .saved
            loadState = .loaded
        } catch {
            sections = []
            state = .failed("Routine could not load right now.")
            loadState = .error("AIScend could not load your saved Glow-Up routine. Please try again.")
        }
    }

    func saveIfNeeded(input: GlowupRoutineInput, uid: String?) async {
        guard let uid = uid?.trimmingCharacters(in: .whitespacesAndNewlines), !uid.isEmpty else {
            state = .localOnly
            return
        }

        let saveKey = "\(uid)|\(input.fingerprint)"
        guard await saveCoordinator.reserve(saveKey) else {
            state = .skipped
            return
        }

        state = .saving

        do {
            try await repository.overwriteGlowupSections(
                uid: uid,
                sections: input.firestoreSections
            )
            await saveCoordinator.markCompleted(saveKey)
            state = .saved
        } catch {
            await saveCoordinator.release(saveKey)
            state = .failed("Generated locally, but Firestore save could not finish.")
        }
    }

    private static func sections(from payloads: [GlowupSectionKey: GlowupSectionPayload]) -> [GlowupRoutineSection] {
        GlowupSectionKey.allCases.compactMap { key in
            guard let payload = payloads[key] else {
                return nil
            }

            return GlowupRoutineSection(
                key: key,
                title: payload.title,
                goal: payload.goal,
                summary: payload.summary,
                goals: payload.goals,
                observedSignals: payload.observedSignals.enumerated().map { index, signal in
                    let parts = signal.components(separatedBy: ":")
                    let label = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespacesAndNewlines)

                    return GlowupScanSignal(
                        id: "\(key.rawValue)-signal-\(index)",
                        label: label?.isEmpty == false ? label! : "Scan signal",
                        value: value.isEmpty ? signal : value,
                        detail: nil
                    )
                },
                actions: payload.actions.isEmpty ? payload.goals.flatMap(\.actions) : payload.actions,
                personalisedTips: payload.personalisedTips.isEmpty
                    ? payload.goals.flatMap(\.personalisedTips)
                    : payload.personalisedTips,
                snapshotChips: payload.snapshotChips,
                avoid: payload.avoid,
                symbol: symbol(for: key),
                accent: accent(for: key)
            )
        }
    }

    private static func symbol(for key: GlowupSectionKey) -> String {
        switch key {
        case .haircut:
            "scissors"
        case .eyebrow:
            "eye.fill"
        case .jaw:
            "triangle.bottomhalf.filled"
        case .lip:
            "mouth.fill"
        case .side:
            "person.crop.rectangle.stack.fill"
        case .skin:
            "drop.fill"
        case .general:
            "sparkles.rectangle.stack.fill"
        }
    }

    private static func accent(for key: GlowupSectionKey) -> RoutineAccent {
        switch key {
        case .haircut, .lip:
            .sky
        case .eyebrow, .side, .skin:
            .mint
        case .jaw, .general:
            .dawn
        }
    }
}

actor GlowupRoutineSaveCoordinator {
    static let shared = GlowupRoutineSaveCoordinator()

    private var inFlight = Set<String>()
    private var completed = Set<String>()

    func reserve(_ key: String) -> Bool {
        guard !completed.contains(key), !inFlight.contains(key) else {
            return false
        }

        inFlight.insert(key)
        return true
    }

    func markCompleted(_ key: String) {
        inFlight.remove(key)
        completed.insert(key)
    }

    func release(_ key: String) {
        inFlight.remove(key)
    }
}
