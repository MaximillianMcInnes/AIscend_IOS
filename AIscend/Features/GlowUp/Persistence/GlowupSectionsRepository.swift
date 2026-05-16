//
//  GlowupSectionsRepository.swift
//  AIscend
//

import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

protocol GlowupSectionsWriting {
    func loadGlowupSections(uid: String?) async throws -> [GlowupSectionKey: GlowupSectionPayload]
    func overwriteGlowupSection(uid: String, sectionKey: GlowupSectionKey, payload: GlowupSectionPayload) async throws
    func overwriteGlowupSections(uid: String, sections: [GlowupSectionKey: GlowupSectionPayload]) async throws
}

actor GlowupSectionsRepository: GlowupSectionsWriting {
    #if canImport(FirebaseFirestore)
    private let firestore: Firestore

    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }
    #else
    init() {}
    #endif

    func loadGlowupSections(uid: String?) async throws -> [GlowupSectionKey: GlowupSectionPayload] {
        guard let resolvedUID = try resolvedAuthenticatedUID(requestedUID: uid) else {
            return [:]
        }

        #if canImport(FirebaseFirestore)
        let reference = firestore.collection("Users").document(resolvedUID)
        let snapshot = try await getDocument(reference)
        guard let data = snapshot.data(),
              let rawGlowupJson = data["glowupJson"] as? [String: Any]
        else {
            return [:]
        }

        return parseGlowupJson(rawGlowupJson)
        #else
        return [:]
        #endif
    }

    func overwriteGlowupSection(uid: String, sectionKey: GlowupSectionKey, payload: GlowupSectionPayload) async throws {
        guard let resolvedUID = try resolvedAuthenticatedUID(requestedUID: uid) else {
            return
        }

        let sectionPayload = firestorePayload(for: payload)

        #if canImport(FirebaseFirestore)
        let reference = firestore.collection("Users").document(resolvedUID)
        try await setData(
            [
                "glowupJson": [
                    sectionKey.rawValue: sectionPayload
                ],
                "updatedAt": FieldValue.serverTimestamp()
            ],
            on: reference,
            merge: true
        )
        #endif
    }

    func overwriteGlowupSections(uid: String, sections: [GlowupSectionKey: GlowupSectionPayload]) async throws {
        guard let resolvedUID = try resolvedAuthenticatedUID(requestedUID: uid), !sections.isEmpty else {
            return
        }

        let glowupJson = sections.reduce(into: [String: Any]()) { partialResult, element in
            partialResult[element.key.rawValue] = firestorePayload(for: element.value)
        }

        #if canImport(FirebaseFirestore)
        let reference = firestore.collection("Users").document(resolvedUID)
        try await setData(
            [
                "glowupJson": glowupJson,
                "updatedAt": FieldValue.serverTimestamp()
            ],
            on: reference,
            merge: true
        )
        #endif
    }

    private func firestorePayload(for payload: GlowupSectionPayload) -> [String: Any] {
        var data: [String: Any] = [
            "title": sanitizedString(payload.title, fallback: "Glow-Up section"),
            "goal": sanitizedString(payload.goal, fallback: payload.summary),
            "summary": sanitizedString(payload.summary, fallback: "Generated from scan results."),
            "goals": sanitizedGoalSubSections(payload.goals),
            "observedSignals": sanitizedStringArray(payload.observedSignals),
            "actions": sanitizedStringArray(payload.actions),
            "personalisedTips": sanitizedStringArray(payload.personalisedTips),
            "snapshotChips": sanitizedStringArray(payload.snapshotChips),
            "avoid": sanitizedStringArray(payload.avoid),
            "source": payload.source == "scan_results" ? payload.source : "scan_results",
            "fingerprint": sanitizedString(payload.fingerprint, fallback: "unknown"),
            "generatedAt": serverTimestampValue(),
            "updatedAt": serverTimestampValue()
        ]

        if let scanId = payload.scanId?.trimmingCharacters(in: .whitespacesAndNewlines), !scanId.isEmpty {
            data["scanId"] = scanId
        }

        return data
    }

    private func parseGlowupJson(_ glowupJson: [String: Any]) -> [GlowupSectionKey: GlowupSectionPayload] {
        glowupJson.reduce(into: [GlowupSectionKey: GlowupSectionPayload]()) { partialResult, element in
            guard
                let sectionKey = GlowupSectionKey(rawValue: element.key),
                let rawPayload = element.value as? [String: Any]
            else {
                return
            }

            let title = stringValue(for: ["title"], in: rawPayload) ?? defaultTitle(for: sectionKey)
            let summary = stringValue(for: ["summary", "detail", "description"], in: rawPayload)
                ?? "Generated from your saved scan routine."
            let goal = stringValue(for: ["goal"], in: rawPayload) ?? summary
            let goals = goalSubSectionsValue(for: ["goals"], in: rawPayload)
            let actions = stringArrayValue(for: ["actions", "steps", "dos"], in: rawPayload)
            let observedSignals = stringArrayValue(for: ["observedSignals", "signals", "scanSignals"], in: rawPayload)
            let personalisedTips = stringArrayValue(for: ["personalisedTips", "personalizedTips", "tips"], in: rawPayload)
            let snapshotChips = stringArrayValue(for: ["snapshotChips", "chips", "snapshot"], in: rawPayload)
            let avoid = stringArrayValue(for: ["avoid", "donts", "warnings"], in: rawPayload)
            let scanId = stringValue(for: ["scanId"], in: rawPayload)
            let source = stringValue(for: ["source"], in: rawPayload) ?? "scan_results"
            let fingerprint = stringValue(for: ["fingerprint"], in: rawPayload) ?? scanId ?? sectionKey.rawValue

            partialResult[sectionKey] = GlowupSectionPayload(
                title: title,
                goal: goal,
                summary: summary,
                goals: goals,
                observedSignals: observedSignals,
                actions: actions,
                personalisedTips: personalisedTips,
                snapshotChips: snapshotChips,
                avoid: avoid,
                scanId: scanId,
                source: source,
                fingerprint: fingerprint
            )
        }
    }

    private func stringValue(for keys: [String], in data: [String: Any]) -> String? {
        for key in keys {
            if let raw = data[key] as? String {
                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return String(trimmed.prefix(600))
                }
            }
        }

        return nil
    }

    private func stringArrayValue(for keys: [String], in data: [String: Any]) -> [String] {
        for key in keys {
            if let values = data[key] as? [String] {
                return sanitizedStringArray(values)
            }

            if let values = data[key] as? [Any] {
                return sanitizedStringArray(values.compactMap { value in
                    if let string = value as? String {
                        return string
                    }

                    if let object = value as? [String: Any] {
                        return stringValue(for: ["title", "label", "value", "text"], in: object)
                    }

                    return nil
                })
            }

            if let object = data[key] as? [String: Any] {
                let chips = object
                    .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
                    .compactMap { key, value -> String? in
                        if let string = value as? String {
                            return "\(PersistedScanRecord.normalizedLabel(for: key)): \(string)"
                        }

                        if let bool = value as? Bool {
                            return "\(PersistedScanRecord.normalizedLabel(for: key)): \(bool ? "Yes" : "No")"
                        }

                        if let number = value as? NSNumber {
                            return "\(PersistedScanRecord.normalizedLabel(for: key)): \(number)"
                        }

                        return nil
                    }

                if !chips.isEmpty {
                    return sanitizedStringArray(chips)
                }
            }
        }

        return []
    }

    private func goalSubSectionsValue(for keys: [String], in data: [String: Any]) -> [GlowupGoalSubSection] {
        for key in keys {
            guard let rawGoals = data[key] as? [Any] else {
                continue
            }

            let goals = rawGoals.compactMap { rawGoal -> GlowupGoalSubSection? in
                guard let object = rawGoal as? [String: Any] else {
                    return nil
                }

                let title = stringValue(for: ["title", "label"], in: object) ?? "Routine goal"
                let goal = stringValue(for: ["goal", "summary", "description"], in: object) ?? title
                let actions = stringArrayValue(for: ["actions", "steps", "dos"], in: object)
                let personalisedTips = stringArrayValue(
                    for: ["personalisedTips", "personalizedTips", "tips"],
                    in: object
                )

                guard !actions.isEmpty || !personalisedTips.isEmpty else {
                    return nil
                }

                return GlowupGoalSubSection(
                    title: title,
                    goal: goal,
                    actions: actions,
                    personalisedTips: personalisedTips
                )
            }

            if !goals.isEmpty {
                return Array(goals.prefix(8))
            }
        }

        return []
    }

    private func defaultTitle(for sectionKey: GlowupSectionKey) -> String {
        switch sectionKey {
        case .haircut:
            "Haircut & Harmony"
        case .eyebrow:
            "Eyebrows & Eye Area"
        case .jaw:
            "Jaw & Cheek Area"
        case .lip:
            "Lips"
        case .side:
            "Side Profile"
        case .skin:
            "Skin"
        case .general:
            "General"
        }
    }

    private func sanitizedString(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : String(trimmed.prefix(600))
    }

    private func sanitizedStringArray(_ values: [String]) -> [String] {
        var seen = Set<String>()

        return values.compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return nil
            }

            let normalized = String(trimmed.prefix(360))
            guard seen.insert(normalized.lowercased()).inserted else {
                return nil
            }

            return normalized
        }
        .prefix(12)
        .map { $0 }
    }

    private func sanitizedGoalSubSections(_ goals: [GlowupGoalSubSection]) -> [[String: Any]] {
        goals.compactMap { goal in
            let actions = sanitizedStringArray(goal.actions)
            let personalisedTips = sanitizedStringArray(goal.personalisedTips)
            guard !actions.isEmpty || !personalisedTips.isEmpty else {
                return nil
            }

            return [
                "title": sanitizedString(goal.title, fallback: "Routine goal"),
                "goal": sanitizedString(goal.goal, fallback: goal.title),
                "actions": actions,
                "personalisedTips": personalisedTips
            ]
        }
        .prefix(8)
        .map { $0 }
    }

    private func serverTimestampValue() -> Any {
        #if canImport(FirebaseFirestore)
        return FieldValue.serverTimestamp()
        #else
        return Date()
        #endif
    }

    private func resolvedAuthenticatedUID(requestedUID: String?) throws -> String? {
        let normalizedRequest = requestedUID?.trimmingCharacters(in: .whitespacesAndNewlines)

        #if canImport(FirebaseAuth)
        let authUID = Auth.auth().currentUser?.uid.trimmingCharacters(in: .whitespacesAndNewlines)
        if let authUID, !authUID.isEmpty {
            if let normalizedRequest, !normalizedRequest.isEmpty, normalizedRequest != authUID {
                throw GlowupSectionsRepositoryError.uidMismatch
            }

            return authUID
        }
        #endif

        guard let normalizedRequest, !normalizedRequest.isEmpty else {
            return nil
        }

        return normalizedRequest
    }

    #if canImport(FirebaseFirestore)
    private func getDocument(_ reference: DocumentReference) async throws -> DocumentSnapshot {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DocumentSnapshot, Error>) in
            reference.getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: GlowupSectionsRepositoryError.missingSnapshot)
                }
            }
        }
    }

    private func setData(_ data: [String: Any], on reference: DocumentReference, merge: Bool) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.setData(data, merge: merge) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    #endif
}

enum GlowupSectionsRepositoryError: Error {
    case uidMismatch
    case missingSnapshot
}
