//
//  ScanCaptureFlowView.swift
//  AIscend
//

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

    @State private var frontPreview: UIImage?
    @State private var frontImageData: Data?
    @State private var sidePreview: UIImage?
    @State private var sideImageData: Data?
    @State private var showingResults = false
    @State private var scanResult: PersistedScanRecord?
    @State private var isAnalyzing = false
    @State private var scanErrorMessage: String?
    @State private var activeStep: ScanCaptureStep = .front

    private let scanAnalysisService: ScanAnalysisServiceProtocol

    init(
        session: AuthSessionStore,
        badgeManager: BadgeManager,
        dailyCheckInStore: DailyCheckInStore,
        notificationManager: NotificationManager,
        scanAnalysisService: ScanAnalysisServiceProtocol = ScanAnalysisService(),
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
            scanErrorMessage = "Select both photos before running the scan."
            return
        }

        isAnalyzing = true
        scanErrorMessage = nil

        do {
            scanResult = try await scanAnalysisService.analyze(
                frontImageData: frontImageData,
                sideImageData: sideImageData,
                email: session.user?.email,
                userID: session.user?.id
            )
            showingResults = true
        } catch {
            scanErrorMessage = error.localizedDescription
        }

        isAnalyzing = false
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

private struct ScanAnalysisLoadingView: View {
    @State private var pulse = false
    @State private var orbit = false

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            VStack(spacing: AIscendTheme.Spacing.xLarge) {
                ZStack {
                    Circle()
                        .stroke(AIscendTheme.Colors.accentGlow.opacity(0.16), lineWidth: 18)
                        .frame(width: 176, height: 176)
                        .scaleEffect(pulse ? 1.12 : 0.86)
                        .opacity(pulse ? 0.22 : 0.72)

                    Circle()
                        .trim(from: 0.08, to: 0.78)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentGlow,
                                    AIscendTheme.Colors.accentCyan,
                                    AIscendTheme.Colors.accentSoft
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 148, height: 148)
                        .rotationEffect(.degrees(orbit ? 360 : 0))
                        .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.35), radius: 20, x: 0, y: 12)

                    Image(systemName: "face.smiling.inverse")
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(spacing: AIscendTheme.Spacing.small) {
                    Text("Building your scan")
                        .font(.system(size: 31, weight: .bold, design: .rounded))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Aligning the front and side photos, reading facial structure, and preparing your result.")
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: AIscendTheme.Spacing.small) {
                    ScanLoadingStep(title: "Front profile locked", symbol: "checkmark.circle.fill", isComplete: true)
                    ScanLoadingStep(title: "Side profile aligned", symbol: "checkmark.circle.fill", isComplete: true)
                    ScanLoadingStep(title: "Generating result", symbol: "sparkles", isComplete: false)
                }
                .padding(AIscendTheme.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(AIscendTheme.Colors.surfaceGlass.opacity(0.82))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                )
            }
            .padding(.horizontal, AIscendTheme.Spacing.xLarge)
            .frame(maxWidth: 560)
        }
        .onAppear {
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

private struct ScanLoadingStep: View {
    let title: String
    let symbol: String
    let isComplete: Bool

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isComplete ? AIscendTheme.Colors.success : AIscendTheme.Colors.accentGlow)
                .frame(width: 24, height: 24)

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)

            Spacer(minLength: 0)
        }
    }
}
