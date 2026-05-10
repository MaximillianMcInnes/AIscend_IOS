//
//  ScanCaptureFlowView.swift
//  AIscend
//

import SwiftUI
import UIKit

struct ScanCaptureFlowView: View {
    let session: AuthSessionStore
    let isPremium: Bool
    let onOpenRoutine: () -> Void
    let onOpenChat: () -> Void
    let onReturnHome: () -> Void
    let onDismiss: () -> Void

    @ObservedObject private var badgeManager: BadgeManager
    @ObservedObject private var dailyCheckInStore: DailyCheckInStore
    @ObservedObject private var notificationManager: NotificationManager

    @State private var frontPreview: UIImage?
    @State private var frontImageData: Data?
    @State private var sidePreview: UIImage?
    @State private var sideImageData: Data?
    @State private var showingResults = false
    @State private var scanResult: PersistedScanRecord?
    @State private var isAnalyzing = false
    @State private var scanErrorMessage: String?
    @State private var scanErrorAlert: ScanFlowErrorAlert?
    @State private var activeStep: ScanCaptureStep = .front

    private let scanAnalysisService: ScanAnalysisServiceProtocol

    init(
        session: AuthSessionStore,
        badgeManager: BadgeManager,
        dailyCheckInStore: DailyCheckInStore,
        notificationManager: NotificationManager,
        isPremium: Bool = false,
        scanAnalysisService: ScanAnalysisServiceProtocol = ScanAnalysisService(),
        onOpenRoutine: @escaping () -> Void = {},
        onOpenChat: @escaping () -> Void = {},
        onReturnHome: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void = {}
    ) {
        self.session = session
        self.isPremium = isPremium
        self.onOpenRoutine = onOpenRoutine
        self.onOpenChat = onOpenChat
        self.onReturnHome = onReturnHome
        self.onDismiss = onDismiss
        self.scanAnalysisService = scanAnalysisService
        self._badgeManager = ObservedObject(wrappedValue: badgeManager)
        self._dailyCheckInStore = ObservedObject(wrappedValue: dailyCheckInStore)
        self._notificationManager = ObservedObject(wrappedValue: notificationManager)
    }

    var body: some View {
        ZStack {
            if isAnalyzing {
                ScanAnalysisLoadingView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                activeCaptureStepPage
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .animation(.smooth(duration: 0.26), value: activeStep)
        .animation(.easeInOut(duration: 0.24), value: isAnalyzing)
        .preferredColorScheme(ColorScheme.dark)
        .alert(item: $scanErrorAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("Got it"))
            )
        }
        .fullScreenCover(isPresented: $showingResults) {
            ScanResultsFlowView(
                session: session,
                initialResult: scanResult,
                badgeManager: badgeManager,
                dailyCheckInStore: dailyCheckInStore,
                notificationManager: notificationManager,
                onOpenScan: {
                    showingResults = false
                },
                onOpenRoutine: onOpenRoutine,
                onOpenChat: onOpenChat,
                onReturnHome: onReturnHome,
                onDismiss: {
                    showingResults = false
                    onDismiss()
                }
            )
        }
    }

    @ViewBuilder
    private var activeCaptureStepPage: some View {
        switch activeStep {
        case .front:
            ScanCapturePageView(
                title: "Upload front selfie",
                subtitle: "Take the photo in AIScend or upload a clear front-facing image. Keep your face centered, relaxed, and evenly lit.",
                image: frontPreview,
                symbol: "face.smiling",
                guide: .front,
                buttonTitle: frontPreview == nil ? "Upload Photo" : "Replace Upload",
                stepTitle: "Step 1 of 2",
                onBack: nil,
                onClose: onDismiss,
                onPickImage: { image, data in
                    updateImage(image, data: data, slot: .front)
                },
                onContinue: frontImageData == nil ? nil : {
                    withAnimation(.smooth(duration: 0.24)) {
                        activeStep = .side
                    }
                },
                footnote: nil
            )

        case .side:
            ScanCapturePageView(
                title: "Upload side profile",
                subtitle: "Turn sideways for a clean profile. Keep your jaw, chin, neck, and forehead visible inside the guide.",
                image: sidePreview,
                symbol: "person.crop.square",
                guide: .side,
                buttonTitle: sidePreview == nil ? "Upload Photo" : "Replace Upload",
                stepTitle: "Step 2 of 2",
                onBack: {
                    withAnimation(.smooth(duration: 0.24)) {
                        activeStep = .front
                    }
                },
                onClose: onDismiss,
                onPickImage: { image, data in
                    updateImage(image, data: data, slot: .side)
                },
                onContinue: sideImageData == nil ? nil : {
                    Task {
                        await analyzeScan()
                    }
                },
                footnote: scanErrorMessage
            )
        }
    }

    private func updateImage(_ image: UIImage?, data: Data?, slot: ScanCaptureImageSlot) {
        scanResult = nil
        scanErrorMessage = nil

        switch slot {
        case .front:
            frontPreview = image
            frontImageData = data
        case .side:
            sidePreview = image
            sideImageData = data
        }
    }

    @MainActor
    private func analyzeScan() async {
        guard let frontImageData, let sideImageData else {
            presentScanError(
                title: "Photos needed",
                message: "Select both a front selfie and a side-profile photo before running the scan."
            )
            return
        }

        isAnalyzing = true
        scanErrorMessage = nil

        do {
            scanResult = try await scanAnalysisService.analyze(
                frontImageData: frontImageData,
                sideImageData: sideImageData,
                email: session.user?.email,
                userID: session.user?.id,
                isPremium: isPremium
            )
            showingResults = true
        } catch {
            presentScanError(error)
        }

        isAnalyzing = false
    }

    private func presentScanError(_ error: Error) {
        let title: String
        let message: String

        if let scanError = error as? ScanAnalysisError {
            title = scanError.alertTitle
            message = [scanError.errorDescription, scanError.recoverySuggestion]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty }
                .joined(separator: "\n\n")
        } else {
            title = "Scan failed"
            message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                ?? "AIScend could not finish the scan. Please try again."
        }

        presentScanError(title: title, message: message)
    }

    private func presentScanError(title: String, message: String) {
        scanErrorMessage = message
        scanErrorAlert = ScanFlowErrorAlert(title: title, message: message)
    }
}

private enum ScanCaptureStep {
    case front
    case side
}

private enum ScanCaptureImageSlot {
    case front
    case side
}

private struct ScanFlowErrorAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct ScanAnalysisLoadingView: View {
    private let estimatedDuration: TimeInterval = 180
    private let steps = ScanAnalysisStep.defaultSteps

    @State private var startedAt = Date()
    @State private var pulse = false
    @State private var orbit = false

    var body: some View {
        TimelineView(.periodic(from: startedAt, by: 1)) { context in
            let elapsed = max(0, context.date.timeIntervalSince(startedAt))
            let progress = min(elapsed / estimatedDuration, 0.98)
            let remaining = max(0, Int(ceil(estimatedDuration - elapsed)))

            ZStack {
                AIscendBackdrop()
                DashboardAmbientLayer()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AIscendTheme.Spacing.large) {
                        ScanAnalysisCoreGraphic(progress: progress, pulse: pulse, orbit: orbit)

                        VStack(spacing: AIscendTheme.Spacing.small) {
                            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                                Image(systemName: "cpu.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Scan engine")
                                    .aiscendTextStyle(.eyebrow, color: AIscendTheme.Colors.accentGlow)
                            }

                            Text("Building your scan")
                                .font(.system(size: 31, weight: .bold, design: .rounded))
                                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                                .multilineTextAlignment(.center)

                            Text("We are aligning your uploads, mapping facial landmarks, and running the structure model before the reveal opens.")
                                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        ScanAnalysisProgressPanel(
                            progress: progress,
                            remainingSeconds: remaining,
                            steps: steps
                        )
                    }
                    .padding(.horizontal, AIscendTheme.Spacing.large)
                    .padding(.vertical, AIscendTheme.Spacing.xLarge)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .onAppear {
            startedAt = Date()

            withAnimation(.easeInOut(duration: 1.18).repeatForever(autoreverses: true)) {
                pulse = true
            }

            withAnimation(.linear(duration: 1.65).repeatForever(autoreverses: false)) {
                orbit = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Building your scan")
    }
}

private struct ScanAnalysisCoreGraphic: View {
    let progress: Double
    let pulse: Bool
    let orbit: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.surfaceHighlight.opacity(0.92),
                            AIscendTheme.Colors.surfaceGlass.opacity(0.72),
                            AIscendTheme.Colors.accentDeep.opacity(0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.borderStrong,
                                    AIscendTheme.Colors.accentGlow.opacity(0.42),
                                    AIscendTheme.Colors.borderSubtle
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            VStack(spacing: AIscendTheme.Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(AIscendTheme.Colors.accentPrimary.opacity(0.12))
                        .frame(width: 168, height: 168)
                        .scaleEffect(pulse ? 1.05 : 0.94)

                    Circle()
                        .stroke(AIscendTheme.Colors.accentGlow.opacity(0.20), lineWidth: 16)
                        .frame(width: 162, height: 162)
                        .scaleEffect(pulse ? 1.14 : 0.90)
                        .opacity(pulse ? 0.20 : 0.72)

                    Circle()
                        .trim(from: 0.06, to: 0.78)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentGlow,
                                    AIscendTheme.Colors.accentCyan,
                                    AIscendTheme.Colors.accentMint
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 138, height: 138)
                        .rotationEffect(.degrees(orbit ? 360 : 0))
                        .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.30), radius: 18, x: 0, y: 10)

                    ScanFaceMap(progress: progress)
                        .frame(width: 124, height: 124)
                }

                HStack(spacing: AIscendTheme.Spacing.small) {
                    ScanSignalPill(title: "Front", value: "locked", symbol: "checkmark.seal.fill", accent: .mint)
                    ScanSignalPill(title: "Side", value: "aligned", symbol: "viewfinder", accent: .sky)
                    ScanSignalPill(title: "Model", value: "active", symbol: "waveform.path.ecg", accent: .dawn)
                }
            }
            .padding(AIscendTheme.Spacing.large)
        }
        .frame(maxWidth: 360)
        .fixedSize(horizontal: false, vertical: true)
        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.20), radius: 26, x: 0, y: 18)
    }
}

private struct ScanFaceMap: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let scanY = size * (0.16 + (0.68 * progress))

            ZStack {
                Image(systemName: "face.smiling.inverse")
                    .font(.system(size: size * 0.55, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .symbolRenderingMode(.hierarchical)

                ForEach(ScanLandmarkPoint.points, id: \.id) { point in
                    Circle()
                        .fill(point.isPrimary ? AIscendTheme.Colors.accentGlow : AIscendTheme.Colors.accentCyan)
                        .frame(width: point.isPrimary ? 6 : 4, height: point.isPrimary ? 6 : 4)
                        .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.46), radius: 6, x: 0, y: 0)
                        .position(x: size * point.x, y: size * point.y)
                        .opacity(progress > point.revealThreshold ? 1 : 0.18)
                }

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                AIscendTheme.Colors.accentGlow.opacity(0.86),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: size * 0.82, height: 3)
                    .position(x: size * 0.5, y: min(size * 0.86, scanY))
            }
            .frame(width: size, height: size)
        }
    }
}

private struct ScanAnalysisProgressPanel: View {
    let progress: Double
    let remainingSeconds: Int
    let steps: [ScanAnalysisStep]

    private var activeIndex: Int {
        min(steps.count - 1, max(0, Int(floor(progress * Double(steps.count)))))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text("Analysis queue")
                        .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                    Text("ETA \(formattedETA)")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                }

                Spacer(minLength: AIscendTheme.Spacing.small)

                Text("\(Int((progress * 100).rounded()))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AIscendTheme.Colors.surfaceMuted.opacity(0.82))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentGlow,
                                    AIscendTheme.Colors.accentCyan,
                                    AIscendTheme.Colors.accentMint
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(16, proxy.size.width * progress))
                        .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.32), radius: 12, x: 0, y: 0)
                }
            }
            .frame(height: 10)

            VStack(spacing: AIscendTheme.Spacing.xSmall) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    ScanLoadingStep(
                        step: step,
                        state: state(for: index),
                        progress: rowProgress(for: index)
                    )
                }
            }
        }
        .padding(AIscendTheme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceGlass.opacity(0.86))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private var formattedETA: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    private func state(for index: Int) -> ScanLoadingStepState {
        if index < activeIndex {
            return .complete
        }

        if index == activeIndex {
            return .active
        }

        return .pending
    }

    private func rowProgress(for index: Int) -> Double {
        let scaled = progress * Double(steps.count)
        return min(1, max(0, scaled - Double(index)))
    }
}

private struct ScanLoadingStep: View {
    let step: ScanAnalysisStep
    let state: ScanLoadingStepState
    let progress: Double

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            ZStack {
                Circle()
                    .fill(state.background)
                Image(systemName: state.symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(state.tint)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                HStack(spacing: AIscendTheme.Spacing.xSmall) {
                    Text(step.title)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)

                    Spacer(minLength: 0)

                    Text(state.label)
                        .aiscendTextStyle(.eyebrow, color: state.tint)
                        .monospacedDigit()
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AIscendTheme.Colors.surfaceMuted.opacity(0.62))
                        Capsule()
                            .fill(state.tint.opacity(state == .pending ? 0.20 : 0.92))
                            .frame(width: max(state == .pending ? 0 : 6, proxy.size.width * progress))
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, AIscendTheme.Spacing.xSmall)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(state == .active ? AIscendTheme.Colors.surfaceHighlight.opacity(0.46) : .clear)
        )
    }
}

private struct ScanSignalPill: View {
    let title: String
    let value: String
    let symbol: String
    let accent: RoutineAccent

    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.xxSmall) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(accent.tint)
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            Text(value)
                .aiscendTextStyle(.eyebrow, color: AIscendTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceGlass.opacity(0.64))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent.tint.opacity(0.24), lineWidth: 1)
        )
    }
}

private struct ScanAnalysisStep: Identifiable {
    let id: String
    let title: String

    static let defaultSteps: [ScanAnalysisStep] = [
        ScanAnalysisStep(id: "load-model", title: "Loading facial model"),
        ScanAnalysisStep(id: "capture-geometry", title: "Validating capture geometry"),
        ScanAnalysisStep(id: "landmarks", title: "Landmarking your face"),
        ScanAnalysisStep(id: "normalization", title: "Normalizing front and side profiles"),
        ScanAnalysisStep(id: "calculations", title: "Running proportion calculations"),
        ScanAnalysisStep(id: "taylor-pass", title: "Running Taylor-based model pass"),
        ScanAnalysisStep(id: "signal-check", title: "Checking symmetry and structure signals"),
        ScanAnalysisStep(id: "report", title: "Preparing your result")
    ]
}

private enum ScanLoadingStepState {
    case complete
    case active
    case pending

    var symbol: String {
        switch self {
        case .complete:
            return "checkmark"
        case .active:
            return "waveform.path.ecg"
        case .pending:
            return "circle"
        }
    }

    var label: String {
        switch self {
        case .complete:
            return "done"
        case .active:
            return "running"
        case .pending:
            return "queued"
        }
    }

    var tint: Color {
        switch self {
        case .complete:
            return AIscendTheme.Colors.success
        case .active:
            return AIscendTheme.Colors.accentGlow
        case .pending:
            return AIscendTheme.Colors.textMuted
        }
    }

    var background: Color {
        switch self {
        case .complete:
            return AIscendTheme.Colors.success.opacity(0.16)
        case .active:
            return AIscendTheme.Colors.accentGlow.opacity(0.18)
        case .pending:
            return AIscendTheme.Colors.surfaceMuted.opacity(0.76)
        }
    }
}

private struct ScanLandmarkPoint: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let isPrimary: Bool
    let revealThreshold: Double

    static let points: [ScanLandmarkPoint] = [
        ScanLandmarkPoint(id: 0, x: 0.35, y: 0.35, isPrimary: true, revealThreshold: 0.05),
        ScanLandmarkPoint(id: 1, x: 0.65, y: 0.35, isPrimary: true, revealThreshold: 0.08),
        ScanLandmarkPoint(id: 2, x: 0.50, y: 0.48, isPrimary: false, revealThreshold: 0.18),
        ScanLandmarkPoint(id: 3, x: 0.38, y: 0.58, isPrimary: false, revealThreshold: 0.28),
        ScanLandmarkPoint(id: 4, x: 0.62, y: 0.58, isPrimary: false, revealThreshold: 0.34),
        ScanLandmarkPoint(id: 5, x: 0.50, y: 0.68, isPrimary: true, revealThreshold: 0.42),
        ScanLandmarkPoint(id: 6, x: 0.28, y: 0.50, isPrimary: false, revealThreshold: 0.52),
        ScanLandmarkPoint(id: 7, x: 0.72, y: 0.50, isPrimary: false, revealThreshold: 0.58),
        ScanLandmarkPoint(id: 8, x: 0.42, y: 0.76, isPrimary: false, revealThreshold: 0.68),
        ScanLandmarkPoint(id: 9, x: 0.58, y: 0.76, isPrimary: false, revealThreshold: 0.74)
    ]
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
