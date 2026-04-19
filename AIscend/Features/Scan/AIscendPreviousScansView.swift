//
//  AIscendPreviousScansView.swift
//  AIscend
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct AIscendPreviousScansView: View {
    let session: AuthSessionStore
    var onOpenScanRecord: (PersistedScanRecord) -> Void = { _ in }
    var onStartNewScan: () -> Void = {}

    @StateObject private var viewModel: ScanArchiveViewModel
    @State private var sortMode: ScanArchiveSortMode = .newest

    init(
        session: AuthSessionStore,
        previewItems: [ScanArchiveItem]? = nil,
        repository: ScanResultsRepositoryProtocol = ScanResultsRepository(),
        onOpenScanRecord: @escaping (PersistedScanRecord) -> Void = { _ in },
        onStartNewScan: @escaping () -> Void = {}
    ) {
        self.session = session
        self.onOpenScanRecord = onOpenScanRecord
        self.onStartNewScan = onStartNewScan
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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                archiveHero

                if let errorMessage = viewModel.errorMessage {
                    archiveError(message: errorMessage)
                }

                sortControl

                archiveContent
            }
            .padding(.bottom, AIscendTheme.Spacing.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("previous-scans-root")
        .task(id: session.user?.id) {
            await viewModel.loadArchive(for: session.user)
        }
        .refreshable {
            await viewModel.loadArchive(for: session.user, force: true)
        }
    }

    private var archiveHero: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    archiveBadge(
                        title: viewModel.items.isEmpty ? "Archive ready" : "Synced archive",
                        symbol: "clock.arrow.trianglehead.counterclockwise.rotate.90"
                    )

                    Text("Previous Scans")
                        .aiscendTextStyle(.sectionTitle)

                    Text("Track your progress over time, surface your strongest result fast, and reopen any saved scan in one tap.")
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                }

                HStack(spacing: AIscendTheme.Spacing.small) {
                    archiveStat(
                        title: "Saved",
                        value: "\(viewModel.items.count)"
                    )

                    archiveStat(
                        title: "Best",
                        value: bestScore == 0 ? "--" : "\(bestScore)"
                    )

                    archiveStat(
                        title: "Latest",
                        value: viewModel.items.isEmpty
                            ? "--"
                            : "\(latestScore)"
                    )
                }
            }
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(AIscendTheme.Colors.accentAmber.opacity(0.18))
                    .frame(width: 124, height: 124)
                    .blur(radius: 24)
                    .offset(x: 18, y: -18)
                    .allowsHitTesting(false)
            }
        }
    }

    private var sortControl: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text("Sort")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            HStack(spacing: 6) {
                ForEach(ScanArchiveSortMode.allCases) { mode in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                            sortMode = mode
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.symbol)
                                .font(.system(size: 11, weight: .semibold))

                            Text(mode.title)
                                .aiscendTextStyle(
                                    .caption,
                                    color: sortMode == mode ? Color.black : AIscendTheme.Colors.textSecondary
                                )
                        }
                        .foregroundStyle(sortMode == mode ? Color.black : AIscendTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule(style: .continuous)
                                .fill(sortMode == mode ? mode.selectedFill : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(
                Capsule(style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.62))
                    .allowsHitTesting(false)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                    .allowsHitTesting(false)
            )
        }
    }

    @ViewBuilder
    private var archiveContent: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            LazyVStack(spacing: AIscendTheme.Spacing.medium) {
                ForEach(0..<3, id: \.self) { _ in
                    ScanArchiveLoadingCard()
                }
            }
        } else if !viewModel.isLoading && viewModel.items.isEmpty {
            ScanArchiveEmptyState(onStartNewScan: onStartNewScan)
        } else {
            LazyVStack(spacing: AIscendTheme.Spacing.medium) {
                ForEach(sortedItems) { item in
                    ScanArchiveCard(
                        item: item,
                        isBest: item.id == bestScanID,
                        isLatest: item.id == latestScanID,
                        onOpen: {
                            onOpenScanRecord(item.record)
                        }
                    )
                }
            }
        }
    }

    private func archiveStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            Text(value)
                .aiscendTextStyle(.cardTitle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.54))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private func archiveBadge(title: String, symbol: String) -> some View {
        HStack(spacing: AIscendTheme.Spacing.xxSmall) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(AIscendTheme.Colors.accentGlow.opacity(0.16))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.accentGlow.opacity(0.32), lineWidth: 1)
        )
    }

    private func archiveError(message: String) -> some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 0.98, green: 0.75, blue: 0.45))

            Text(message)
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(Color(red: 0.42, green: 0.19, blue: 0.10).opacity(0.34))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(Color(red: 0.95, green: 0.62, blue: 0.32).opacity(0.28), lineWidth: 1)
        )
    }
}

private enum ScanArchiveSortMode: String, CaseIterable, Identifiable {
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
            "Best scans"
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

    var shareText: String {
        "AIScend read: \(record.tierTitle), top \(record.percentile)% placement, \(Int(record.overallScore.rounded()))/100 overall."
    }

    var accessLabel: String {
        switch record.accessLevel {
        case .free:
            "Free"
        case .premium:
            "Paid"
        }
    }

    var challengeText: String {
        "I just scored \(Int(record.overallScore.rounded()))/100 on AIScend. Beat my scan and send yours back."
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

private struct ScanArchiveCard: View {
    let item: ScanArchiveItem
    let isBest: Bool
    let isLatest: Bool
    let onOpen: () -> Void

    @State private var didCopyChallenge = false

    private var score: Double {
        item.record.overallScore
    }

    private var accentColor: Color {
        switch score {
        case 80...:
            return Color(red: 0.58, green: 0.95, blue: 0.72)
        case 68...:
            return Color(red: 0.86, green: 0.79, blue: 0.43)
        default:
            return AIscendTheme.Colors.textSecondary
        }
    }

    private var scoreBarColor: Color {
        switch score {
        case 80...:
            return Color(red: 0.30, green: 0.82, blue: 0.54)
        case 68...:
            return Color(red: 0.91, green: 0.71, blue: 0.28)
        default:
            return Color(red: 0.88, green: 0.45, blue: 0.37)
        }
    }

    private var borderColor: Color {
        if isBest {
            return Color(red: 0.96, green: 0.83, blue: 0.46).opacity(0.54)
        }

        if isLatest {
            return AIscendTheme.Colors.accentCyan.opacity(0.34)
        }

        return AIscendTheme.Colors.borderSubtle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text(item.createdAt, format: .dateTime.month(.abbreviated).day().year().hour().minute())
                        .aiscendTextStyle(.cardTitle)

                    Text(item.record.tierTitle)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                }

                Spacer()

                HStack(spacing: 8) {
                    ScanArchiveTag(title: item.accessLabel, tint: accentColor.opacity(0.18), foreground: accentColor)

                    if isBest {
                        ScanArchiveTag(
                            title: "Best Score",
                            symbol: "trophy.fill",
                            tint: Color(red: 0.72, green: 0.58, blue: 0.22).opacity(0.22),
                            foreground: Color(red: 0.96, green: 0.83, blue: 0.46)
                        )
                    }

                    if isLatest {
                        ScanArchiveTag(
                            title: "Latest Scan",
                            symbol: "clock.fill",
                            tint: AIscendTheme.Colors.accentGlow.opacity(0.18),
                            foreground: AIscendTheme.Colors.accentGlow
                        )
                    }
                }
            }

            HStack(spacing: AIscendTheme.Spacing.small) {
                ScanArchivePhotoCard(title: "Front", url: url(from: item.record.meta.frontUrl))
                ScanArchivePhotoCard(title: "Side", url: url(from: item.record.meta.sideUrl))
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                        Text("Overall score")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(Int(score.rounded()))")
                                .aiscendTextStyle(.metricCompact)
                                .foregroundStyle(AIscendTheme.Colors.textPrimary)

                            Text("/ 100")
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        }
                    }

                    Spacer()

                    Label("Open result", systemImage: "arrow.up.right")
                        .aiscendTextStyle(.caption, color: accentColor)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.56))

                        Capsule(style: .continuous)
                            .fill(scoreBarColor)
                            .frame(width: max(geometry.size.width * min(max(score, 0), 100) / 100, 8))
                    }
                }
                .frame(height: 10)

                Text(item.record.headline)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .lineLimit(2)
            }

            HStack(spacing: 10) {
                ShareLink(item: item.shareText) {
                    ScanArchiveActionButton(
                        title: "Share",
                        symbol: "square.and.arrow.up",
                        fill: AIscendTheme.Colors.accentCyan.opacity(0.20),
                        stroke: AIscendTheme.Colors.accentCyan.opacity(0.34)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    UIPasteboard.general.string = item.challengeText
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()

                    withAnimation(.easeOut(duration: 0.2)) {
                        didCopyChallenge = true
                    }

                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_400_000_000)
                        withAnimation(.easeOut(duration: 0.2)) {
                            didCopyChallenge = false
                        }
                    }
                } label: {
                    ScanArchiveActionButton(
                        title: didCopyChallenge ? "Copied" : "Challenge a Friend",
                        symbol: didCopyChallenge ? "checkmark" : "bolt.fill",
                        fill: AIscendTheme.Colors.success.opacity(0.18),
                        stroke: AIscendTheme.Colors.success.opacity(0.28)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AIscendTheme.Spacing.mediumLarge)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.10),
                            AIscendTheme.Colors.surfaceHighlight.opacity(0.68),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.22), radius: 20, x: 0, y: 12)
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture(perform: onOpen)
    }

    private func url(from rawValue: String?) -> URL? {
        guard let rawValue = rawValue?.trimmedNonEmpty else {
            return nil
        }

        if rawValue.hasPrefix("http://") || rawValue.hasPrefix("https://") || rawValue.hasPrefix("file://") {
            return URL(string: rawValue)
        }

        if rawValue.hasPrefix("/") {
            return URL(fileURLWithPath: rawValue)
        }

        return URL(string: rawValue)
    }
}

private struct ScanArchivePhotoCard: View {
    let title: String
    let url: URL?

    @State private var didRevealImage = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: "11161D"))

            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .opacity(didRevealImage ? 1 : 0)
                            .scaleEffect(didRevealImage ? 1 : 1.03)
                            .blur(radius: didRevealImage ? 0 : 10)
                            .onAppear {
                                withAnimation(.easeOut(duration: 0.45)) {
                                    didRevealImage = true
                                }
                            }
                    case .empty:
                        photoPlaceholder
                            .overlay(ScanArchiveShimmerBlock(cornerRadius: 22))
                    default:
                        photoPlaceholder
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            } else {
                photoPlaceholder
            }

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.72)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                .padding(AIscendTheme.Spacing.medium)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 162)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private var photoPlaceholder: some View {
        LinearGradient(
            colors: [
                Color(hex: "1A2028"),
                Color(hex: "0D1118")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: "person.crop.rectangle")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(AIscendTheme.Colors.textMuted)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct ScanArchiveActionButton: View {
    let title: String
    let symbol: String
    let fill: Color
    let stroke: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            Capsule(style: .continuous)
                .fill(fill)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(stroke, lineWidth: 1)
        )
    }
}

private struct ScanArchiveTag: View {
    let title: String
    var symbol: String? = nil
    let tint: Color
    let foreground: Color

    var body: some View {
        HStack(spacing: 6) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .bold))
            }

            Text(title)
                .aiscendTextStyle(.caption, color: foreground)
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(tint)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(foreground.opacity(0.20), lineWidth: 1)
        )
    }
}

private struct ScanArchiveLoadingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            ScanArchiveShimmerBlock(cornerRadius: 10)
                .frame(width: 160, height: 20)

            HStack(spacing: AIscendTheme.Spacing.small) {
                ScanArchiveShimmerBlock(cornerRadius: 22)
                    .frame(height: 162)

                ScanArchiveShimmerBlock(cornerRadius: 22)
                    .frame(height: 162)
            }

            ScanArchiveShimmerBlock(cornerRadius: 10)
                .frame(height: 18)

            ScanArchiveShimmerBlock(cornerRadius: 999)
                .frame(height: 10)

            HStack(spacing: 10) {
                ScanArchiveShimmerBlock(cornerRadius: 999)
                    .frame(height: 42)

                ScanArchiveShimmerBlock(cornerRadius: 999)
                    .frame(height: 42)
            }
        }
        .padding(AIscendTheme.Spacing.mediumLarge)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.42))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
        .redacted(reason: .placeholder)
    }
}

private struct ScanArchiveEmptyState: View {
    let onStartNewScan: () -> Void

    var body: some View {
        DashboardGlassCard {
            VStack(alignment: .center, spacing: AIscendTheme.Spacing.large) {
                AIscendIconOrb(symbol: "sparkles", accent: .sky, size: 56)

                VStack(spacing: AIscendTheme.Spacing.small) {
                    Text("You have not scanned yet")
                        .aiscendTextStyle(.sectionTitle)

                    Text("Start your first scan and this archive will begin tracking your strongest reads over time.")
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Button(action: onStartNewScan) {
                    AIscendButtonLabel(
                        title: "Start Your Scan",
                        leadingSymbol: "camera.aperture"
                    )
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AIscendTheme.Spacing.mediumLarge)
        }
    }
}

private struct ScanArchiveShimmerBlock: View {
    let cornerRadius: CGFloat

    @State private var shimmerX: CGFloat = -1.2

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.18),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.72)
                    .offset(x: geometry.size.width * shimmerX)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .onAppear {
                shimmerX = -1.2
                withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                    shimmerX = 1.2
                }
            }
    }
}

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
