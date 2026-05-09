//
//  FoodScannerView.swift
//  AIscend
//

import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct FoodScannerView: View {
    @ObservedObject var store: NutritionStore
    let onDismiss: () -> Void

    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCameraCapture = false
    @State private var cameraAlert: FoodScannerCameraAlert?
    @State private var phase: FoodScannerPhase = .idle
    @State private var scanProgress = 0.0
    @State private var pulse = false

    private let analysisEngine = NutritionAnalysisEngine()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AIscendBackdrop()
                DashboardAmbientLayer()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                        topBar(topInset: geometry.safeAreaInsets.top)
                        heroHeader
                        scanStage
                        scannerActions

                        switch phase {
                        case .idle:
                            scannerBrief
                        case .analyzing:
                            premiumLoadingState
                        case .completed(let result):
                            DashboardGlassCard(tone: .premium) {
                                MealAnalysisResultView(
                                    result: result,
                                    onLogMeal: {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        store.addMeal(result.mealEntry)
                                        onDismiss()
                                    },
                                    onScanAgain: resetScanner
                                )
                            }
                        case .failed(let message):
                            failureState(message: message)
                        }
                    }
                    .frame(maxWidth: 620)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                    .padding(.top, AIscendTheme.Spacing.small)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 56)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task { await importPhoto(from: newItem) }
        }
        .fullScreenCover(isPresented: $showingCameraCapture) {
            AIscendEditedCameraPicker(
                preferredCameraDevice: .rear,
                onImagePicked: { image in
                    showingCameraCapture = false
                    selectedImage = image
                    Task { await analyze(image: image) }
                },
                onCancel: {
                    showingCameraCapture = false
                }
            )
            .ignoresSafeArea()
        }
        .alert(item: $cameraAlert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
    }

    private func topBar(topInset: CGFloat) -> some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(AIscendTheme.Colors.surfaceGlass))
                    .overlay(Circle().stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            AIscendBadge(title: "Food Scanner", symbol: "camera.viewfinder", style: .accent)
        }
        .padding(.top, topInset + AIscendTheme.Spacing.small)
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text("AI food intelligence")
                .aiscendTextStyle(.eyebrow, color: AIscendTheme.Colors.accentGlow)
            Text("Scan the meal. Read the face impact.")
                .font(.system(size: 36, weight: .bold, design: .default))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Calories, macros, sodium, sugar, hydration, and inflammation risk are converted into aesthetic guidance in one pass.")
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var scanStage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceMuted.opacity(0.92))

            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                FoodScannerPlaceholder(pulse: pulse)
            }

            FoodScanOverlay(
                isScanning: phase.isAnalyzing,
                progress: scanProgress,
                labels: activeLabels
            )

            if case .analyzing = phase {
                VStack {
                    Spacer()
                    scanStatusRibbon
                }
                .padding(AIscendTheme.Spacing.medium)
            }
        }
        .frame(height: 430)
        .clipShape(RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
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
        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.20), radius: 28, x: 0, y: 18)
    }

    private var activeLabels: [FoodScanOverlayLabel] {
        if case .completed(let result) = phase {
            return result.detectedItems.map {
                FoodScanOverlayLabel(
                    title: $0.name,
                    confidence: $0.confidence,
                    x: $0.region.x + ($0.region.width * 0.5),
                    y: max(0.12, $0.region.y)
                )
            }
        }

        if phase.isAnalyzing {
            return [
                FoodScanOverlayLabel(title: "Food map", confidence: 0.78, x: 0.24, y: 0.22),
                FoodScanOverlayLabel(title: "Macro estimate", confidence: 0.71, x: 0.68, y: 0.38),
                FoodScanOverlayLabel(title: "Face impact", confidence: 0.84, x: 0.44, y: 0.64)
            ]
        }

        return []
    }

    private var scanStatusRibbon: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack {
                Text("Analyzing meal")
                    .aiscendTextStyle(.buttonLabel)
                Spacer()
                Text("\(Int(scanProgress * 100))%")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                    .monospacedDigit()
            }

            GeometryReader { proxy in
                Capsule(style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight)
                    .overlay(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [AIscendTheme.Colors.accentGlow, AIscendTheme.Colors.accentMint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: proxy.size.width * scanProgress)
                    }
            }
            .frame(height: 8)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
        )
    }

    private var scannerActions: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Button(action: startCameraCapture) {
                AIscendButtonLabel(title: selectedImage == nil ? "Take Photo" : "Retake", leadingSymbol: "camera.fill")
            }
            .buttonStyle(AIscendButtonStyle(variant: .primary))

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                AIscendButtonLabel(title: "Upload", leadingSymbol: "photo.on.rectangle.angled")
            }
            .buttonStyle(AIscendButtonStyle(variant: .secondary))
        }
    }

    private var scannerBrief: some View {
        DashboardGlassCard(tone: .subtle) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendSectionHeader(
                    eyebrow: "Pipeline Ready",
                    title: "Built for the next intelligence layer",
                    subtitle: "The scanner is structured for Vision, Core ML, OpenAI image analysis, nutrition APIs, barcode scanning, meal memory, and recommendations."
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                    pipelineChip("Food detection", "viewfinder")
                    pipelineChip("Macro read", "chart.pie.fill")
                    pipelineChip("Sodium risk", "saltshaker.fill")
                    pipelineChip("Face impact", "sparkles")
                }

                Button {
                    Task { await analyze(image: nil) }
                } label: {
                    AIscendButtonLabel(title: "Run Demo Scan", leadingSymbol: "sparkles")
                }
                .buttonStyle(AIscendButtonStyle(variant: .ghost))
            }
        }
    }

    private var premiumLoadingState: some View {
        DashboardGlassCard(tone: .premium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendSectionHeader(
                    eyebrow: "AI Inference",
                    title: "Building nutrition read",
                    subtitle: "Segmenting food, estimating macros, then translating the meal into facial-aesthetic impact."
                )

                loadingStep(title: "Detecting food items", progress: min(1, scanProgress * 1.4), symbol: "viewfinder")
                loadingStep(title: "Estimating calories and macros", progress: max(0, min(1, (scanProgress - 0.22) * 1.45)), symbol: "chart.pie.fill")
                loadingStep(title: "Modeling sodium, sugar, and hydration", progress: max(0, min(1, (scanProgress - 0.44) * 1.55)), symbol: "drop.triangle.fill")
                loadingStep(title: "Generating face-impact insights", progress: max(0, min(1, (scanProgress - 0.64) * 1.7)), symbol: "sparkles")
            }
            .redacted(reason: scanProgress < 0.12 ? .placeholder : [])
        }
    }

    private func failureState(message: String) -> some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendIconOrb(symbol: "exclamationmark.triangle.fill", accent: .dawn, size: 48)
                Text("Scan could not finish")
                    .aiscendTextStyle(.cardTitle)
                Text(message)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                Button(action: resetScanner) {
                    AIscendButtonLabel(title: "Try Again", leadingSymbol: "arrow.clockwise")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
            }
        }
    }

    private func pipelineChip(_ title: String, _ symbol: String) -> some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: symbol)
                .foregroundStyle(AIscendTheme.Colors.accentGlow)
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.58))
        )
    }

    private func loadingStep(title: String, progress: Double, symbol: String) -> some View {
        HStack(spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: symbol, accent: .mint, size: 38)
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                HStack {
                    Text(title)
                        .aiscendTextStyle(.buttonLabel)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        .monospacedDigit()
                }

                GeometryReader { proxy in
                    Capsule(style: .continuous)
                        .fill(AIscendTheme.Colors.surfaceHighlight)
                        .overlay(alignment: .leading) {
                            Capsule(style: .continuous)
                                .fill(AIscendTheme.Colors.accentGlow)
                                .frame(width: proxy.size.width * progress)
                        }
                }
                .frame(height: 7)
            }
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.48))
        )
    }

    private func importPhoto(from item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                await MainActor.run {
                    phase = .failed("That image format could not be loaded.")
                }
                return
            }

            await MainActor.run {
                selectedImage = image
            }
            await analyze(image: image)
        } catch {
            await MainActor.run {
                phase = .failed("The selected image could not be imported.")
            }
        }
    }

    private func analyze(image: UIImage?) async {
        await MainActor.run {
            phase = .analyzing
            scanProgress = 0
        }

        let progressTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 80_000_000)
                await MainActor.run {
                    scanProgress = min(0.94, scanProgress + 0.035)
                }
            }
        }

        do {
            let result = try await analysisEngine.analyzeMealImage(image)
            progressTask.cancel()
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.28)) {
                    scanProgress = 1
                    phase = .completed(result)
                }
            }
        } catch {
            progressTask.cancel()
            await MainActor.run {
                phase = .failed("AIScend could not analyze this meal image.")
            }
        }
    }

    private func startCameraCapture() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            cameraAlert = .unavailable
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingCameraCapture = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingCameraCapture = true
                    } else {
                        cameraAlert = .denied
                    }
                }
            }
        case .denied, .restricted:
            cameraAlert = .denied
        @unknown default:
            cameraAlert = .unavailable
        }
    }

    private func resetScanner() {
        withAnimation(AIscendTheme.Motion.reveal) {
            selectedImage = nil
            selectedPhotoItem = nil
            scanProgress = 0
            phase = .idle
        }
    }
}

private enum FoodScannerPhase {
    case idle
    case analyzing
    case completed(MealAnalysisResult)
    case failed(String)

    var isAnalyzing: Bool {
        if case .analyzing = self {
            return true
        }
        return false
    }
}

private enum FoodScannerCameraAlert: Identifiable {
    case unavailable
    case denied

    var id: String {
        switch self {
        case .unavailable:
            return "unavailable"
        case .denied:
            return "denied"
        }
    }

    var title: String {
        switch self {
        case .unavailable:
            return "Camera unavailable"
        case .denied:
            return "Camera access needed"
        }
    }

    var message: String {
        switch self {
        case .unavailable:
            return "This device does not have an available camera for food scanning."
        case .denied:
            return "Allow camera access in Settings to scan meals without leaving AIScend."
        }
    }
}

private struct FoodScanOverlayLabel: Identifiable {
    let id = UUID()
    var title: String
    var confidence: Double
    var x: Double
    var y: Double
}

private struct FoodScanOverlay: View {
    let isScanning: Bool
    let progress: Double
    let labels: [FoodScanOverlayLabel]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                scanGrid
                scanCorners

                if isScanning {
                    scanLine(in: geometry.size)
                }

                ForEach(labels) { label in
                    overlayLabel(label)
                        .position(
                            x: geometry.size.width * min(0.88, max(0.12, label.x)),
                            y: geometry.size.height * min(0.82, max(0.14, label.y))
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
        }
    }

    private var scanGrid: some View {
        Canvas { context, size in
            var path = Path()
            let columns = 6
            let rows = 8

            for index in 1..<columns {
                let x = size.width * CGFloat(index) / CGFloat(columns)
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }

            for index in 1..<rows {
                let y = size.height * CGFloat(index) / CGFloat(rows)
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }

            context.stroke(path, with: .color(AIscendTheme.Colors.accentGlow.opacity(0.075)), lineWidth: 1)
        }
        .blendMode(.screen)
    }

    private var scanCorners: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let length: CGFloat = 48
            let inset: CGFloat = 20

            Path { path in
                path.move(to: CGPoint(x: inset, y: inset + length))
                path.addLine(to: CGPoint(x: inset, y: inset))
                path.addLine(to: CGPoint(x: inset + length, y: inset))

                path.move(to: CGPoint(x: width - inset - length, y: inset))
                path.addLine(to: CGPoint(x: width - inset, y: inset))
                path.addLine(to: CGPoint(x: width - inset, y: inset + length))

                path.move(to: CGPoint(x: inset, y: height - inset - length))
                path.addLine(to: CGPoint(x: inset, y: height - inset))
                path.addLine(to: CGPoint(x: inset + length, y: height - inset))

                path.move(to: CGPoint(x: width - inset - length, y: height - inset))
                path.addLine(to: CGPoint(x: width - inset, y: height - inset))
                path.addLine(to: CGPoint(x: width - inset, y: height - inset - length))
            }
            .stroke(AIscendTheme.Colors.accentGlow.opacity(0.82), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.42), radius: 12, x: 0, y: 0)
        }
    }

    private func scanLine(in size: CGSize) -> some View {
        let y = size.height * min(0.96, max(0.04, progress))

        return Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, AIscendTheme.Colors.accentGlow, AIscendTheme.Colors.accentMint, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 3)
            .position(x: size.width / 2, y: y)
            .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.86), radius: 18, x: 0, y: 0)
    }

    private func overlayLabel(_ label: FoodScanOverlayLabel) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(AIscendTheme.Colors.accentMint)
                .frame(width: 7, height: 7)
                .shadow(color: AIscendTheme.Colors.accentMint.opacity(0.8), radius: 8, x: 0, y: 0)
            VStack(alignment: .leading, spacing: 1) {
                Text(label.title)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
                Text("\(Int(label.confidence * 100))% lock")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)
                    .monospacedDigit()
            }
        }
        .foregroundStyle(AIscendTheme.Colors.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .overlay(Capsule(style: .continuous).stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1))
    }
}

private struct FoodScannerPlaceholder: View {
    let pulse: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.cardGradientStart,
                    AIscendTheme.Colors.accentDeep.opacity(0.66),
                    AIscendTheme.Colors.cardGradientEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AIscendTheme.Colors.accentGlow.opacity(pulse ? 0.24 : 0.12))
                .blur(radius: 44)
                .frame(width: 230, height: 230)
                .offset(x: 70, y: -80)

            VStack(spacing: AIscendTheme.Spacing.medium) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.7), radius: 22, x: 0, y: 0)

                Text("Frame the meal")
                    .aiscendTextStyle(.cardTitle)
                Text("Camera or upload starts the AI scan.")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }
        }
    }
}
