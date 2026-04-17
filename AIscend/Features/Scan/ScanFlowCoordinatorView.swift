//
//  ScanFlowCoordinatorView.swift
//  AIscend
//

import PhotosUI
import SwiftUI
import UIKit

struct ScanFlowCoordinatorView: View {
    let session: AuthSessionStore
    let onOpenRoutine: () -> Void
    let onOpenChat: () -> Void
    let onReturnHome: () -> Void
    let onDismiss: () -> Void

    @ObservedObject private var badgeManager: BadgeManager
    @ObservedObject private var dailyCheckInStore: DailyCheckInStore
    @ObservedObject private var notificationManager: NotificationManager
    private let analysisService: ScanAnalysisServiceProtocol

    @State private var step: Step = .front
    @State private var frontImage: UIImage?
    @State private var frontData: Data?
    @State private var sideImage: UIImage?
    @State private var sideData: Data?

    @State private var progress: Double = 0
    @State private var processingTask: Task<Void, Never>?
    @State private var generatedResult: PersistedScanRecord?
    @State private var errorMessage: String?

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
        NavigationStack {
            ZStack {
                AIscendBackdrop()
                DashboardAmbientLayer()

                content
            }
            .preferredColorScheme(.dark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .onDisappear {
            processingTask?.cancel()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .front:
            ScanCapturePageView(
                title: "Front Photo",
                subtitle: "Upload a clean front-facing photo.",
                image: frontImage,
                symbol: "person.crop.square",
                buttonTitle: frontImage == nil ? "Upload Front Photo" : "Replace Front Photo",
                stepTitle: "Step 1 of 3",
                onBack: nil,
                onClose: onDismiss,
                onPickImage: handleFrontImage,
                onContinue: frontImage == nil ? nil : {
                    step = .side
                },
                footnote: errorMessage
            )

        case .side:
            ScanCapturePageView(
                title: "Side Photo",
                subtitle: "Upload a clear side profile with the same lighting.",
                image: sideImage,
                symbol: "person.crop.rectangle",
                buttonTitle: sideImage == nil ? "Upload Side Photo" : "Replace Side Photo",
                stepTitle: "Step 2 of 3",
                onBack: {
                    step = .front
                },
                onClose: onDismiss,
                onPickImage: handleSideImage,
                onContinue: sideImage == nil ? nil : {
                    startProcessing()
                },
                footnote: errorMessage
            )

        case .processing:
            ScanProcessingExperience(
                progress: progress,
                onCancel: {
                    processingTask?.cancel()
                    processingTask = nil
                    step = .side
                }
            )

        case .results:
            ScanResultsFlowView(
                session: session,
                initialResult: generatedResult,
                badgeManager: badgeManager,
                dailyCheckInStore: dailyCheckInStore,
                notificationManager: notificationManager,
                onOpenScan: resetFlow,
                onOpenRoutine: onOpenRoutine,
                onOpenChat: onOpenChat,
                onReturnHome: onReturnHome,
                onDismiss: onDismiss
            )
        }
    }

    private var isPremiumUnlocked: Bool {
        badgeManager.earnedBadges.contains(where: { $0.id == .premiumUnlocked })
    }

    private func handleFrontImage(_ image: UIImage, _ data: Data) {
        frontImage = image
        frontData = data
        errorMessage = nil
    }

    private func handleSideImage(_ image: UIImage, _ data: Data) {
        sideImage = image
        sideData = data
        errorMessage = nil
    }

    private func startProcessing() {
        guard let frontData, let sideData else { return }

        let accessLevel: ScanResultsAccess = isPremiumUnlocked ? .premium : .free
        let email = session.user?.email
        let userID = session.user?.id

        generatedResult = nil
        errorMessage = nil
        progress = 0
        step = .processing
        processingTask?.cancel()

        processingTask = Task { @MainActor in
            do {
                try await animateProgress(to: 18, duration: 0.35)

                async let remoteResult = analysisService.analyze(
                    frontImageData: frontData,
                    sideImageData: sideData,
                    email: email,
                    userID: userID,
                    accessLevel: accessLevel
                )

                try await animateProgress(to: 45, duration: 0.45)
                try await animateProgress(to: 75, duration: 0.55)
                try await animateProgress(to: 92, duration: 0.55)

                let analyzedResult = try await remoteResult
                let finalResult = try finalizedResult(
                    analyzedResult,
                    frontData: frontData,
                    sideData: sideData,
                    email: email,
                    accessLevel: accessLevel
                )

                try await animateProgress(to: 100, duration: 0.20)

                generatedResult = finalResult
                processingTask = nil
                step = .results
            } catch is CancellationError {
                processingTask = nil
            } catch {
                processingTask = nil
                errorMessage = error.localizedDescription.isEmpty
                    ? "The scan could not be completed right now."
                    : error.localizedDescription
                step = .side
            }
        }
    }

    private func resetFlow() {
        frontImage = nil
        frontData = nil
        sideImage = nil
        sideData = nil
        generatedResult = nil
        errorMessage = nil
        progress = 0
        step = .front
    }

    private func animateProgress(to target: Double, duration: TimeInterval) async throws {
        let clampedTarget = max(progress, min(target, 100))
        let start = progress
        let tick: TimeInterval = 0.05
        let steps = max(Int(duration / tick), 1)

        for stepIndex in 1...steps {
            try Task.checkCancellation()
            let value = start + ((clampedTarget - start) * (Double(stepIndex) / Double(steps)))
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

private extension ScanFlowCoordinatorView {
    enum Step {
        case front
        case side
        case processing
        case results
    }
}