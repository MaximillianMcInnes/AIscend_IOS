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
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                        topBar(topInset: geometry.safeAreaInsets.top)

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                            Text(stepTitle)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(AIscendTheme.Colors.accentGlow)
                                .textCase(.uppercase)

                            Text(subtitle)
                                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 2)

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: "F8F5FF").opacity(0.95),
                                                Color(hex: "DED7F0").opacity(0.92)
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
                                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                                } else {
                                    ScanFaceGuidePlaceholder(guide: guide, symbol: symbol)
                                        .padding(.horizontal, AIscendTheme.Spacing.xLarge)
                                        .padding(.vertical, AIscendTheme.Spacing.large)
                                }

                                VStack {
                                    Spacer()

                                    HStack {
                                        Image(systemName: image == nil ? "viewfinder" : "checkmark.seal.fill")
                                            .font(.system(size: 13, weight: .bold))

                                        Text(image == nil ? guide.instruction : "\(guide.title) ready")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .lineLimit(2)
                                    }
                                    .foregroundStyle(image == nil ? AIscendTheme.Colors.textPrimary : Color.black)
                                    .padding(.horizontal, AIscendTheme.Spacing.small)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(image == nil ? Color.black.opacity(0.58) : AIscendTheme.Colors.accentGlow)
                                    )
                                    .padding(AIscendTheme.Spacing.medium)
                                }

                                if isLoading {
                                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                                        .fill(Color.black.opacity(0.35))

                                    ProgressView()
                                        .tint(AIscendTheme.Colors.accentGlow)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .aspectRatio(ScanPhotoLayout.portraitAspectRatio, contentMode: .fit)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.36),
                                                AIscendTheme.Colors.accentGlow.opacity(0.28)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: AIscendTheme.Shadow.card, radius: 24, x: 0, y: 18)

                            if canUseCamera {
                                Button(action: startCameraCapture) {
                                    AIscendButtonLabel(
                                        title: image == nil ? "Take Photo" : "Retake Photo",
                                        leadingSymbol: "camera.fill"
                                    )
                                }
                                .buttonStyle(AIscendButtonStyle(variant: .primary))
                            }

                            PhotosPicker(
                                selection: $pickerItem,
                                matching: .images,
                                preferredItemEncoding: .compatible
                            ) {
                                AIscendButtonLabel(
                                    title: buttonTitle,
                                    leadingSymbol: "photo.badge.plus"
                                )
                            }
                            .buttonStyle(
                                AIscendButtonStyle(variant: canUseCamera ? .secondary : .primary)
                            )

                            if let onContinue {
                                Button(action: onContinue) {
                                    AIscendButtonLabel(
                                        title: "Continue",
                                        leadingSymbol: "arrow.right"
                                    )
                                }
                                .buttonStyle(AIscendButtonStyle(variant: .primary))
                            }

                            if let footnote, !footnote.isEmpty {
                                Text(footnote)
                                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(AIscendTheme.Spacing.medium)
                        .background(
                            RoundedRectangle(cornerRadius: 34, style: .continuous)
                                .fill(Color(hex: "111622").opacity(0.92))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 34, style: .continuous)
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )
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

            Text(title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

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
            capturedError = error
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

private struct ScanFaceGuidePlaceholder: View {
    let guide: ScanCaptureGuide
    let symbol: String

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScanGuideGrid()
                    .stroke(Color.black.opacity(0.10), lineWidth: 1)

                ScanGuideLandmarks(guide: guide)

                ScanFaceGuideShape(guide: guide)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "1C2030"),
                                Color(hex: "5B4A92")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: max(3, geometry.size.width * 0.016), lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.18), radius: 10, x: 0, y: 8)

                VStack(spacing: 8) {
                    Image(systemName: symbol)
                        .font(.system(size: 22, weight: .semibold))

                    Text(guide.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Color(hex: "252635").opacity(0.72))
                .padding(.horizontal, AIscendTheme.Spacing.medium)
                .padding(.vertical, AIscendTheme.Spacing.small)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.46))
                )
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, AIscendTheme.Spacing.large)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct ScanGuideLandmarks: View {
    let guide: ScanCaptureGuide

    private var points: [CGPoint] {
        switch guide {
        case .front:
            return [
                CGPoint(x: 0.38, y: 0.39),
                CGPoint(x: 0.62, y: 0.39),
                CGPoint(x: 0.50, y: 0.50),
                CGPoint(x: 0.42, y: 0.58),
                CGPoint(x: 0.58, y: 0.58),
                CGPoint(x: 0.50, y: 0.67),
                CGPoint(x: 0.33, y: 0.53),
                CGPoint(x: 0.67, y: 0.53)
            ]
        case .side:
            return [
                CGPoint(x: 0.45, y: 0.22),
                CGPoint(x: 0.60, y: 0.36),
                CGPoint(x: 0.72, y: 0.47),
                CGPoint(x: 0.62, y: 0.56),
                CGPoint(x: 0.48, y: 0.70),
                CGPoint(x: 0.35, y: 0.55)
            ]
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                Circle()
                    .fill(AIscendTheme.Colors.accentGlow.opacity(0.66))
                    .frame(width: 7, height: 7)
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
        let centerX = rect.midX
        let centerY = rect.midY

        path.move(to: CGPoint(x: centerX, y: rect.minY + rect.height * 0.08))
        path.addLine(to: CGPoint(x: centerX, y: rect.maxY - rect.height * 0.08))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: centerY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: centerY))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.32))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.22, y: rect.minY + rect.height * 0.32))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.minY + rect.height * 0.68))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.24, y: rect.minY + rect.height * 0.68))

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

        path.addEllipse(in: CGRect(
            x: rect.minX + w * 0.26,
            y: rect.minY + h * 0.15,
            width: w * 0.48,
            height: h * 0.53
        ))

        path.move(to: CGPoint(x: rect.minX + w * 0.38, y: rect.minY + h * 0.66))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.62, y: rect.minY + h * 0.66),
            control1: CGPoint(x: rect.minX + w * 0.42, y: rect.minY + h * 0.75),
            control2: CGPoint(x: rect.minX + w * 0.58, y: rect.minY + h * 0.75)
        )

        path.move(to: CGPoint(x: rect.minX + w * 0.34, y: rect.minY + h * 0.79))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.66, y: rect.minY + h * 0.79),
            control1: CGPoint(x: rect.minX + w * 0.40, y: rect.minY + h * 0.72),
            control2: CGPoint(x: rect.minX + w * 0.60, y: rect.minY + h * 0.72)
        )

        path.move(to: CGPoint(x: rect.minX + w * 0.42, y: rect.minY + h * 0.41))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.46, y: rect.minY + h * 0.41))

        path.move(to: CGPoint(x: rect.minX + w * 0.54, y: rect.minY + h * 0.41))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.58, y: rect.minY + h * 0.41))

        return path
    }

    private func sidePath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: rect.minX + w * 0.45, y: rect.minY + h * 0.14))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.34, y: rect.minY + h * 0.55),
            control1: CGPoint(x: rect.minX + w * 0.20, y: rect.minY + h * 0.16),
            control2: CGPoint(x: rect.minX + w * 0.20, y: rect.minY + h * 0.45)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.47, y: rect.minY + h * 0.70),
            control1: CGPoint(x: rect.minX + w * 0.35, y: rect.minY + h * 0.63),
            control2: CGPoint(x: rect.minX + w * 0.39, y: rect.minY + h * 0.68)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.74, y: rect.minY + h * 0.61),
            control1: CGPoint(x: rect.minX + w * 0.58, y: rect.minY + h * 0.72),
            control2: CGPoint(x: rect.minX + w * 0.68, y: rect.minY + h * 0.66)
        )
        path.addLine(to: CGPoint(x: rect.minX + w * 0.62, y: rect.minY + h * 0.56))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.72, y: rect.minY + h * 0.47),
            control1: CGPoint(x: rect.minX + w * 0.70, y: rect.minY + h * 0.55),
            control2: CGPoint(x: rect.minX + w * 0.76, y: rect.minY + h * 0.52)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.63, y: rect.minY + h * 0.39),
            control1: CGPoint(x: rect.minX + w * 0.66, y: rect.minY + h * 0.44),
            control2: CGPoint(x: rect.minX + w * 0.64, y: rect.minY + h * 0.42)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.45, y: rect.minY + h * 0.14),
            control1: CGPoint(x: rect.minX + w * 0.66, y: rect.minY + h * 0.25),
            control2: CGPoint(x: rect.minX + w * 0.60, y: rect.minY + h * 0.15)
        )

        path.move(to: CGPoint(x: rect.minX + w * 0.38, y: rect.minY + h * 0.70))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.66, y: rect.minY + h * 0.88),
            control1: CGPoint(x: rect.minX + w * 0.42, y: rect.minY + h * 0.80),
            control2: CGPoint(x: rect.minX + w * 0.55, y: rect.minY + h * 0.88)
        )

        path.move(to: CGPoint(x: rect.minX + w * 0.58, y: rect.minY + h * 0.36))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.62, y: rect.minY + h * 0.36))

        return path
    }
}
