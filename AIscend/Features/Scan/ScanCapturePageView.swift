//
//  ScanCapturePageView.swift
//  AIscend
//

import AVFoundation
import Photos
import PhotosUI
import SwiftUI
import UIKit

struct ScanCapturePageView: View {
    @Environment(\.openURL) private var openURL

    let title: String
    let subtitle: String
    let image: UIImage?
    let symbol: String
    let guide: ScanCaptureGuide
    let buttonTitle: String
    let stepTitle: String
    let onBack: (() -> Void)?
    let onClose: () -> Void
    let onPickImage: (UIImage, Data) -> Void
    let onContinue: (() -> Void)?
    let footnote: String?

    @State private var pickerItem: PhotosPickerItem?
    @State private var isLoading = false
    @State private var showingCameraCapture = false
    @State private var cameraAlert: ScanPageCameraAlert?
    @State private var photoImportAlert: ScanPagePhotoImportAlert?

    private var canUseCamera: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AIscendBackdrop()
                DashboardAmbientLayer()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                        topBar(topInset: geometry.safeAreaInsets.top)
                        ScanCaptureProgressStrip(stepTitle: stepTitle, guide: guide, isReady: image != nil)

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                            AIscendSectionHeader(
                                eyebrow: guide.title,
                                title: title,
                                subtitle: subtitle,
                                prominence: .standard
                            )

                            ScanCaptureHeroFrame(
                                image: image,
                                guide: guide,
                                symbol: symbol,
                                isLoading: isLoading
                            )

                            ScanCaptureGuidanceChips(guide: guide)

                            ScanCaptureActionStack(
                                image: image,
                                buttonTitle: buttonTitle,
                                canUseCamera: canUseCamera,
                                pickerItem: $pickerItem,
                                onStartCamera: startCameraCapture,
                                onContinue: onContinue
                            )

                            if let footnote, !footnote.isEmpty {
                                ScanCaptureInlineError(message: footnote)
                            }
                        }
                        .padding(AIscendTheme.Spacing.mediumLarge)
                        .aiscendPanel(.elevated)
                        .accessibilityElement(children: .contain)
                    }
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, AIscendTheme.Spacing.large) + AIscendTheme.Spacing.large)
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showingCameraCapture) {
            AIscendEditedCameraPicker(
                preferredCameraDevice: .front,
                guide: guide,
                onImagePicked: { image in
                    showingCameraCapture = false
                    importCapturedPhoto(image)
                },
                onCancel: {
                    showingCameraCapture = false
                }
            )
            .ignoresSafeArea()
        }
        .alert(item: $cameraAlert) { alert in
            switch alert {
            case .unavailable:
                return Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )

            case .denied:
                return Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    primaryButton: .default(Text("Settings")) {
                        openAppSettings()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .alert(item: $photoImportAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("Got it"))
            )
        }
        .onChange(of: pickerItem) { _, newValue in
            guard let newValue else { return }
            Task {
                await importPhoto(from: newValue)
            }
        }
    }

    private func topBar(topInset: CGFloat) -> some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Button(action: onBack ?? onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(Color(hex: "10141B").opacity(0.88))
                            .overlay(Circle().fill(.ultraThinMaterial).opacity(0.50))
                    )
                    .overlay(
                        Circle()
                            .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("Face Scan")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                Text(stepTitle)
                    .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 0)

            if image != nil {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.success)
            }
        }
        .padding(.top, topInset + AIscendTheme.Spacing.small)
    }

    private func importPhoto(from item: PhotosPickerItem) async {
        await MainActor.run {
            isLoading = true
        }

        do {
            let preparedImage = try await ScanPhotoImportLoader.preparedScanImage(from: item)

            await MainActor.run {
                finishImport(image: preparedImage.image, data: preparedImage.data)
                pickerItem = nil
            }
        } catch {
            await MainActor.run {
                isLoading = false
                pickerItem = nil
                photoImportAlert = ScanPagePhotoImportAlert(error: error)
            }
        }
    }

    private func startCameraCapture() {
        guard canUseCamera else {
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

    private func importCapturedPhoto(_ image: UIImage) {
        isLoading = true

        Task {
            guard let preparedImage = await Task.detached(priority: .userInitiated, operation: {
                image.aiscendPreparedScanImage()
            }).value else {
                await MainActor.run {
                    isLoading = false
                }
                return
            }

            await MainActor.run {
                finishImport(image: preparedImage.image, data: preparedImage.data)
            }
        }
    }

    private func finishImport(image: UIImage, data: Data) {
        onPickImage(image, data)
        isLoading = false
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(url)
    }
}

private enum ScanPhotoImportLoader {
    static func preparedScanImage(from item: PhotosPickerItem) async throws -> (image: UIImage, data: Data) {
        let data = try await bestAvailableImageData(from: item)

        guard let preparedImage = await UIImage.aiscendPreparedScanImage(from: data) else {
            throw ScanPhotoImportError.unsupportedFormat
        }

        return preparedImage
    }

    private static func bestAvailableImageData(from item: PhotosPickerItem) async throws -> Data {
        var capturedError: Error?

        if let localIdentifier = item.itemIdentifier {
            do {
                if let data = try await photoLibraryData(for: localIdentifier) {
                    return data
                }
            } catch {
                capturedError = error
            }
        }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                return data
            }
        } catch {
            capturedError = capturedError ?? error
        }

        if let capturedError {
            throw ScanPhotoImportError.loadingFailed(capturedError)
        }

        throw ScanPhotoImportError.unavailable
    }

    private static func photoLibraryData(for localIdentifier: String) async throws -> Data? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)

        guard let asset = fetchResult.firstObject else {
            return nil
        }

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none
        options.version = .current

        return try await withCheckedThrowingContinuation { continuation in
            var didResume = false

            func resume(_ result: Result<Data?, Error>) {
                guard !didResume else { return }
                didResume = true

                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, info in
                if let isCancelled = info?[PHImageCancelledKey] as? Bool, isCancelled {
                    resume(.failure(ScanPhotoImportError.unavailable))
                    return
                }

                if let error = info?[PHImageErrorKey] as? Error {
                    resume(.failure(error))
                    return
                }

                if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded, data == nil {
                    return
                }

                resume(.success(data))
            }
        }
    }
}

private enum ScanPhotoImportError: LocalizedError {
    case unavailable
    case unsupportedFormat
    case loadingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "AIScend could not load that photo."
        case .unsupportedFormat:
            return "That photo format is not supported."
        case .loadingFailed(let error):
            return error.localizedDescription
        }
    }
}

private struct ScanPagePhotoImportAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String

    init(error: Error) {
        title = "Photo Could Not Load"

        let rawMessage = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = "AIScend could not download this image from Photos. If it is stored in iCloud, open it in Photos first so it finishes downloading, or take a new photo inside AIScend."

        if rawMessage.isEmpty || rawMessage == "The operation couldn’t be completed." {
            message = fallback
        } else {
            message = "\(rawMessage)\n\n\(fallback)"
        }
    }
}

private enum ScanPageCameraAlert: Int, Identifiable {
    case unavailable
    case denied

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .unavailable:
            "Camera Unavailable"
        case .denied:
            "Camera Access Needed"
        }
    }

    var message: String {
        switch self {
        case .unavailable:
            "This device does not have a camera available for in-app scan capture."
        case .denied:
            "Allow camera access in Settings to capture and crop scan photos without leaving the app."
        }
    }
}

private struct ScanCaptureProgressStrip: View {
    let stepTitle: String
    let guide: ScanCaptureGuide
    let isReady: Bool

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            progressItem(title: "Front", symbol: "face.smiling", state: frontState)
            progressItem(title: "Side", symbol: "person.crop.square", state: sideState)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stepTitle), \(guide.title)")
    }

    private var frontState: ScanCaptureProgressState {
        if guide == .front {
            return isReady ? .ready : .active
        }

        return .ready
    }

    private var sideState: ScanCaptureProgressState {
        if guide == .side {
            return isReady ? .ready : .active
        }

        return .pending
    }

    private func progressItem(
        title: String,
        symbol: String,
        state: ScanCaptureProgressState
    ) -> some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: state.symbolOverride ?? symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(state.tint)
                .frame(width: 26, height: 26)
                .background(Circle().fill(state.fill))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)

                Text(state.label)
                    .aiscendTextStyle(.caption, color: state.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceGlass.opacity(state == .pending ? 0.42 : 0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(state.border, lineWidth: 1)
        )
    }
}

private enum ScanCaptureProgressState: Equatable {
    case active
    case ready
    case pending

    var label: String {
        switch self {
        case .active:
            return "Current"
        case .ready:
            return "Ready"
        case .pending:
            return "Next"
        }
    }

    var symbolOverride: String? {
        switch self {
        case .ready:
            return "checkmark"
        case .active, .pending:
            return nil
        }
    }

    var tint: Color {
        switch self {
        case .active:
            return AIscendTheme.Colors.accentGlow
        case .ready:
            return AIscendTheme.Colors.success
        case .pending:
            return AIscendTheme.Colors.textMuted
        }
    }

    var fill: Color {
        switch self {
        case .active:
            return AIscendTheme.Colors.accentGlow.opacity(0.18)
        case .ready:
            return AIscendTheme.Colors.success.opacity(0.18)
        case .pending:
            return AIscendTheme.Colors.surfaceMuted.opacity(0.84)
        }
    }

    var border: Color {
        switch self {
        case .active:
            return AIscendTheme.Colors.accentGlow.opacity(0.38)
        case .ready:
            return AIscendTheme.Colors.success.opacity(0.32)
        case .pending:
            return AIscendTheme.Colors.borderSubtle
        }
    }
}

private struct ScanCaptureHeroFrame: View {
    let image: UIImage?
    let guide: ScanCaptureGuide
    let symbol: String
    let isLoading: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "111821"),
                            Color(hex: "15111E"),
                            Color(hex: "0E1118")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.18),
                        .clear,
                        Color.black.opacity(0.54)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                ScanGuideGrid()
                    .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [7, 9]))
                    .padding(AIscendTheme.Spacing.medium)
            } else {
                ScanFaceGuidePlaceholder(guide: guide, symbol: symbol)
                    .padding(AIscendTheme.Spacing.medium)
            }

            VStack {
                HStack {
                    statusBadge
                    Spacer(minLength: 0)
                }

                Spacer(minLength: 0)

                ScanCaptureInstructionPill(
                    text: image == nil ? guide.instruction : "\(guide.title) loaded",
                    isReady: image != nil
                )
            }
            .padding(AIscendTheme.Spacing.medium)

            if isLoading {
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(Color.black.opacity(0.46))

                ProgressView()
                    .tint(AIscendTheme.Colors.accentGlow)
                    .scaleEffect(1.12)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(ScanPhotoLayout.portraitAspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.26),
                            AIscendTheme.Colors.accentGlow.opacity(image == nil ? 0.18 : 0.42),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: AIscendTheme.Shadow.card, radius: 24, x: 0, y: 18)
    }

    private var statusBadge: some View {
        HStack(spacing: 7) {
            Image(systemName: image == nil ? "viewfinder" : "checkmark.seal.fill")
                .font(.system(size: 12, weight: .bold))

            Text(image == nil ? "Align photo" : "Captured")
                .aiscendTextStyle(.caption, color: image == nil ? AIscendTheme.Colors.textPrimary : Color.black)
        }
        .foregroundStyle(image == nil ? AIscendTheme.Colors.textPrimary : Color.black)
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(image == nil ? Color.black.opacity(0.46) : AIscendTheme.Colors.success)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(image == nil ? 0.16 : 0), lineWidth: 1)
        )
    }
}

private struct ScanCaptureInstructionPill: View {
    let text: String
    let isReady: Bool

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: isReady ? "checkmark.circle.fill" : "scope")
                .font(.system(size: 13, weight: .bold))

            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(isReady ? Color.black : AIscendTheme.Colors.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isReady ? AIscendTheme.Colors.accentMint : Color.black.opacity(0.58))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(isReady ? 0 : 0.14), lineWidth: 1)
        )
    }
}

private struct ScanCaptureGuidanceChips: View {
    let guide: ScanCaptureGuide

    private var tips: [(symbol: String, title: String)] {
        switch guide {
        case .front:
            return [
                ("sun.max.fill", "Even light"),
                ("face.smiling", "Neutral face"),
                ("viewfinder", "Centered")
            ]
        case .side:
            return [
                ("arrow.left.and.right", "90 degrees"),
                ("person.crop.square", "Full profile"),
                ("lightbulb.fill", "Clean outline")
            ]
        }
    }

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            ForEach(tips, id: \.title) { tip in
                HStack(spacing: 6) {
                    Image(systemName: tip.symbol)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AIscendTheme.Colors.accentGlow)

                    Text(tip.title)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.58))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                )
            }
        }
    }
}

private struct ScanCaptureActionStack: View {
    let image: UIImage?
    let buttonTitle: String
    let canUseCamera: Bool
    @Binding var pickerItem: PhotosPickerItem?
    let onStartCamera: () -> Void
    let onContinue: (() -> Void)?

    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            if image != nil, let onContinue {
                Button(action: onContinue) {
                    AIscendButtonLabel(title: "Continue", trailingSymbol: "arrow.right")
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))
            }

            if canUseCamera {
                Button(action: onStartCamera) {
                    AIscendButtonLabel(
                        title: image == nil ? "Take Photo" : "Retake",
                        leadingSymbol: "camera.fill"
                    )
                }
                .buttonStyle(AIscendButtonStyle(variant: image == nil ? .primary : .secondary))
            }

            PhotosPicker(
                selection: $pickerItem,
                matching: .images,
                preferredItemEncoding: .compatible
            ) {
                AIscendButtonLabel(
                    title: image == nil ? buttonTitle : "Replace",
                    leadingSymbol: "photo.badge.plus"
                )
            }
            .buttonStyle(AIscendButtonStyle(variant: canUseCamera || image != nil ? .secondary : .primary))
        }
    }
}

private struct ScanCaptureInlineError: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AIscendTheme.Colors.warning)
                .padding(.top, 1)

            Text(message)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AIscendTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AIscendTheme.Colors.warning.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AIscendTheme.Colors.warning.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct ScanFaceGuidePlaceholder: View {
    let guide: ScanCaptureGuide
    let symbol: String

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.94))

                ScanGuideGrid()
                    .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [7, 8]))

                ScanGuideMesh(guide: guide)
                    .stroke(Color.white.opacity(0.30), lineWidth: 1)

                ScanGuideLandmarks(guide: guide)

                ScanFaceGuideShape(guide: guide)
                    .stroke(Color.white.opacity(0.92), style: StrokeStyle(lineWidth: max(1.6, geometry.size.width * 0.010), lineCap: .round, lineJoin: .round))
                    .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.24), radius: 10, x: 0, y: 0)

                VStack(spacing: 8) {
                    Image(systemName: symbol)
                        .font(.system(size: 22, weight: .semibold))

                    Text(guide.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Color.white.opacity(0.86))
                .padding(.horizontal, AIscendTheme.Spacing.medium)
                .padding(.vertical, AIscendTheme.Spacing.small)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.black.opacity(0.58))
                        .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.18), lineWidth: 1))
                )
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, AIscendTheme.Spacing.large)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .accessibilityHidden(true)
    }
}

private struct ScanGuideMesh: Shape {
    let guide: ScanCaptureGuide

    func path(in rect: CGRect) -> Path {
        switch guide {
        case .front:
            return frontMesh(in: rect)
        case .side:
            return sideMesh(in: rect)
        }
    }

    private func frontMesh(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        let points = [
            CGPoint(x: 0.50, y: 0.08),
            CGPoint(x: 0.23, y: 0.39),
            CGPoint(x: 0.77, y: 0.39),
            CGPoint(x: 0.31, y: 0.66),
            CGPoint(x: 0.69, y: 0.66),
            CGPoint(x: 0.50, y: 0.92),
            CGPoint(x: 0.39, y: 0.42),
            CGPoint(x: 0.61, y: 0.42),
            CGPoint(x: 0.50, y: 0.54)
        ].map { CGPoint(x: rect.minX + w * $0.x, y: rect.minY + h * $0.y) }

        let lines = [
            (0, 1), (0, 2), (1, 3), (2, 4), (3, 5), (4, 5),
            (1, 8), (2, 8), (3, 8), (4, 8), (6, 8), (7, 8),
            (3, 4), (6, 7)
        ]

        for line in lines {
            path.move(to: points[line.0])
            path.addLine(to: points[line.1])
        }

        return path
    }

    private func sideMesh(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        let points = [
            CGPoint(x: 0.48, y: 0.08),
            CGPoint(x: 0.76, y: 0.18),
            CGPoint(x: 0.82, y: 0.40),
            CGPoint(x: 0.74, y: 0.54),
            CGPoint(x: 0.79, y: 0.64),
            CGPoint(x: 0.66, y: 0.78),
            CGPoint(x: 0.36, y: 0.58),
            CGPoint(x: 0.32, y: 0.32),
            CGPoint(x: 0.52, y: 0.94)
        ].map { CGPoint(x: rect.minX + w * $0.x, y: rect.minY + h * $0.y) }

        let lines = [
            (0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 8),
            (7, 0), (7, 6), (6, 5), (6, 8), (6, 3), (6, 2),
            (7, 2), (1, 3), (3, 5)
        ]

        for line in lines {
            path.move(to: points[line.0])
            path.addLine(to: points[line.1])
        }

        return path
    }
}

private struct ScanGuideLandmarks: View {
    let guide: ScanCaptureGuide

    private var points: [CGPoint] {
        switch guide {
        case .front:
            return [
                CGPoint(x: 0.50, y: 0.08),
                CGPoint(x: 0.23, y: 0.39),
                CGPoint(x: 0.77, y: 0.39),
                CGPoint(x: 0.36, y: 0.41),
                CGPoint(x: 0.44, y: 0.42),
                CGPoint(x: 0.56, y: 0.42),
                CGPoint(x: 0.64, y: 0.41),
                CGPoint(x: 0.50, y: 0.52),
                CGPoint(x: 0.42, y: 0.60),
                CGPoint(x: 0.50, y: 0.64),
                CGPoint(x: 0.58, y: 0.60),
                CGPoint(x: 0.33, y: 0.70),
                CGPoint(x: 0.50, y: 0.73),
                CGPoint(x: 0.67, y: 0.70),
                CGPoint(x: 0.37, y: 0.86),
                CGPoint(x: 0.63, y: 0.86),
                CGPoint(x: 0.50, y: 0.92)
            ]
        case .side:
            return [
                CGPoint(x: 0.48, y: 0.08),
                CGPoint(x: 0.76, y: 0.18),
                CGPoint(x: 0.82, y: 0.40),
                CGPoint(x: 0.72, y: 0.45),
                CGPoint(x: 0.74, y: 0.54),
                CGPoint(x: 0.79, y: 0.64),
                CGPoint(x: 0.70, y: 0.71),
                CGPoint(x: 0.66, y: 0.78),
                CGPoint(x: 0.36, y: 0.58),
                CGPoint(x: 0.32, y: 0.32),
                CGPoint(x: 0.52, y: 0.94)
            ]
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                Circle()
                    .fill(Color.white.opacity(0.96))
                    .frame(width: 7.5, height: 7.5)
                    .shadow(color: Color.white.opacity(0.32), radius: 5, x: 0, y: 0)
                    .position(
                        x: geometry.size.width * point.x,
                        y: geometry.size.height * point.y
                    )
            }
        }
        .accessibilityHidden(true)
    }
}

private struct ScanGuideGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for x in stride(from: 0.20, through: 0.80, by: 0.30) {
            path.move(to: CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * 0.04))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * x, y: rect.maxY - rect.height * 0.04))
        }

        for y in stride(from: 0.18, through: 0.82, by: 0.16) {
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.minY + rect.height * y))
            path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.06, y: rect.minY + rect.height * y))
        }

        return path
    }
}

private struct ScanFaceGuideShape: Shape {
    let guide: ScanCaptureGuide

    func path(in rect: CGRect) -> Path {
        switch guide {
        case .front:
            return frontPath(in: rect)
        case .side:
            return sidePath(in: rect)
        }
    }

    private func frontPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: rect.minX + w * 0.50, y: rect.minY + h * 0.08))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.78, y: rect.minY + h * 0.38),
            control1: CGPoint(x: rect.minX + w * 0.66, y: rect.minY + h * 0.08),
            control2: CGPoint(x: rect.minX + w * 0.77, y: rect.minY + h * 0.22)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.70, y: rect.minY + h * 0.70),
            control1: CGPoint(x: rect.minX + w * 0.79, y: rect.minY + h * 0.52),
            control2: CGPoint(x: rect.minX + w * 0.76, y: rect.minY + h * 0.63)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.50, y: rect.minY + h * 0.92),
            control1: CGPoint(x: rect.minX + w * 0.65, y: rect.minY + h * 0.82),
            control2: CGPoint(x: rect.minX + w * 0.58, y: rect.minY + h * 0.91)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.30, y: rect.minY + h * 0.70),
            control1: CGPoint(x: rect.minX + w * 0.42, y: rect.minY + h * 0.91),
            control2: CGPoint(x: rect.minX + w * 0.35, y: rect.minY + h * 0.82)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.22, y: rect.minY + h * 0.38),
            control1: CGPoint(x: rect.minX + w * 0.24, y: rect.minY + h * 0.63),
            control2: CGPoint(x: rect.minX + w * 0.21, y: rect.minY + h * 0.52)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.50, y: rect.minY + h * 0.08),
            control1: CGPoint(x: rect.minX + w * 0.23, y: rect.minY + h * 0.22),
            control2: CGPoint(x: rect.minX + w * 0.34, y: rect.minY + h * 0.08)
        )

        path.addEllipse(in: CGRect(x: rect.minX + w * 0.13, y: rect.minY + h * 0.38, width: w * 0.12, height: h * 0.22))
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.75, y: rect.minY + h * 0.38, width: w * 0.12, height: h * 0.22))

        path.move(to: CGPoint(x: rect.minX + w * 0.31, y: rect.minY + h * 0.39))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.47, y: rect.minY + h * 0.39),
            control1: CGPoint(x: rect.minX + w * 0.35, y: rect.minY + h * 0.34),
            control2: CGPoint(x: rect.minX + w * 0.43, y: rect.minY + h * 0.34)
        )
        path.move(to: CGPoint(x: rect.minX + w * 0.53, y: rect.minY + h * 0.39))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.69, y: rect.minY + h * 0.39),
            control1: CGPoint(x: rect.minX + w * 0.57, y: rect.minY + h * 0.34),
            control2: CGPoint(x: rect.minX + w * 0.65, y: rect.minY + h * 0.34)
        )

        path.addEllipse(in: CGRect(x: rect.minX + w * 0.34, y: rect.minY + h * 0.41, width: w * 0.11, height: h * 0.06))
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.55, y: rect.minY + h * 0.41, width: w * 0.11, height: h * 0.06))

        path.move(to: CGPoint(x: rect.minX + w * 0.50, y: rect.minY + h * 0.46))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.43, y: rect.minY + h * 0.62))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.57, y: rect.minY + h * 0.62),
            control1: CGPoint(x: rect.minX + w * 0.47, y: rect.minY + h * 0.66),
            control2: CGPoint(x: rect.minX + w * 0.53, y: rect.minY + h * 0.66)
        )
        path.closeSubpath()

        path.move(to: CGPoint(x: rect.minX + w * 0.32, y: rect.minY + h * 0.70))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.68, y: rect.minY + h * 0.70),
            control1: CGPoint(x: rect.minX + w * 0.42, y: rect.minY + h * 0.78),
            control2: CGPoint(x: rect.minX + w * 0.58, y: rect.minY + h * 0.78)
        )
        path.move(to: CGPoint(x: rect.minX + w * 0.34, y: rect.minY + h * 0.72))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.66, y: rect.minY + h * 0.72),
            control1: CGPoint(x: rect.minX + w * 0.43, y: rect.minY + h * 0.68),
            control2: CGPoint(x: rect.minX + w * 0.57, y: rect.minY + h * 0.68)
        )

        return path
    }

    private func sidePath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: rect.minX + w * 0.47, y: rect.minY + h * 0.08))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.77, y: rect.minY + h * 0.17),
            control1: CGPoint(x: rect.minX + w * 0.62, y: rect.minY + h * 0.06),
            control2: CGPoint(x: rect.minX + w * 0.74, y: rect.minY + h * 0.10)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.84, y: rect.minY + h * 0.41),
            control1: CGPoint(x: rect.minX + w * 0.82, y: rect.minY + h * 0.25),
            control2: CGPoint(x: rect.minX + w * 0.82, y: rect.minY + h * 0.35)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.74, y: rect.minY + h * 0.54),
            control1: CGPoint(x: rect.minX + w * 0.78, y: rect.minY + h * 0.45),
            control2: CGPoint(x: rect.minX + w * 0.73, y: rect.minY + h * 0.49)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.82, y: rect.minY + h * 0.64),
            control1: CGPoint(x: rect.minX + w * 0.80, y: rect.minY + h * 0.58),
            control2: CGPoint(x: rect.minX + w * 0.84, y: rect.minY + h * 0.61)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.66, y: rect.minY + h * 0.78),
            control1: CGPoint(x: rect.minX + w * 0.77, y: rect.minY + h * 0.70),
            control2: CGPoint(x: rect.minX + w * 0.72, y: rect.minY + h * 0.75)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.34, y: rect.minY + h * 0.58),
            control1: CGPoint(x: rect.minX + w * 0.53, y: rect.minY + h * 0.76),
            control2: CGPoint(x: rect.minX + w * 0.42, y: rect.minY + h * 0.68)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.47, y: rect.minY + h * 0.08),
            control1: CGPoint(x: rect.minX + w * 0.22, y: rect.minY + h * 0.36),
            control2: CGPoint(x: rect.minX + w * 0.29, y: rect.minY + h * 0.12)
        )

        path.addEllipse(in: CGRect(x: rect.minX + w * 0.27, y: rect.minY + h * 0.32, width: w * 0.16, height: h * 0.18))

        path.move(to: CGPoint(x: rect.minX + w * 0.67, y: rect.minY + h * 0.39))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.75, y: rect.minY + h * 0.39),
            control1: CGPoint(x: rect.minX + w * 0.70, y: rect.minY + h * 0.36),
            control2: CGPoint(x: rect.minX + w * 0.73, y: rect.minY + h * 0.36)
        )
        path.move(to: CGPoint(x: rect.minX + w * 0.74, y: rect.minY + h * 0.52))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.83, y: rect.minY + h * 0.52),
            control1: CGPoint(x: rect.minX + w * 0.78, y: rect.minY + h * 0.49),
            control2: CGPoint(x: rect.minX + w * 0.81, y: rect.minY + h * 0.50)
        )
        path.move(to: CGPoint(x: rect.minX + w * 0.74, y: rect.minY + h * 0.62))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.82, y: rect.minY + h * 0.62),
            control1: CGPoint(x: rect.minX + w * 0.77, y: rect.minY + h * 0.65),
            control2: CGPoint(x: rect.minX + w * 0.80, y: rect.minY + h * 0.65)
        )

        return path
    }
}
