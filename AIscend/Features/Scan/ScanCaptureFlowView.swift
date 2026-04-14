//
//  ScanCaptureFlowView.swift
//  AIscend
//
//  Created by Codex on 4/12/26.
//

import PhotosUI
import SwiftUI
import UIKit

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

protocol ScanAnalysisServiceProtocol: Sendable {
    func analyze(
        frontImageData: Data,
        sideImageData: Data,
        email: String?,
        userID: String?,
        accessLevel: ScanResultsAccess
    ) async throws -> PersistedScanRecord
}

enum ScanAnalysisError: LocalizedError, Equatable {
    case missingBackendBaseURL
    case invalidResponse
    case backend(String)

    var errorDescription: String? {
        switch self {
        case .missingBackendBaseURL:
            "Add `AISCEND_API_BASE_URL` to the app configuration before submitting scan captures."
        case .invalidResponse:
            "AIScend returned an unreadable scan response. Please try again."
        case .backend(let message):
            message
        }
    }
}

actor ScanAnalysisService: ScanAnalysisServiceProtocol {
    private let configuration: AIscendChatConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder

    init(
        configuration: AIscendChatConfiguration = .live,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func analyze(
        frontImageData: Data,
        sideImageData: Data,
        email: String?,
        userID: String?,
        accessLevel: ScanResultsAccess
    ) async throws -> PersistedScanRecord {
        guard let baseURL = configuration.backendBaseURL else {
            throw ScanAnalysisError.missingBackendBaseURL
        }

        let scanPath = configuration.scanAnalyzePath
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let endpoint = baseURL.appendingPathComponent(scanPath.isEmpty ? "scan/analyze" : scanPath)
        let identity = try? await authenticatedIdentity(forceRefresh: true)
        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let idToken = identity?.idToken?.trimmedNonEmpty {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = multipartBody(
            boundary: boundary,
            frontImageData: frontImageData,
            sideImageData: sideImageData,
            email: identity?.email ?? email,
            userID: identity?.userID ?? userID,
            accessLevel: accessLevel
        )

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScanAnalysisError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ScanAnalysisError.backend(
                backendMessage(from: data, statusCode: httpResponse.statusCode)
            )
        }

        return try parseResult(
            from: data,
            email: identity?.email ?? email,
            accessLevel: accessLevel
        )
    }
}

private extension ScanAnalysisService {
    struct AuthenticatedIdentity {
        let userID: String?
        let email: String?
        let idToken: String?
    }

    func multipartBody(
        boundary: String,
        frontImageData: Data,
        sideImageData: Data,
        email: String?,
        userID: String?,
        accessLevel: ScanResultsAccess
    ) -> Data {
        var body = Data()

        body.appendMultipartField(named: "access", value: accessLevel.rawValue, boundary: boundary)
        body.appendMultipartField(named: "scanType", value: accessLevel.rawValue, boundary: boundary)
        body.appendMultipartField(named: "source", value: "scan-flow", boundary: boundary)

        if let email = email?.trimmedNonEmpty {
            body.appendMultipartField(named: "email", value: email, boundary: boundary)
        }

        if let userID = userID?.trimmedNonEmpty {
            body.appendMultipartField(named: "userId", value: userID, boundary: boundary)
        }

        body.appendMultipartFile(
            named: "frontImage",
            filename: "front.jpg",
            mimeType: "image/jpeg",
            data: frontImageData,
            boundary: boundary
        )
        body.appendMultipartFile(
            named: "sideImage",
            filename: "side.jpg",
            mimeType: "image/jpeg",
            data: sideImageData,
            boundary: boundary
        )
        body.appendUTF8("--\(boundary)--\r\n")

        return body
    }

    func parseResult(
        from data: Data,
        email: String?,
        accessLevel: ScanResultsAccess
    ) throws -> PersistedScanRecord {
        if let directRecord = try? decoder.decode(PersistedScanRecord.self, from: data),
           directRecord.isDisplayable
        {
            return normalized(directRecord, email: email, accessLevel: accessLevel)
        }

        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ScanAnalysisError.invalidResponse
        }

        let candidates: [Any?] = [
            object,
            object["result"],
            object["scan"],
            object["scanResult"],
            object["scan_result"],
            object["data"],
            object["analysis"]
        ]

        for candidate in candidates {
            if let record = try decodeRecord(from: candidate, rootObject: object),
               record.isDisplayable
            {
                return normalized(record, email: email, accessLevel: accessLevel)
            }
        }

        throw ScanAnalysisError.invalidResponse
    }

    func decodeRecord(from raw: Any?, rootObject: [String: Any]) throws -> PersistedScanRecord? {
        guard let raw else {
            return nil
        }

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

            let savedAt = dateValue(
                for: ["savedAt", "saved_at", "createdAt", "created_at", "updatedAt", "updated_at"],
                in: dictionary
            ) ?? dateValue(
                for: ["savedAt", "saved_at", "createdAt", "created_at"],
                in: rootObject
            )

            return PersistedScanRecord(
                payload: payload,
                meta: meta,
                savedAt: savedAt
            )
        }

        if let jsonString = raw as? String,
           let jsonData = jsonString.data(using: .utf8)
        {
            if let directRecord = try? decoder.decode(PersistedScanRecord.self, from: jsonData),
               directRecord.isDisplayable
            {
                return directRecord
            }

            if let payload = try? decoder.decode(ScanPayload.self, from: jsonData) {
                return PersistedScanRecord(
                    payload: payload,
                    meta: ScanResultMeta(),
                    savedAt: nil
                )
            }
        }

        return nil
    }

    func decodePayload(from raw: Any?) throws -> ScanPayload? {
        guard let raw else {
            return nil
        }

        if let dictionary = raw as? [String: Any] {
            let data = try jsonData(from: dictionary)
            return try? decoder.decode(ScanPayload.self, from: data)
        }

        if let jsonString = raw as? String,
           let data = jsonString.data(using: .utf8)
        {
            return try? decoder.decode(ScanPayload.self, from: data)
        }

        return nil
    }

    func decodeMeta(from raw: Any?) throws -> ScanResultMeta? {
        guard let raw else {
            return nil
        }

        if let dictionary = raw as? [String: Any] {
            let data = try jsonData(from: dictionary)
            return try? decoder.decode(ScanResultMeta.self, from: data)
        }

        if let jsonString = raw as? String,
           let data = jsonString.data(using: .utf8)
        {
            return try? decoder.decode(ScanResultMeta.self, from: data)
        }

        return nil
    }

    func jsonData(from value: Any) throws -> Data {
        guard JSONSerialization.isValidJSONObject(value) else {
            throw ScanAnalysisError.invalidResponse
        }

        return try JSONSerialization.data(withJSONObject: value, options: [])
    }

    func normalized(
        _ result: PersistedScanRecord,
        email: String?,
        accessLevel: ScanResultsAccess
    ) -> PersistedScanRecord {
        var normalized = result

        if normalized.meta.email?.trimmedNonEmpty == nil {
            normalized.meta.email = email
        }

        if normalized.meta.type?.trimmedNonEmpty == nil {
            normalized.meta.type = accessLevel.rawValue
        }

        if normalized.meta.source?.trimmedNonEmpty == nil {
            normalized.meta.source = "scan-flow"
        }

        if normalized.savedAt == nil {
            normalized.savedAt = .now
        }

        return normalized
    }

    func dateValue(for keys: [String], in object: [String: Any]) -> Date? {
        for key in keys {
            guard let value = object[key] else {
                continue
            }

            if let date = dateValue(from: value) {
                return date
            }
        }

        return nil
    }

    func dateValue(from raw: Any) -> Date? {
        if let date = raw as? Date {
            return date
        }

        if let string = raw as? String {
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: string) {
                return date
            }

            if let timeInterval = Double(string) {
                return dateValue(from: timeInterval)
            }
        }

        if let number = raw as? NSNumber {
            return dateValue(from: number.doubleValue)
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

    func dateValue(from timeInterval: Double) -> Date {
        let normalizedInterval = timeInterval > 10_000_000_000 ? timeInterval / 1000 : timeInterval
        return Date(timeIntervalSince1970: normalizedInterval)
    }

    func backendMessage(from data: Data, statusCode: Int) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let message = stringValue(
                for: ["detail", "error", "message", "reason"],
                in: object
            )
            if let message, !message.isEmpty {
                return message
            }
        }

        switch statusCode {
        case 400:
            return "AIScend could not validate those scan captures."
        case 401, 403:
            return "Your session needs to be refreshed before AIScend can submit the scan."
        case 404:
            return "The scan endpoint could not be reached from this build."
        case 413:
            return "Those photos are too large to upload right now."
        default:
            return "AIScend could not finish the scan right now."
        }
    }

    func stringValue(for keys: [String], in data: [String: Any]) -> String? {
        for key in keys {
            if let value = data[key] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }

        return nil
    }

    func authenticatedIdentity(forceRefresh: Bool) async throws -> AuthenticatedIdentity? {
        #if canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else {
            return nil
        }

        let idToken = try await fetchIDToken(for: user, forceRefresh: forceRefresh)
        return AuthenticatedIdentity(
            userID: user.uid,
            email: user.email,
            idToken: idToken
        )
        #else
        return nil
        #endif
    }

    #if canImport(FirebaseAuth)
    func fetchIDToken(for user: FirebaseAuth.User, forceRefresh: Bool) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            user.getIDTokenForcingRefresh(forceRefresh) { token, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: ScanAnalysisError.invalidResponse)
                }
            }
        }
    }
    #endif
}

private extension Data {
    mutating func appendUTF8(_ string: String) {
        append(Data(string.utf8))
    }

    mutating func appendMultipartField(named name: String, value: String, boundary: String) {
        appendUTF8("--\(boundary)\r\n")
        appendUTF8("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        appendUTF8("\(value)\r\n")
    }

    mutating func appendMultipartFile(
        named name: String,
        filename: String,
        mimeType: String,
        data: Data,
        boundary: String
    ) {
        appendUTF8("--\(boundary)\r\n")
        appendUTF8("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        appendUTF8("Content-Type: \(mimeType)\r\n\r\n")
        append(data)
        appendUTF8("\r\n")
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct ScanCaptureFlowView: View {
    let session: AuthSessionStore
    let onOpenRoutine: () -> Void
    let onOpenChat: () -> Void
    let onReturnHome: () -> Void
    let onDismiss: () -> Void

    @ObservedObject private var badgeManager: BadgeManager
    @ObservedObject private var dailyCheckInStore: DailyCheckInStore
    @ObservedObject private var notificationManager: NotificationManager
    private let analysisService: ScanAnalysisServiceProtocol

    @State private var phase: Phase = .frontCapture
    @State private var frontPickerItem: PhotosPickerItem?
    @State private var sidePickerItem: PhotosPickerItem?
    @State private var frontPreview: UIImage?
    @State private var sidePreview: UIImage?
    @State private var frontData: Data?
    @State private var sideData: Data?
    @State private var progress: Double = 0
    @State private var importMessage: String?
    @State private var isImportingFront = false
    @State private var isImportingSide = false
    @State private var processingTask: Task<Void, Never>?
    @State private var generatedResult: PersistedScanRecord?

    init(
        session: AuthSessionStore,
        badgeManager: BadgeManager,
        dailyCheckInStore: DailyCheckInStore,
        notificationManager: NotificationManager,
        analysisService: ScanAnalysisServiceProtocol = ScanAnalysisService(),
        onOpenRoutine: @escaping () -> Void = {},
        onOpenChat: @escaping () -> Void = {},
        onReturnHome: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void = {}
    ) {
        self.session = session
        self.onOpenRoutine = onOpenRoutine
        self.onOpenChat = onOpenChat
        self.onReturnHome = onReturnHome
        self.onDismiss = onDismiss
        self.analysisService = analysisService
        self._badgeManager = ObservedObject(wrappedValue: badgeManager)
        self._dailyCheckInStore = ObservedObject(wrappedValue: dailyCheckInStore)
        self._notificationManager = ObservedObject(wrappedValue: notificationManager)
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            content
        }
        .preferredColorScheme(.dark)
        .onChange(of: frontPickerItem) { _, newValue in
            guard let newValue else {
                return
            }

            Task {
                await importPhoto(from: newValue, sideProfile: false)
            }
        }
        .onChange(of: sidePickerItem) { _, newValue in
            guard let newValue else {
                return
            }

            Task {
                await importPhoto(from: newValue, sideProfile: true)
            }
        }
        .onDisappear {
            processingTask?.cancel()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .frontCapture:
            captureExperience(for: .front, review: false)
        case .frontReview:
            captureExperience(for: .front, review: true)
        case .sideCapture:
            captureExperience(for: .side, review: false)
        case .sideReview:
            captureExperience(for: .side, review: true)
        case .processing:
            ScanProcessingExperience(
                progress: progress,
                onCancel: cancelProcessing
            )
        case .results:
            ScanResultsFlowView(
                session: session,
                initialResult: generatedResult,
                badgeManager: badgeManager,
                dailyCheckInStore: dailyCheckInStore,
                notificationManager: notificationManager,
                onOpenScan: resetToCapture,
                onOpenRoutine: onOpenRoutine,
                onOpenChat: onOpenChat,
                onReturnHome: onReturnHome,
                onDismiss: onDismiss
            )
        }
    }

    private func captureExperience(for angle: CaptureAngle, review: Bool) -> some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    topBar(topInset: geometry.safeAreaInsets.top)
                    sessionSummaryCard
                    captureStageSummaryCard(for: angle, review: review)
                    captureStageCard(for: angle, review: review)
                    captureProtocolCard

                    if let importMessage {
                        Text(importMessage)
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                    }
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
        }
    }

    private func topBar(topInset: CGFloat) -> some View {
        HStack {
            if canGoBack {
                Button(action: navigateBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color(hex: "10141B").opacity(0.86))
                                .overlay(Circle().fill(.ultraThinMaterial).opacity(0.55))
                        )
                        .overlay(
                            Circle()
                                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            AIscendBadge(
                title: "Guided scan",
                symbol: "sparkles.rectangle.stack.fill",
                style: .accent
            )

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color(hex: "10141B").opacity(0.86))
                            .overlay(Circle().fill(.ultraThinMaterial).opacity(0.55))
                    )
                    .overlay(
                        Circle()
                            .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, topInset + AIscendTheme.Spacing.small)
    }

    private var sessionSummaryCard: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                AIscendSectionHeader(
                    title: "Build a clean front and side read",
                    subtitle: "Confirm the front angle first, replace it if needed, then repeat for the side profile before AIScend sends both captures to the API."
                )

                HStack(spacing: AIscendTheme.Spacing.small) {
                    scanMetric(
                        title: "Access",
                        value: isPremiumUnlocked ? "Premium" : "Free",
                        detail: isPremiumUnlocked ? "Full report path" : "Preview + upsell"
                    )
                    scanMetric(
                        title: "Archive",
                        value: session.user == nil ? "Local" : "Sync",
                        detail: session.user == nil ? "Saved on device" : "Ready for Firestore"
                    )
                }

                Text("Once the API response comes back, the result drops straight into the existing guided reveal and archive pipeline.")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
            }
        }
    }

    private func captureStageSummaryCard(for angle: CaptureAngle, review: Bool) -> some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                DashboardSectionHeading(
                    eyebrow: angle.stepEyebrow(review: review),
                    title: angle.stepTitle(review: review),
                    subtitle: angle.stepSubtitle(review: review)
                )

                HStack(spacing: AIscendTheme.Spacing.small) {
                    ScanFlowProgressPill(
                        title: "Front",
                        state: angle == .front ? .current : .complete
                    )
                    ScanFlowProgressPill(
                        title: "Side",
                        state: angle == .side ? .current : (angle == .front ? .upcoming : .complete)
                    )
                    ScanFlowProgressPill(
                        title: "Analyze",
                        state: .upcoming
                    )
                }
            }
        }
    }

    private func captureStageCard(for angle: CaptureAngle, review: Bool) -> some View {
        ScanImportCard(
            title: angle.cardTitle,
            subtitle: angle.cardSubtitle,
            buttonTitle: angle.buttonTitle(previewExists: preview(for: angle) != nil),
            image: preview(for: angle),
            symbol: angle.symbol,
            isBusy: isImporting(angle)
        ) {
            VStack(spacing: AIscendTheme.Spacing.small) {
                if review {
                    Button(action: { confirmCapture(for: angle) }) {
                        AIscendButtonLabel(
                            title: angle.confirmButtonTitle,
                            leadingSymbol: angle == .front ? "checkmark.circle.fill" : "arrow.up.circle.fill"
                        )
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .primary))
                    .disabled(isImporting)
                }

                PhotosPicker(selection: pickerBinding(for: angle), matching: .images) {
                    AIscendButtonLabel(
                        title: review ? angle.replaceButtonTitle : angle.buttonTitle(previewExists: preview(for: angle) != nil),
                        leadingSymbol: review ? "arrow.triangle.2.circlepath" : "photo.badge.plus"
                    )
                }
                .buttonStyle(AIscendButtonStyle(variant: review ? .secondary : .primary))
                .disabled(isImporting)

                if review {
                    Text(angle.reviewHint)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                }
            }
        }
    }

    private var captureProtocolCard: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                DashboardSectionHeading(
                    eyebrow: "Protocol",
                    title: "Capture checklist",
                    subtitle: "The review flow is simple on purpose: cleaner inputs now mean fewer bad reads once the API starts scoring both angles."
                )

                VStack(spacing: AIscendTheme.Spacing.small) {
                    ScanChecklistRow(
                        symbol: "sun.max.fill",
                        title: "Stable lighting",
                        detail: "Avoid overhead shadows or mixed light so skin and structure read consistently."
                    )
                    ScanChecklistRow(
                        symbol: "face.smiling.inverse",
                        title: "Neutral expression",
                        detail: "Relax the jaw, keep lips closed, and avoid tilting the head between angles."
                    )
                    ScanChecklistRow(
                        symbol: "lock.shield.fill",
                        title: "Private handoff",
                        detail: session.user == nil
                            ? "The result is stored locally unless you sign in later."
                            : "The result can be saved into your archive after the reveal finishes."
                    )
                }
            }
        }
    }

    private var isPremiumUnlocked: Bool {
        badgeManager.earnedBadges.contains(where: { $0.id == .premiumUnlocked })
    }

    private var isImporting: Bool {
        isImportingFront || isImportingSide
    }

    private var canGoBack: Bool {
        switch phase {
        case .frontCapture, .processing, .results:
            return false
        case .frontReview, .sideCapture, .sideReview:
            return true
        }
    }

    private func preview(for angle: CaptureAngle) -> UIImage? {
        switch angle {
        case .front:
            frontPreview
        case .side:
            sidePreview
        }
    }

    private func isImporting(_ angle: CaptureAngle) -> Bool {
        switch angle {
        case .front:
            isImportingFront
        case .side:
            isImportingSide
        }
    }

    private func pickerBinding(for angle: CaptureAngle) -> Binding<PhotosPickerItem?> {
        switch angle {
        case .front:
            $frontPickerItem
        case .side:
            $sidePickerItem
        }
    }

    private func navigateBack() {
        switch phase {
        case .frontCapture, .processing, .results:
            break
        case .frontReview:
            phase = .frontCapture
        case .sideCapture:
            phase = .frontReview
        case .sideReview:
            phase = .sideCapture
        }
    }

    private func confirmCapture(for angle: CaptureAngle) {
        switch angle {
        case .front:
            importMessage = "Front capture confirmed. Upload the side profile next."
            phase = .sideCapture
        case .side:
            startProcessing()
        }
    }

    private func scanMetric(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            Text(value)
                .aiscendTextStyle(.sectionTitle)

            Text(detail)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.62))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private func importPhoto(from item: PhotosPickerItem, sideProfile: Bool) async {
        await MainActor.run {
            if sideProfile {
                isImportingSide = true
            } else {
                isImportingFront = true
            }
            importMessage = nil
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                await MainActor.run {
                    importMessage = "That photo could not be loaded."
                    setImporting(false, sideProfile: sideProfile)
                }
                return
            }

            guard let image = UIImage(data: data),
                  let compressed = image.jpegData(compressionQuality: 0.88) else {
                await MainActor.run {
                    importMessage = "That photo format is not supported."
                    setImporting(false, sideProfile: sideProfile)
                }
                return
            }

            await MainActor.run {
                if sideProfile {
                    sidePreview = image
                    sideData = compressed
                    phase = .sideReview
                } else {
                    frontPreview = image
                    frontData = compressed
                    phase = .frontReview
                }

                setImporting(false, sideProfile: sideProfile)

                importMessage = sideProfile
                    ? "Side profile loaded. Confirm it or replace it before AIScend submits the scan."
                    : "Front capture loaded. Confirm it or replace it before moving to the side view."
            }
        } catch {
            await MainActor.run {
                importMessage = error.localizedDescription
                setImporting(false, sideProfile: sideProfile)
            }
        }
    }

    private func setImporting(_ importing: Bool, sideProfile: Bool) {
        if sideProfile {
            isImportingSide = importing
        } else {
            isImportingFront = importing
        }
    }

    private func startProcessing() {
        guard let frontData,
              let sideData else {
            return
        }

        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        importMessage = nil
        progress = 0
        generatedResult = nil
        phase = .processing
        processingTask?.cancel()

        let accessLevel: ScanResultsAccess = isPremiumUnlocked ? .premium : .free
        let email = session.user?.email
        let userID = session.user?.id

        processingTask = Task { @MainActor in
            do {
                try await animateProgress(to: 12, duration: 0.36)
                try await animateProgress(to: 24, duration: 0.34)

                async let remoteResult = analysisService.analyze(
                    frontImageData: frontData,
                    sideImageData: sideData,
                    email: email,
                    userID: userID,
                    accessLevel: accessLevel
                )

                try await animateProgress(to: 42, duration: 0.45)
                try await animateProgress(to: 60, duration: 0.55)
                try await animateProgress(to: 78, duration: 0.60)
                try await animateProgress(to: 92, duration: 0.70)

                let analyzedResult = try await remoteResult
                let result = try finalizedResult(
                    analyzedResult,
                    frontData: frontData,
                    sideData: sideData,
                    email: email,
                    accessLevel: accessLevel
                )

                try await animateProgress(to: 100, duration: 0.24)

                generatedResult = result
                phase = .results
                processingTask = nil
            } catch is CancellationError {
                processingTask = nil
            } catch {
                importMessage = error.localizedDescription.isEmpty
                    ? "The scan could not be submitted right now. Please try again."
                    : error.localizedDescription
                phase = .sideReview
                processingTask = nil
            }
        }
    }

    private func cancelProcessing() {
        processingTask?.cancel()
        processingTask = nil
        phase = .sideReview
        progress = 0
        importMessage = "Scan cancelled before the API submission finished."
    }

    private func resetToCapture() {
        generatedResult = nil
        progress = 0
        importMessage = nil
        frontPickerItem = nil
        sidePickerItem = nil
        frontPreview = nil
        sidePreview = nil
        frontData = nil
        sideData = nil
        phase = .frontCapture
    }

    private func animateProgress(to target: Double, duration: TimeInterval) async throws {
        let clampedTarget = max(progress, min(target, 100))
        let start = progress
        let tick: TimeInterval = 0.05
        let steps = max(Int(duration / tick), 1)

        for step in 1...steps {
            try Task.checkCancellation()
            let value = start + ((clampedTarget - start) * (Double(step) / Double(steps)))
            withAnimation(.easeInOut(duration: tick)) {
                progress = value
            }
            try await Task.sleep(nanoseconds: UInt64(tick * 1_000_000_000))
        }

        progress = clampedTarget
    }

    private func finalizedResult(
        _ apiResult: PersistedScanRecord,
        frontData: Data,
        sideData: Data,
        email: String?,
        accessLevel: ScanResultsAccess
    ) throws -> PersistedScanRecord {
        let frontURL = try ScanCaptureAssetStore.store(data: frontData, prefix: "front")
        let sideURL = try ScanCaptureAssetStore.store(data: sideData, prefix: "side")

        var result = apiResult

        if result.meta.frontUrl?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            result.meta.frontUrl = frontURL.absoluteString
        }

        if result.meta.sideUrl?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            result.meta.sideUrl = sideURL.absoluteString
        }

        if result.meta.email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            result.meta.email = email
        }

        if result.meta.type?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            result.meta.type = accessLevel.rawValue
        }

        if result.meta.source?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            result.meta.source = "scan-flow"
        }

        if result.savedAt == nil {
            result.savedAt = .now
        }

        return result
    }
}

private extension ScanCaptureFlowView {
    enum Phase {
        case frontCapture
        case frontReview
        case sideCapture
        case sideReview
        case processing
        case results
    }
}

private extension ScanCaptureFlowView {
    enum CaptureAngle {
        case front
        case side

        var symbol: String {
            switch self {
            case .front:
                "person.crop.square"
            case .side:
                "person.crop.rectangle"
            }
        }

        var cardTitle: String {
            switch self {
            case .front:
                "Front capture"
            case .side:
                "Side profile"
            }
        }

        var cardSubtitle: String {
            switch self {
            case .front:
                "Straight-on face, level camera, even light."
            case .side:
                "Clear profile line, relaxed jaw, same lighting."
            }
        }

        func stepEyebrow(review: Bool) -> String {
            switch (self, review) {
            case (.front, false):
                "Step 1 of 3"
            case (.front, true):
                "Review front"
            case (.side, false):
                "Step 2 of 3"
            case (.side, true):
                "Review side"
            }
        }

        func stepTitle(review: Bool) -> String {
            switch (self, review) {
            case (.front, false):
                "Upload your front photo"
            case (.front, true):
                "Confirm the front capture"
            case (.side, false):
                "Upload your side profile"
            case (.side, true):
                "Confirm the side photo and submit"
            }
        }

        func stepSubtitle(review: Bool) -> String {
            switch (self, review) {
            case (.front, false):
                "Start with the straight-on angle. Once it looks clean, you can lock it in or replace it."
            case (.front, true):
                "Check framing, posture, and lighting before moving on to the side profile."
            case (.side, false):
                "Match the same lighting, keep the jaw relaxed, and line up a clean profile."
            case (.side, true):
                "The second confirmation is the last stop before both photos are pushed to the API."
            }
        }

        func buttonTitle(previewExists: Bool) -> String {
            switch self {
            case .front:
                previewExists ? "Replace front photo" : "Upload front photo"
            case .side:
                previewExists ? "Replace side photo" : "Upload side photo"
            }
        }

        var replaceButtonTitle: String {
            switch self {
            case .front:
                "Replace front photo"
            case .side:
                "Replace side photo"
            }
        }

        var confirmButtonTitle: String {
            switch self {
            case .front:
                "Use front photo"
            case .side:
                "Push scan to API"
            }
        }

        var reviewHint: String {
            switch self {
            case .front:
                "If anything feels off, replace this angle now so the side step starts from a clean baseline."
            case .side:
                "Submitting now keeps the guided results flow intact and sends the confirmed pair to the backend."
            }
        }
    }
}

private enum ScanCaptureAssetStore {
    static func store(data: Data, prefix: String) throws -> URL {
        let root = try captureDirectory()
        let fileURL = root.appendingPathComponent("\(prefix)-\(UUID().uuidString).jpg")
        try data.write(to: fileURL, options: [.atomic])
        return fileURL
    }

    private static func captureDirectory() throws -> URL {
        let baseDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory

        let directory = baseDirectory.appendingPathComponent("ScanCaptures", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

private enum ScanFlowStepState {
    case complete
    case current
    case upcoming
}

private struct ScanFlowProgressPill: View {
    let title: String
    let state: ScanFlowStepState

    private var fill: Color {
        switch state {
        case .complete:
            AIscendTheme.Colors.accentPrimary.opacity(0.18)
        case .current:
            AIscendTheme.Colors.accentGlow.opacity(0.22)
        case .upcoming:
            AIscendTheme.Colors.surfaceHighlight.opacity(0.58)
        }
    }

    private var stroke: Color {
        switch state {
        case .complete:
            AIscendTheme.Colors.accentGlow.opacity(0.34)
        case .current:
            AIscendTheme.Colors.accentGlow.opacity(0.56)
        case .upcoming:
            AIscendTheme.Colors.borderSubtle
        }
    }

    private var foreground: Color {
        switch state {
        case .complete, .current:
            AIscendTheme.Colors.textPrimary
        case .upcoming:
            AIscendTheme.Colors.textSecondary
        }
    }

    private var iconName: String {
        switch state {
        case .complete:
            "checkmark.circle.fill"
        case .current:
            "circle.fill"
        case .upcoming:
            "circle"
        }
    }

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: iconName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(state == .upcoming ? AIscendTheme.Colors.textMuted : AIscendTheme.Colors.accentGlow)

            Text(title)
                .aiscendTextStyle(.caption, color: foreground)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(stroke, lineWidth: 1)
        )
    }
}

private struct ScanImportCard<CTA: View>: View {
    let title: String
    let subtitle: String
    let buttonTitle: String
    let image: UIImage?
    let symbol: String
    let isBusy: Bool
    let cta: CTA

    init(
        title: String,
        subtitle: String,
        buttonTitle: String,
        image: UIImage?,
        symbol: String,
        isBusy: Bool,
        @ViewBuilder cta: () -> CTA
    ) {
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.image = image
        self.symbol = symbol
        self.isBusy = isBusy
        self.cta = cta()
    }

    var body: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                    AIscendIconOrb(symbol: symbol, accent: .sky, size: 46)

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                        Text(title)
                            .aiscendTextStyle(.sectionTitle)

                        Text(subtitle)
                            .aiscendTextStyle(.body)
                    }
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.52))
                        .frame(height: 250)

                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                        LinearGradient(
                            colors: [
                                .clear,
                                AIscendTheme.Colors.overlayDark
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    } else {
                        VStack(spacing: AIscendTheme.Spacing.small) {
                            Image(systemName: symbol)
                                .font(.system(size: 42, weight: .medium))
                                .foregroundStyle(AIscendTheme.Colors.accentGlow)

                            Text(buttonTitle)
                                .aiscendTextStyle(.cardTitle)

                            Text("Import a clean image from your library to populate this angle.")
                                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 280)
                        }
                        .padding(AIscendTheme.Spacing.large)
                    }

                    if isBusy {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.black.opacity(0.34))

                        VStack(spacing: AIscendTheme.Spacing.small) {
                            ProgressView()
                                .tint(AIscendTheme.Colors.accentGlow)

                            Text("Loading photo")
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                )

                cta
            }
        }
    }
}

private struct ScanChecklistRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: symbol, accent: .mint, size: 40)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(title)
                    .aiscendTextStyle(.cardTitle)

                Text(detail)
                    .aiscendTextStyle(.body)
            }
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.62))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct SwipeToStartControl: View {
    let disabled: Bool
    let label: String
    let onComplete: () -> Void

    @State private var knobOffset: CGFloat = 0
    @State private var maxTravel: CGFloat = 0
    @State private var hasCompleted = false

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack {
                Text(label)
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textPrimary.opacity(disabled ? 0.72 : 1))

                Spacer()

                Text(disabled ? "Locked" : (hasCompleted ? "Done" : "Slide"))
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }

            GeometryReader { geometry in
                let knobSize: CGFloat = 52
                let travel = max(geometry.size.width - knobSize - 8, 0)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.28))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )

                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.10),
                            Color.white.opacity(0.02),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    HStack(spacing: 2) {
                        Spacer()
                        Image(systemName: "chevron.right")
                        Image(systemName: "chevron.right")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.textMuted)
                    .padding(.trailing, AIscendTheme.Spacing.medium)

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(disabled ? 0.72 : 1))
                        .frame(width: knobSize, height: knobSize)
                        .overlay(
                            Image(systemName: disabled ? "lock.fill" : "chevron.right")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.black)
                        )
                        .shadow(color: Color.black.opacity(0.24), radius: 18, x: 0, y: 10)
                        .padding(4)
                        .offset(x: knobOffset)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard !disabled, !hasCompleted else {
                                        return
                                    }

                                    maxTravel = travel
                                    knobOffset = min(max(0, value.translation.width), travel)
                                }
                                .onEnded { _ in
                                    guard !disabled, !hasCompleted else {
                                        withAnimation(.spring(response: 0.24, dampingFraction: 0.9)) {
                                            knobOffset = 0
                                        }
                                        return
                                    }

                                    let threshold = travel * 0.82
                                    if knobOffset >= threshold {
                                        hasCompleted = true
                                        withAnimation(.spring(response: 0.26, dampingFraction: 0.88)) {
                                            knobOffset = travel
                                        }
                                        onComplete()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                            knobOffset = 0
                                            hasCompleted = false
                                        }
                                    } else {
                                        withAnimation(.spring(response: 0.26, dampingFraction: 0.88)) {
                                            knobOffset = 0
                                        }
                                    }
                                }
                        )
                }
                .onAppear {
                    maxTravel = travel
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
                .accessibilityHint(disabled ? "Front and side photos are required before the scan can start." : "Swipe right to begin the scan.")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction {
                    guard !disabled else {
                        return
                    }
                    onComplete()
                }
            }
            .frame(height: 60)
        }
    }
}

private struct ScanProcessingExperience: View {
    let progress: Double
    let onCancel: () -> Void

    private var clampedProgress: Double {
        max(0, min(progress, 100))
    }

    private var etaLabel: String {
        let remaining = Int(((100 - clampedProgress) / 100) * 300)
        let minutes = remaining / 60
        let seconds = remaining % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    private var stage: ScanProcessingStage {
        switch clampedProgress {
        case ..<12:
            .init(label: "Booting", subtitle: "Initializing secure scan session...")
        case ..<24:
            .init(label: "Packaging", subtitle: "Preparing the confirmed front and side captures...")
        case ..<42:
            .init(label: "Uploading", subtitle: "Pushing both images into the scan API...")
        case ..<60:
            .init(label: "Queued", subtitle: "AIScend has accepted the capture pair and started the read...")
        case ..<78:
            .init(label: "Analysis", subtitle: "The backend is mapping features across both angles...")
        case ..<92:
            .init(label: "Scoring", subtitle: "Compiling the structured result payload...")
        default:
            .init(label: "Finalizing", subtitle: "Preparing your results dashboard...")
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    Button(action: onCancel) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary.opacity(0.88))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, geometry.safeAreaInsets.top + AIscendTheme.Spacing.medium)
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)

                Spacer()

                DashboardGlassCard(tone: .premium) {
                    VStack(alignment: .center, spacing: AIscendTheme.Spacing.mediumLarge) {
                        AIscendBadge(
                            title: "AIScend scanning",
                            symbol: "sparkles.rectangle.stack.fill",
                            style: .accent
                        )

                        HStack(spacing: AIscendTheme.Spacing.small) {
                            Circle()
                                .fill(AIscendTheme.Colors.accentGlow)
                                .frame(width: 8, height: 8)
                                .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.85), radius: 8, x: 0, y: 0)

                            Text("ETA \(etaLabel)")
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                        }
                        .padding(.horizontal, AIscendTheme.Spacing.medium)
                        .padding(.vertical, AIscendTheme.Spacing.small)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.84))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )

                        Text("AIScend submits the confirmed pair first, waits for the API response, and only then opens the guided reveal.")
                            .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)

                        AIscendLoadingIndicator()

                        VStack(spacing: AIscendTheme.Spacing.xxSmall) {
                            Text(stage.label)
                                .aiscendTextStyle(.sectionTitle)

                            Text(stage.subtitle)
                                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                            HStack {
                                Text("\(Int(clampedProgress))%")
                                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)

                                Spacer()

                                Text("AIScend Engine")
                                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))

                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    AIscendTheme.Colors.accentSoft,
                                                    AIscendTheme.Colors.accentPrimary
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * (clampedProgress / 100))
                                }
                            }
                            .frame(height: 10)
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                            ScanProcessingStepChip(done: clampedProgress >= 24, label: "Photos packaged")
                            ScanProcessingStepChip(done: clampedProgress >= 42, label: "Upload finished")
                            ScanProcessingStepChip(done: clampedProgress >= 78, label: "Analysis returned")
                            ScanProcessingStepChip(done: clampedProgress >= 95, label: "Results building")
                        }

                        Button(action: onCancel) {
                            AIscendButtonLabel(title: "Cancel scan", leadingSymbol: "xmark")
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .secondary))

                        Text("Tip: even lighting and a neutral expression improve consistency.")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)

                Spacer()
            }
        }
    }
}

private struct ScanProcessingStepChip: View {
    let done: Bool
    let label: String

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Circle()
                .fill(done ? AIscendTheme.Colors.accentGlow : AIscendTheme.Colors.textMuted.opacity(0.4))
                .frame(width: 8, height: 8)

            Text(label)
                .aiscendTextStyle(.caption, color: done ? AIscendTheme.Colors.textPrimary : AIscendTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(done ? AIscendTheme.Colors.accentPrimary.opacity(0.14) : AIscendTheme.Colors.surfaceHighlight.opacity(0.58))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(done ? AIscendTheme.Colors.accentGlow.opacity(0.26) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct ScanProcessingStage {
    let label: String
    let subtitle: String
}
