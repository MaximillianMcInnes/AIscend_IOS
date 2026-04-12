//
//  ScanCaptureFlowView.swift
//  AIscend
//
//  Created by Codex on 4/12/26.
//

import PhotosUI
import SwiftUI
import UIKit

struct ScanCaptureFlowView: View {
    let session: AuthSessionStore
    let onOpenRoutine: () -> Void
    let onOpenChat: () -> Void
    let onReturnHome: () -> Void
    let onDismiss: () -> Void

    @ObservedObject private var badgeManager: BadgeManager
    @ObservedObject private var dailyCheckInStore: DailyCheckInStore
    @ObservedObject private var notificationManager: NotificationManager

    @State private var phase: Phase = .capture
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
        case .capture:
            captureExperience
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

    private var captureExperience: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    topBar(topInset: geometry.safeAreaInsets.top)
                    sessionSummaryCard
                    captureCards
                    captureProtocolCard
                    swipeCard

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
                    subtitle: "Import both angles, keep expression neutral, and let AIScend turn the capture into the same guided reveal flow you outlined."
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

                Text("Fresh scan results open automatically after processing, and the guarded auto-save path only runs once for new scan-flow records.")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
            }
        }
    }

    private var captureCards: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            ScanImportCard(
                title: "Front capture",
                subtitle: "Straight-on face, level camera, even light.",
                buttonTitle: frontPreview == nil ? "Choose front photo" : "Replace front photo",
                image: frontPreview,
                symbol: "person.crop.square",
                isBusy: isImportingFront
            ) {
                PhotosPicker(selection: $frontPickerItem, matching: .images) {
                    AIscendButtonLabel(
                        title: frontPreview == nil ? "Choose front photo" : "Replace front photo",
                        leadingSymbol: "photo.badge.plus"
                    )
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))
                .disabled(isImporting)
            }

            ScanImportCard(
                title: "Side profile",
                subtitle: "Clear profile line, relaxed jaw, same lighting.",
                buttonTitle: sidePreview == nil ? "Choose side photo" : "Replace side photo",
                image: sidePreview,
                symbol: "person.crop.rectangle",
                isBusy: isImportingSide
            ) {
                PhotosPicker(selection: $sidePickerItem, matching: .images) {
                    AIscendButtonLabel(
                        title: sidePreview == nil ? "Choose side photo" : "Replace side photo",
                        leadingSymbol: "photo.badge.plus"
                    )
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
                .disabled(isImporting)
            }
        }
    }

    private var captureProtocolCard: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                DashboardSectionHeading(
                    eyebrow: "Protocol",
                    title: "Capture checklist",
                    subtitle: "This follows the same premium-feel scan flow: controlled inputs, guided processing, then a structured multi-page result reveal."
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

    private var swipeCard: some View {
        DashboardGlassCard(tone: .premium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                AIscendSectionHeader(
                    eyebrow: "Start",
                    title: "Swipe to begin the scan",
                    subtitle: canStartScan
                        ? "Both angles are loaded. The next step is the premium processing stage and then the guided breakdown."
                        : "Add both the front and side photos first."
                )

                SwipeToStartControl(
                    disabled: !canStartScan,
                    label: canStartScan ? "Slide to start scan" : "Front and side photos required",
                    onComplete: startProcessing
                )

                Text("Tip: this currently generates the guided result locally, then hands it into the existing results pipeline, including the guarded archive save.")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
            }
        }
    }

    private var isPremiumUnlocked: Bool {
        badgeManager.earnedBadges.contains(where: { $0.id == .premiumUnlocked })
    }

    private var isImporting: Bool {
        isImportingFront || isImportingSide
    }

    private var canStartScan: Bool {
        frontData != nil && sideData != nil && !isImporting
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
                } else {
                    frontPreview = image
                    frontData = compressed
                }

                setImporting(false, sideProfile: sideProfile)

                importMessage = sideProfile
                    ? "Side profile loaded. Add the front capture to continue."
                    : "Front capture loaded. Add the side profile to continue."

                if canStartScan {
                    importMessage = "Both captures are loaded. Swipe to begin the scan."
                }
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
        guard canStartScan,
              let frontData,
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

        processingTask = Task { @MainActor in
            do {
                try await animateProgress(to: 8, duration: 0.45)
                try await animateProgress(to: 16, duration: 0.40)
                try await animateProgress(to: 28, duration: 0.55)
                try await animateProgress(to: 40, duration: 0.55)
                try await animateProgress(to: 55, duration: 0.65)
                try await animateProgress(to: 70, duration: 0.65)
                try await animateProgress(to: 82, duration: 0.55)
                try await animateProgress(to: 92, duration: 0.50)
                try await animateProgress(to: 98, duration: 0.45)

                let result = try makeResult(
                    frontData: frontData,
                    sideData: sideData,
                    accessLevel: accessLevel,
                    email: email
                )

                try await animateProgress(to: 100, duration: 0.24)

                generatedResult = result
                phase = .results
                processingTask = nil
            } catch is CancellationError {
                processingTask = nil
            } catch {
                importMessage = "The scan could not be prepared right now. Please try again."
                phase = .capture
                processingTask = nil
            }
        }
    }

    private func cancelProcessing() {
        processingTask?.cancel()
        processingTask = nil
        phase = .capture
        progress = 0
        importMessage = "Scan cancelled before results were generated."
    }

    private func resetToCapture() {
        generatedResult = nil
        progress = 0
        phase = .capture
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

    private func makeResult(
        frontData: Data,
        sideData: Data,
        accessLevel: ScanResultsAccess,
        email: String?
    ) throws -> PersistedScanRecord {
        let frontURL = try ScanCaptureAssetStore.store(data: frontData, prefix: "front")
        let sideURL = try ScanCaptureAssetStore.store(data: sideData, prefix: "side")

        var result = accessLevel == .premium
            ? PersistedScanRecord.previewPremium
            : PersistedScanRecord.previewFree

        let scoreOffset = Double(((frontData.count % 11) + (sideData.count % 9)) % 7) - 3
        let overall = clamp(result.overallScore + (scoreOffset * 0.8), min: 54, max: 94)
        let potential = clamp(overall + 8 + Double(sideData.count % 3), min: overall + 4, max: 97)
        let eyes = clamp(overall + 2 - Double(frontData.count % 5), min: 48, max: 96)
        let skin = clamp(overall - 3 + Double(frontData.count % 4), min: 44, max: 94)
        let jaw = clamp(overall + Double(sideData.count % 4), min: 48, max: 96)
        let side = clamp(overall + 1 - Double(sideData.count % 3), min: 46, max: 95)

        result.payload.scores.overall = overall
        result.payload.scores.potential = potential
        result.payload.scores.eyes = eyes
        result.payload.scores.skin = skin
        result.payload.scores.jaw = jaw
        result.payload.scores.side = side

        result.meta.frontUrl = frontURL.absoluteString
        result.meta.sideUrl = sideURL.absoluteString
        result.meta.email = email
        result.meta.type = accessLevel.rawValue
        result.meta.scanId = nil
        result.meta.source = "scan-flow"
        result.savedAt = .now

        return result
    }

    private func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(max, value))
    }
}

private extension ScanCaptureFlowView {
    enum Phase {
        case capture
        case processing
        case results
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
        case ..<8:
            .init(label: "Booting", subtitle: "Initializing secure scan session...")
        case ..<16:
            .init(label: "Loading Models", subtitle: "Loading large analysis models...")
        case ..<28:
            .init(label: "Optimizing Photos", subtitle: "Enhancing lighting and alignment...")
        case ..<40:
            .init(label: "Uploading", subtitle: "Preparing inputs for the guided read...")
        case ..<55:
            .init(label: "Face Detection", subtitle: "Locating key facial regions...")
        case ..<70:
            .init(label: "Landmarks", subtitle: "Mapping precision points across both angles...")
        case ..<82:
            .init(label: "Feature Analysis", subtitle: "Measuring symmetry and structure...")
        case ..<92:
            .init(label: "Detail Pass", subtitle: "Refining skin and shape reads...")
        case ..<98:
            .init(label: "Scoring", subtitle: "Generating your personalized breakdown...")
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

                        Text("We run the full guided scan sequence before reveal so the result feels like a deliberate flow instead of a raw dump.")
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
                            ScanProcessingStepChip(done: clampedProgress >= 15, label: "Models loaded")
                            ScanProcessingStepChip(done: clampedProgress >= 55, label: "Landmarks mapped")
                            ScanProcessingStepChip(done: clampedProgress >= 82, label: "Feature scoring")
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
