//
//  AIscendPreviousScansView.swift
//  AIscend
//

import SwiftUI

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct AIscendPreviousScansView: View {
    let session: AuthSessionStore
    var embedded: Bool = false
    var onOpenScanRecord: (PersistedScanRecord) -> Void = { _ in }

    @StateObject private var viewModel: ScanArchiveViewModel
    @State private var sortMode: ScanArchiveSortMode = .newest
    @State private var visibleItemLimit = Self.pageSize

    private static let pageSize = 5

    init(
        session: AuthSessionStore,
        embedded: Bool = false,
        previewItems: [ScanArchiveItem]? = nil,
        repository: ScanResultsRepositoryProtocol = ScanResultsRepository(),
        onOpenScanRecord: @escaping (PersistedScanRecord) -> Void = { _ in }
    ) {
        self.session = session
        self.embedded = embedded
        self.onOpenScanRecord = onOpenScanRecord
        _viewModel = StateObject(
            wrappedValue: ScanArchiveViewModel(
                previewItems: previewItems,
                repository: repository
            )
        )
    }

    private var sortedItems: [ScanArchiveItem] {
        sortMode.sorted(viewModel.items)
    }

    private var visibleItems: [ScanArchiveItem] {
        Array(sortedItems.prefix(visibleItemLimit))
    }

    private var bestScanID: String? {
        sortedItems.max { lhs, rhs in
            if lhs.record.overallScore == rhs.record.overallScore {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.record.overallScore < rhs.record.overallScore
        }?.id
    }

    private var latestScanID: String? {
        sortedItems.max(by: { $0.createdAt < $1.createdAt })?.id
    }

    private var bestScore: Int {
        Int((viewModel.items.map(\.record.overallScore).max() ?? 0).rounded())
    }

    private var latestScore: Int {
        Int((viewModel.items.max(by: { $0.createdAt < $1.createdAt })?.record.overallScore ?? 0).rounded())
    }

    var body: some View {
        PreviousScansView(
            embedded: embedded,
            items: viewModel.items,
            visibleItems: visibleItems,
            isLoading: viewModel.isLoading,
            errorMessage: viewModel.errorMessage,
            sortMode: $sortMode,
            bestScanID: bestScanID,
            latestScanID: latestScanID,
            bestScore: bestScore,
            latestScore: latestScore,
            onOpenScanRecord: onOpenScanRecord,
            onLoadMore: loadMoreIfNeeded(currentItem:)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("previous-scans-root")
        .task(id: session.user?.id) {
            await viewModel.loadArchive(for: session.user)
            resetVisibleItems()
        }
        .refreshable {
            await viewModel.loadArchive(for: session.user, force: true)
            resetVisibleItems()
        }
        .onChange(of: sortMode) { _, _ in
            resetVisibleItems()
        }
        .onChange(of: viewModel.items.count) { _, _ in
            resetVisibleItems()
        }
    }

    private func resetVisibleItems() {
        visibleItemLimit = min(Self.pageSize, sortedItems.count)
    }

    private func loadMoreIfNeeded(currentItem: ScanArchiveItem) {
        guard currentItem.id == visibleItems.last?.id,
              visibleItemLimit < sortedItems.count
        else {
            return
        }

        visibleItemLimit = min(visibleItemLimit + Self.pageSize, sortedItems.count)
    }

}

enum ScanArchiveSortMode: String, CaseIterable, Identifiable {
    case newest
    case oldest
    case best

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newest:
            "Newest"
        case .oldest:
            "Oldest"
        case .best:
            "Best"
        }
    }

    var symbol: String {
        switch self {
        case .newest:
            "arrow.down.circle.fill"
        case .oldest:
            "arrow.up.circle.fill"
        case .best:
            "trophy.fill"
        }
    }

    var selectedFill: Color {
        switch self {
        case .best:
            AIscendTheme.Colors.accentAmber
        case .newest, .oldest:
            Color.white
        }
    }

    func sorted(_ items: [ScanArchiveItem]) -> [ScanArchiveItem] {
        switch self {
        case .newest:
            return items.sorted { lhs, rhs in
                lhs.createdAt > rhs.createdAt
            }
        case .oldest:
            return items.sorted { lhs, rhs in
                lhs.createdAt < rhs.createdAt
            }
        case .best:
            return items.sorted { lhs, rhs in
                if lhs.record.overallScore == rhs.record.overallScore {
                    return lhs.createdAt > rhs.createdAt
                }
                return lhs.record.overallScore > rhs.record.overallScore
            }
        }
    }
}

struct ScanArchiveItem: Identifiable, Hashable {
    let id: String
    let createdAt: Date
    let record: PersistedScanRecord

    var accessLabel: String {
        switch record.accessLevel {
        case .free:
            "Free"
        case .premium:
            "Premium"
        }
    }
}

@MainActor
final class ScanArchiveViewModel: ObservableObject {
    @Published private(set) var items: [ScanArchiveItem]
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let previewItems: [ScanArchiveItem]?
    private let repository: ScanResultsRepositoryProtocol

    #if canImport(FirebaseFirestore)
    private let firestore: Firestore
    #endif

    init(
        previewItems: [ScanArchiveItem]? = nil,
        repository: ScanResultsRepositoryProtocol = ScanResultsRepository()
    ) {
        self.previewItems = previewItems
        self.repository = repository
        self.items = previewItems ?? []

        #if canImport(FirebaseFirestore)
        self.firestore = Firestore.firestore()
        #endif
    }

    func loadArchive(for user: SessionUser?, force: Bool = false) async {
        if let previewItems {
            items = previewItems
            errorMessage = nil
            isLoading = false
            return
        }

        guard let user else {
            items = await loadLocalArchiveItems()
            errorMessage = nil
            isLoading = false
            return
        }

        if isLoading && !force {
            return
        }

        isLoading = true
        let localItems = await loadLocalArchiveItems()
        defer { isLoading = false }

        do {
            let remoteItems = try await fetchArchive(for: user)
            items = mergeArchiveItems(localItems, remoteItems)
            errorMessage = nil
        } catch {
            items = localItems
            errorMessage = localItems.isEmpty ? userFacingMessage(for: error) : nil
        }
    }

    private func loadLocalArchiveItems() async -> [ScanArchiveItem] {
        let localArchive = await repository.loadPersistedArchive()

        return localArchive
            .filter(\.isDisplayable)
            .map { record in
                ScanArchiveItem(
                    id: archiveIdentifier(for: record),
                    createdAt: record.savedAt ?? .distantPast,
                    record: record
                )
            }
            .sorted(by: archiveSort)
    }

    private func mergeArchiveItems(
        _ localItems: [ScanArchiveItem],
        _ remoteItems: [ScanArchiveItem]
    ) -> [ScanArchiveItem] {
        var mergedItems: [ScanArchiveItem] = []

        for item in localItems + remoteItems {
            if let existingIndex = mergedItems.firstIndex(where: { archiveMatches($0, item) }) {
                mergedItems[existingIndex] = mergeArchiveItem(mergedItems[existingIndex], with: item)
            } else {
                mergedItems.append(item)
            }
        }

        return mergedItems.sorted(by: archiveSort)
    }

    private func archiveMatches(_ lhs: ScanArchiveItem, _ rhs: ScanArchiveItem) -> Bool {
        if let lhsScanID = lhs.record.meta.scanId?.trimmedNonEmpty,
           let rhsScanID = rhs.record.meta.scanId?.trimmedNonEmpty,
           lhsScanID == rhsScanID
        {
            return true
        }

        return lhs.record.archiveFingerprint == rhs.record.archiveFingerprint
    }

    private func mergeArchiveItem(
        _ existing: ScanArchiveItem,
        with incoming: ScanArchiveItem
    ) -> ScanArchiveItem {
        let existingDate = existing.record.savedAt ?? existing.createdAt
        let incomingDate = incoming.record.savedAt ?? incoming.createdAt

        let primary = incomingDate >= existingDate ? incoming : existing
        let fallback = incomingDate >= existingDate ? existing : incoming
        var mergedRecord = primary.record

        if mergedRecord.meta.frontUrl?.trimmedNonEmpty == nil {
            mergedRecord.meta.frontUrl = fallback.record.meta.frontUrl
        }

        if mergedRecord.meta.sideUrl?.trimmedNonEmpty == nil {
            mergedRecord.meta.sideUrl = fallback.record.meta.sideUrl
        }

        if mergedRecord.meta.email?.trimmedNonEmpty == nil {
            mergedRecord.meta.email = fallback.record.meta.email
        }

        if mergedRecord.meta.type?.trimmedNonEmpty == nil {
            mergedRecord.meta.type = fallback.record.meta.type
        }

        if mergedRecord.meta.scanId?.trimmedNonEmpty == nil {
            mergedRecord.meta.scanId = fallback.record.meta.scanId
        }

        if mergedRecord.meta.source?.trimmedNonEmpty == nil {
            mergedRecord.meta.source = fallback.record.meta.source
        }

        if mergedRecord.savedAt == nil {
            mergedRecord.savedAt = fallback.record.savedAt ?? fallback.createdAt
        }

        let createdAt = mergedRecord.savedAt ?? max(existing.createdAt, incoming.createdAt)
        return ScanArchiveItem(
            id: archiveIdentifier(for: mergedRecord),
            createdAt: createdAt,
            record: mergedRecord
        )
    }

    private func archiveIdentifier(for record: PersistedScanRecord) -> String {
        if let scanID = record.meta.scanId?.trimmedNonEmpty {
            return scanID
        }

        return record.archiveFingerprint
    }

    private func archiveSort(_ lhs: ScanArchiveItem, _ rhs: ScanArchiveItem) -> Bool {
        lhs.createdAt > rhs.createdAt
    }

    #if canImport(FirebaseFirestore)
    private func fetchArchive(for user: SessionUser) async throws -> [ScanArchiveItem] {
        var documentsByID: [String: QueryDocumentSnapshot] = [:]

        let uidSnapshot = try await firestore
            .collection("Scans")
            .whereField("ownerUid", isEqualTo: user.id)
            .getDocuments()

        for document in uidSnapshot.documents {
            documentsByID[document.documentID] = document
        }

        if let email = user.email?.trimmedNonEmpty?.lowercased() {
            let emailSnapshot = try await firestore
                .collection("Scans")
                .whereField("email", isEqualTo: email)
                .getDocuments()

            for document in emailSnapshot.documents {
                documentsByID[document.documentID] = document
            }
        }

        return documentsByID.values
            .compactMap(ScanArchiveRecordBuilder.item(from:))
            .sorted(by: { lhs, rhs in
                lhs.createdAt > rhs.createdAt
            })
    }
    #endif

    private func userFacingMessage(for error: Error) -> String {
        #if canImport(FirebaseFirestore)
        let nsError = error as NSError
        if FirestoreErrorCode.Code(rawValue: nsError.code) == .permissionDenied {
            return "AIScend could not read your archive with the current Firestore permissions."
        }
        #endif

        let message = (error as NSError).localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return message.isEmpty ? "AIScend could not load your saved scans right now." : message
    }
}

#if canImport(FirebaseFirestore)
private enum ScanArchiveRecordBuilder {
    static func item(from document: QueryDocumentSnapshot) -> ScanArchiveItem? {
        let object = document.data()
        let createdAt = resolveDate(
            from: object["createdAt"]
                ?? object["savedAt"]
                ?? object["updatedAt"]
        ) ?? .distantPast

        let baseMeta = ScanResultMeta(
            frontUrl: stringValue(for: ["frontUrl", "frontURL", "frontImageUrl", "front_image_url"], in: object),
            sideUrl: stringValue(for: ["sideUrl", "sideURL", "sideImageUrl", "side_image_url"], in: object),
            email: stringValue(for: ["email", "Email"], in: object),
            type: stringValue(for: ["type", "scanType", "Scantype", "access"], in: object),
            scanId: document.documentID,
            source: stringValue(for: ["source", "origin"], in: object) ?? "history"
        )

        let resolvedRecord = decodeRecord(from: object, createdAt: createdAt, baseMeta: baseMeta)
            ?? fallbackRecord(from: object, createdAt: createdAt, baseMeta: baseMeta)

        guard let resolvedRecord else {
            return nil
        }

        return ScanArchiveItem(
            id: document.documentID,
            createdAt: resolvedRecord.savedAt ?? createdAt,
            record: resolvedRecord
        )
    }

    private static func decodeRecord(
        from object: [String: Any],
        createdAt: Date,
        baseMeta: ScanResultMeta
    ) -> PersistedScanRecord? {
        let candidates: [Any?] = [
            object["payloadJSON"],
            object["jsonData"],
            object["scanResult"],
            object["scan_result"],
            object["result"],
            object
        ]

        for candidate in candidates {
            if let record = try? decodeRecordCandidate(candidate, rootObject: object) {
                return normalized(record, baseMeta: baseMeta, createdAt: createdAt)
            }
        }

        return nil
    }

    private static func fallbackRecord(
        from object: [String: Any],
        createdAt: Date,
        baseMeta: ScanResultMeta
    ) -> PersistedScanRecord? {
        let overall = numberValue(for: ["overallScore", "overall", "score"], in: object)

        guard overall != nil || baseMeta.frontUrl != nil || baseMeta.sideUrl != nil else {
            return nil
        }

        let payload = ScanPayload(
            scores: ScanScores(overall: overall)
        )
        let record = PersistedScanRecord(
            payload: payload,
            meta: baseMeta,
            savedAt: createdAt
        )
        return normalized(record, baseMeta: baseMeta, createdAt: createdAt)
    }

    private static func normalized(
        _ record: PersistedScanRecord,
        baseMeta: ScanResultMeta,
        createdAt: Date
    ) -> PersistedScanRecord {
        var normalized = record

        if normalized.meta.frontUrl?.trimmedNonEmpty == nil {
            normalized.meta.frontUrl = baseMeta.frontUrl
        }

        if normalized.meta.sideUrl?.trimmedNonEmpty == nil {
            normalized.meta.sideUrl = baseMeta.sideUrl
        }

        if normalized.meta.email?.trimmedNonEmpty == nil {
            normalized.meta.email = baseMeta.email
        }

        if normalized.meta.type?.trimmedNonEmpty == nil {
            normalized.meta.type = baseMeta.type
        }

        if normalized.meta.scanId?.trimmedNonEmpty == nil {
            normalized.meta.scanId = baseMeta.scanId
        }

        if normalized.meta.source?.trimmedNonEmpty == nil {
            normalized.meta.source = baseMeta.source
        }

        if normalized.savedAt == nil {
            normalized.savedAt = createdAt
        }

        return normalized
    }

    private static func decodeRecordCandidate(
        _ raw: Any?,
        rootObject: [String: Any]
    ) throws -> PersistedScanRecord? {
        guard let raw else {
            return nil
        }

        let decoder = configuredDecoder

        if let dictionary = raw as? [String: Any] {
            if let directData = try? jsonData(from: dictionary),
               let directRecord = try? decoder.decode(PersistedScanRecord.self, from: directData),
               directRecord.isDisplayable
            {
                return directRecord
            }

            let payload = try decodePayload(
                from: dictionary["payload"]
                    ?? dictionary["scanPayload"]
                    ?? dictionary["payloadJSON"]
                    ?? dictionary["jsonData"]
                    ?? dictionary["scan_payload"]
                    ?? dictionary
            )

            guard let payload else {
                return nil
            }

            let meta = try decodeMeta(
                from: dictionary["meta"]
                    ?? dictionary["metadata"]
                    ?? dictionary["scanMeta"]
                    ?? dictionary["scan_meta"]
                    ?? dictionary
            ) ?? ScanResultMeta()

            let savedAt = resolveDate(
                from: dictionary["savedAt"]
                    ?? dictionary["createdAt"]
                    ?? dictionary["updatedAt"]
            ) ?? resolveDate(
                from: rootObject["savedAt"]
                    ?? rootObject["createdAt"]
                    ?? rootObject["updatedAt"]
            )

            return PersistedScanRecord(
                payload: payload,
                meta: meta,
                savedAt: savedAt
            )
        }

        if let jsonString = raw as? String,
           let data = jsonString.data(using: .utf8)
        {
            if let directRecord = try? decoder.decode(PersistedScanRecord.self, from: data),
               directRecord.isDisplayable
            {
                return directRecord
            }

            if let payload = try? decoder.decode(ScanPayload.self, from: data) {
                return PersistedScanRecord(
                    payload: payload,
                    meta: ScanResultMeta(),
                    savedAt: nil
                )
            }
        }

        return nil
    }

    private static func decodePayload(from raw: Any?) throws -> ScanPayload? {
        guard let raw else {
            return nil
        }

        if let dictionary = raw as? [String: Any] {
            let data = try jsonData(from: dictionary)
            return try? configuredDecoder.decode(ScanPayload.self, from: data)
        }

        if let jsonString = raw as? String,
           let data = jsonString.data(using: .utf8)
        {
            return try? configuredDecoder.decode(ScanPayload.self, from: data)
        }

        return nil
    }

    private static func decodeMeta(from raw: Any?) throws -> ScanResultMeta? {
        guard let raw else {
            return nil
        }

        if let dictionary = raw as? [String: Any] {
            let data = try jsonData(from: dictionary)
            return try? configuredDecoder.decode(ScanResultMeta.self, from: data)
        }

        if let jsonString = raw as? String,
           let data = jsonString.data(using: .utf8)
        {
            return try? configuredDecoder.decode(ScanResultMeta.self, from: data)
        }

        return nil
    }

    private static func jsonData(from value: Any) throws -> Data {
        guard JSONSerialization.isValidJSONObject(value) else {
            throw ArchiveDecodingError.invalidJSONObject
        }

        return try JSONSerialization.data(withJSONObject: value, options: [])
    }

    private static func resolveDate(from raw: Any?) -> Date? {
        guard let raw else {
            return nil
        }

        if let timestamp = raw as? Timestamp {
            return timestamp.dateValue()
        }

        if let date = raw as? Date {
            return date
        }

        if let string = raw as? String {
            if let date = ISO8601DateFormatter().date(from: string) {
                return date
            }

            if let interval = Double(string) {
                return dateFromTimeInterval(interval)
            }
        }

        if let number = raw as? NSNumber {
            return dateFromTimeInterval(number.doubleValue)
        }

        if let dictionary = raw as? [String: Any] {
            if let seconds = (dictionary["_seconds"] as? NSNumber)?.doubleValue {
                return Date(timeIntervalSince1970: seconds)
            }

            if let seconds = (dictionary["seconds"] as? NSNumber)?.doubleValue {
                return Date(timeIntervalSince1970: seconds)
            }
        }

        return nil
    }

    private static func dateFromTimeInterval(_ rawValue: Double) -> Date {
        let normalizedValue = rawValue > 10_000_000_000 ? rawValue / 1000 : rawValue
        return Date(timeIntervalSince1970: normalizedValue)
    }

    private static func stringValue(for keys: [String], in object: [String: Any]) -> String? {
        for key in keys {
            if let value = object[key] as? String,
               let trimmed = value.trimmedNonEmpty
            {
                return trimmed
            }
        }

        return nil
    }

    private static func numberValue(for keys: [String], in object: [String: Any]) -> Double? {
        for key in keys {
            guard let value = object[key] else {
                continue
            }

            if let number = value as? NSNumber {
                return number.doubleValue
            }

            if let string = value as? String,
               let number = Double(string)
            {
                return number
            }
        }

        return nil
    }

    private static var configuredDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private enum ArchiveDecodingError: Error {
        case invalidJSONObject
    }
}
#endif

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview {
    NavigationStack {
        AIscendPreviousScansView(
            session: AuthSessionStore(),
            previewItems: [
                ScanArchiveItem(
                    id: "preview-1",
                    createdAt: .now,
                    record: .previewPremium
                ),
                ScanArchiveItem(
                    id: "preview-2",
                    createdAt: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now,
                    record: .previewFree
                )
            ]
        )
        .padding(.horizontal, AIscendTheme.Spacing.screenInset)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }
}
