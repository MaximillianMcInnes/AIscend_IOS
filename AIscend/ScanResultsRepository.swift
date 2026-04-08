//
//  ScanResultsRepository.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

protocol ScanResultsRepositoryProtocol: Sendable {
    func loadLatestPersistedResult() async -> PersistedScanRecord?
    func storeLatestPersistedResult(_ result: PersistedScanRecord?) async
    func autoSaveFreshResultIfNeeded(
        _ result: PersistedScanRecord,
        sessionUser: SessionUser?
    ) async -> ScanAutoSaveResult
}

actor ScanResultsRepository: ScanResultsRepositoryProtocol {
    private enum Keys {
        static let latestResult = "aiscend.latestScanResult"
        static let savedScanIDs = "aiscend.savedScanIDs"
    }

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var inFlightFingerprints: Set<String> = []

    #if canImport(FirebaseFirestore)
    private let firestore: Firestore
    #endif

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        #if canImport(FirebaseFirestore)
        self.firestore = Firestore.firestore()
        #endif
    }

    func loadLatestPersistedResult() async -> PersistedScanRecord? {
        guard let data = defaults.data(forKey: Keys.latestResult) else {
            return nil
        }

        return try? decoder.decode(PersistedScanRecord.self, from: data)
    }

    func storeLatestPersistedResult(_ result: PersistedScanRecord?) async {
        guard let result else {
            defaults.removeObject(forKey: Keys.latestResult)
            return
        }

        guard let encoded = try? encoder.encode(result) else {
            return
        }

        defaults.set(encoded, forKey: Keys.latestResult)
    }

    func autoSaveFreshResultIfNeeded(
        _ result: PersistedScanRecord,
        sessionUser: SessionUser?
    ) async -> ScanAutoSaveResult {
        await storeLatestPersistedResult(result)

        guard result.isFreshScanCandidate else {
            return ScanAutoSaveResult(result: result, state: .skipped)
        }

        let resolvedEmail = result.meta.email?.trimmedNonEmpty ?? sessionUser?.email?.trimmedNonEmpty
        let frontURL = result.meta.frontUrl?.trimmedNonEmpty
        let sideURL = result.meta.sideUrl?.trimmedNonEmpty
        let scanType = result.meta.type?.trimmedNonEmpty

        guard
            let resolvedEmail,
            let frontURL,
            let sideURL,
            let scanType,
            result.payload.scores.overall != nil
        else {
            return ScanAutoSaveResult(
                result: result,
                state: .failed("Scan sync skipped because the result payload was incomplete.")
            )
        }

        guard let sessionUser else {
            return ScanAutoSaveResult(result: result, state: .localOnly)
        }

        let fingerprint = result.saveFingerprint
        if let savedScanID = savedScanIDsByFingerprint()[fingerprint]?.trimmedNonEmpty {
            var restored = result
            restored.meta.scanId = savedScanID
            restored.savedAt = restored.savedAt ?? .now
            await storeLatestPersistedResult(restored)
            return ScanAutoSaveResult(result: restored, state: .saved(savedScanID))
        }

        guard !inFlightFingerprints.contains(fingerprint) else {
            return ScanAutoSaveResult(result: result, state: .skipped)
        }

        inFlightFingerprints.insert(fingerprint)
        defer {
            inFlightFingerprints.remove(fingerprint)
        }

        #if canImport(FirebaseFirestore)
        do {
            let savedResult = try await saveScan(
                result,
                sessionUser: sessionUser,
                resolvedEmail: resolvedEmail.lowercased(),
                frontURL: frontURL,
                sideURL: sideURL,
                scanType: scanType
            )
            if let savedScanID = savedResult.meta.scanId?.trimmedNonEmpty {
                storeSavedScanID(savedScanID, for: fingerprint)
            }
            await storeLatestPersistedResult(savedResult)
            return ScanAutoSaveResult(result: savedResult, state: .saved(savedResult.meta.scanId ?? ""))
        } catch {
            return ScanAutoSaveResult(
                result: result,
                state: .failed("Saved locally, but archive sync could not finish right now.")
            )
        }
        #else
        return ScanAutoSaveResult(result: result, state: .localOnly)
        #endif
    }

    private func savedScanIDsByFingerprint() -> [String: String] {
        defaults.dictionary(forKey: Keys.savedScanIDs) as? [String: String] ?? [:]
    }

    private func storeSavedScanID(_ scanID: String, for fingerprint: String) {
        var savedScanIDs = savedScanIDsByFingerprint()
        savedScanIDs[fingerprint] = scanID
        defaults.set(savedScanIDs, forKey: Keys.savedScanIDs)
    }
}

#if canImport(FirebaseFirestore)
private extension ScanResultsRepository {
    func saveScan(
        _ result: PersistedScanRecord,
        sessionUser: SessionUser,
        resolvedEmail: String,
        frontURL: String,
        sideURL: String,
        scanType: String
    ) async throws -> PersistedScanRecord {
        let reference = firestore.collection("Scans").document()
        let payloadJSON = try payloadJSONString(for: result.payload)

        var data: [String: Any] = [
            "ownerUid": sessionUser.id,
            "email": resolvedEmail,
            "frontImageUrl": frontURL,
            "sideImageUrl": sideURL,
            "type": scanType,
            "source": result.meta.source ?? "scan-flow",
            "overallScore": result.overallScore,
            "payloadJSON": payloadJSON,
            "createdAt": Timestamp(date: result.savedAt ?? .now),
            "updatedAt": Timestamp(date: .now)
        ]

        if let potential = result.payload.scores.potential {
            data["potentialScore"] = potential
        }

        if let eyes = result.payload.scores.eyes {
            data["eyesScore"] = eyes
        }

        if let jaw = result.payload.scores.jaw {
            data["jawScore"] = jaw
        }

        if let side = result.payload.scores.side {
            data["sideScore"] = side
        }

        try await setData(data, on: reference)

        var saved = result
        saved.meta.scanId = reference.documentID
        saved.savedAt = .now
        return saved
    }

    func payloadJSONString(for payload: ScanPayload) throws -> String {
        let data = try encoder.encode(payload)
        return String(decoding: data, as: UTF8.self)
    }

    func setData(_ data: [String: Any], on reference: DocumentReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.setData(data) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
#endif

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
