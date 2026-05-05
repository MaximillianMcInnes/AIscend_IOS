//
//  ScanCapturePageView.swift
//  AIscend
//

import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct ScanCapturePageView: View {
    @Environment(\.openURL) private var openURL

    let title: String
    let subtitle: String
    let image: UIImage?
    let symbol: String
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

    private var canUseCamera: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    topBar(topInset: geometry.safeAreaInsets.top)

                    DashboardGlassCard {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                            Text(stepTitle)
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                            Text(title)
                                .aiscendTextStyle(.sectionTitle)

                            Text(subtitle)
                                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                        }
                    }

                    DashboardGlassCard {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.52))

                                if let image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            } else {
                                VStack(spacing: AIscendTheme.Spacing.small) {
                                    Image(systemName: symbol)
                                        .font(.system(size: 42, weight: .medium))
                                        .foregroundStyle(AIscendTheme.Colors.accentGlow)

                                        Text("No image selected")
                                            .aiscendTextStyle(.cardTitle)

                                        Text("Take a photo in the app or choose one from your library.")
                                            .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                                    }
                                    .padding(AIscendTheme.Spacing.large)
                                }

                                if isLoading {
                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                                        .fill(Color.black.opacity(0.35))

                                    ProgressView()
                                        .tint(AIscendTheme.Colors.accentGlow)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .aspectRatio(ScanPhotoLayout.portraitAspectRatio, contentMode: .fit)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                            )

                            if canUseCamera {
                                Button(action: startCameraCapture) {
                                    AIscendButtonLabel(
                                        title: image == nil ? "Take Photo" : "Retake Photo",
                                        leadingSymbol: "camera.fill"
                                    )
                                }
                                .buttonStyle(AIscendButtonStyle(variant: .primary))
                            }

                            PhotosPicker(selection: $pickerItem, matching: .images) {
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
                            }
                        }
                    }
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showingCameraCapture) {
            AIscendEditedCameraPicker(
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
        .onChange(of: pickerItem) { _, newValue in
            guard let newValue else { return }
            Task {
                await importPhoto(from: newValue)
            }
        }
    }

    private func topBar(topInset: CGFloat) -> some View {
        HStack {
            if let onBack {
                Button(action: onBack) {
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

            Spacer()

            Button(action: onClose) {
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

    private func importPhoto(from item: PhotosPickerItem) async {
        await MainActor.run {
            isLoading = true
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else {
                await MainActor.run {
                    isLoading = false
                }
                return
            }

            let scanImage = image.aiscendCroppedToScanPortrait()
            guard let compressed = scanImage.jpegData(compressionQuality: 0.88) else {
                await MainActor.run {
                    isLoading = false
                }
                return
            }

            await MainActor.run {
                finishImport(image: scanImage, data: compressed)
            }
        } catch {
            await MainActor.run {
                isLoading = false
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

        let scanImage = image.aiscendCroppedToScanPortrait()
        guard let compressed = scanImage.jpegData(compressionQuality: 0.88) else {
            isLoading = false
            return
        }

        finishImport(image: scanImage, data: compressed)
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
