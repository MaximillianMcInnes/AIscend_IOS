//
//  DailyPhotoViews.swift
//  AIscend
//
//  Created by Codex on 4/9/26.
//

import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct DashboardDailyPhotoCard: View {
    @ObservedObject var store: DailyPhotoStore
    let onOpenArchive: () -> Void
    let onCapture: () -> Void

    private var recentEntries: [DailyPhotoEntry] {
        store.recentEntries(limit: 3)
    }

    private var streakDays: Int {
        store.currentStreakDays()
    }

    var body: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                        AIscendBadge(
                            title: store.captureCount > 0 ? "Daily photo archive" : "Start daily photo",
                            symbol: store.hasPhotoToday ? "checkmark.seal.fill" : "camera.aperture",
                            style: .accent
                        )

                        Text(store.captureCount > 0 ? "A calm visual record of the days that matter." : "Begin a calmer daily photo ritual.")
                            .aiscendTextStyle(.sectionTitle)

                        Text(
                            store.hasPhotoToday
                            ? "Today’s frame is already saved. Open the archive for sorted previews, date tiles, and a cleaner way to revisit the streak."
                            : "Capture one frame today, then revisit every saved day in a sorted grid with a focused preview."
                        )
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    }

                    Spacer(minLength: 0)

                    AIscendTopBarButton(symbol: "arrow.up.right", highlighted: true, action: onOpenArchive)
                }

                if recentEntries.isEmpty {
                    DailyPhotoArchiveEmptyStrip()
                } else {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        ForEach(recentEntries) { entry in
                            DashboardDailyPhotoPreviewTile(
                                entry: entry,
                                store: store,
                                emphasizesToday: entry.id == store.todayEntry?.id
                            )
                        }

                        ForEach(0..<max(0, 3 - recentEntries.count), id: \.self) { _ in
                            DashboardDailyPhotoPlaceholderTile()
                        }
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        DashboardDailyPhotoStatPill(
                            title: "Saved",
                            value: "\(store.captureCount)",
                            symbol: "photo.stack.fill"
                        )

                        DashboardDailyPhotoStatPill(
                            title: "Current run",
                            value: "\(streakDays)d",
                            symbol: "sparkles.rectangle.stack.fill"
                        )

                        DashboardDailyPhotoStatPill(
                            title: "Today",
                            value: store.hasPhotoToday ? "Ready" : "Open",
                            symbol: store.hasPhotoToday ? "checkmark.circle.fill" : "sun.max.fill"
                        )
                    }

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        DashboardDailyPhotoStatPill(
                            title: "Saved",
                            value: "\(store.captureCount)",
                            symbol: "photo.stack.fill"
                        )

                        DashboardDailyPhotoStatPill(
                            title: "Current run",
                            value: "\(streakDays)d",
                            symbol: "sparkles.rectangle.stack.fill"
                        )

                        DashboardDailyPhotoStatPill(
                            title: "Today",
                            value: store.hasPhotoToday ? "Ready" : "Open",
                            symbol: store.hasPhotoToday ? "checkmark.circle.fill" : "sun.max.fill"
                        )
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        Button(action: onOpenArchive) {
                            AIscendButtonLabel(title: "Open Archive", leadingSymbol: "square.grid.2x2.fill")
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .primary))

                        Button(action: onCapture) {
                            AIscendButtonLabel(
                                title: store.hasPhotoToday ? "Update Today" : "Take Today's Photo",
                                leadingSymbol: store.hasPhotoToday ? "camera.fill" : "camera.aperture"
                            )
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .secondary))
                    }

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        Button(action: onOpenArchive) {
                            AIscendButtonLabel(title: "Open Archive", leadingSymbol: "square.grid.2x2.fill")
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .primary))

                        Button(action: onCapture) {
                            AIscendButtonLabel(
                                title: store.hasPhotoToday ? "Update Today" : "Take Today's Photo",
                                leadingSymbol: store.hasPhotoToday ? "camera.fill" : "camera.aperture"
                            )
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .secondary))
                    }
                }
            }
        }
    }
}

private struct DashboardDailyPhotoPreviewTile: View {
    let entry: DailyPhotoEntry
    @ObservedObject var store: DailyPhotoStore
    var emphasizesToday: Bool = false

    private var dateLabel: String {
        if let date = DailyPhotoStore.date(from: entry.ymd) {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }

        return entry.ymd
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.surfaceHighlight.opacity(0.94),
                            AIscendTheme.Colors.surfaceMuted.opacity(0.94)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let url = store.imageURL(for: entry),
               let image = UIImage(contentsOfFile: url.path)
            {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }

            LinearGradient(
                colors: [
                    Color.clear,
                    AIscendTheme.Colors.overlayDark.opacity(0.82)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                if emphasizesToday {
                    Text("TODAY")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                }

                Text(dateLabel)
                    .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                    .lineLimit(1)
            }
            .padding(AIscendTheme.Spacing.medium)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 118)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    emphasizesToday ? AIscendTheme.Colors.accentGlow.opacity(0.44) : AIscendTheme.Colors.borderSubtle,
                    lineWidth: 1
                )
        )
    }
}

private struct DashboardDailyPhotoStatPill: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                Text(value)
                    .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            Capsule(style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.8))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct DashboardDailyPhotoPlaceholderTile: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        AIscendTheme.Colors.surfaceHighlight.opacity(0.7),
                        AIscendTheme.Colors.surfaceMuted.opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text("Next day")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                    Text("Waiting")
                        .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(AIscendTheme.Spacing.medium)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 118)
    }
}

private struct DailyPhotoArchiveEmptyStrip: View {
    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: "camera.aperture", accent: .dawn, size: 46)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text("No photos saved yet")
                    .aiscendTextStyle(.cardTitle)

                Text("Your archive will start filling in as soon as you save the first daily frame.")
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(AIscendTheme.Spacing.mediumLarge)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

struct DailyPhotoCaptureSheet: View {
    @Environment(\.openURL) private var openURL

    @ObservedObject var store: DailyPhotoStore
    let onDismiss: () -> Void

    @State private var selectedItem: PhotosPickerItem?
    @State private var isSaving = false
    @State private var feedbackMessage: String?
    @State private var showingPhotoLibrary = false
    @State private var showingCameraCapture = false
    @State private var cameraAlert: DailyPhotoCameraAlert?

    private var canUseCamera: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    private var todayLabel: String {
        Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private var cameraButtonTitle: String {
        "Take a Photo"
    }

    private var libraryButtonTitle: String {
        "Select Photo"
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    headerSection

                    if let feedbackMessage {
                        feedbackBanner(feedbackMessage)
                    }

                    previewCard
                }
                .padding(.horizontal, AIscendTheme.Spacing.mediumLarge)
                .padding(.top, AIscendTheme.Spacing.medium)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
            .safeAreaInset(edge: .bottom) {
                actionBar
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .presentationDetents([.fraction(0.92)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(30)
        .presentationBackground(.ultraThinMaterial)
        .interactiveDismissDisabled(isSaving)
        .photosPicker(
            isPresented: $showingPhotoLibrary,
            selection: $selectedItem,
            matching: .images
        )
        .fullScreenCover(isPresented: $showingCameraCapture) {
            DailyPhotoCameraPicker(
                onImagePicked: { image in
                    showingCameraCapture = false

                    Task {
                        await saveCapturedImage(image)
                    }
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
        .onChange(of: selectedItem) { _, newValue in
            guard let newValue else {
                return
            }

            Task {
                await importPhoto(from: newValue)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text(todayLabel.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("Daily Photo")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            Text(
                store.hasPhotoToday
                ? "Today's photo is saved. You can leave it or replace it with a new one."
                : "Take a quick photo for today, or choose one from your library."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var previewCard: some View {
        DailyPhotoSheetCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
                    Text(store.hasPhotoToday ? "Today's Photo" : "Preview")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer(minLength: 0)

                    if store.hasPhotoToday {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.green)
                    }
                }

                Text(
                    store.hasPhotoToday
                    ? "Retake it if you want a better shot."
                    : "You can use the camera or pick one from Photos."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                ZStack {
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))

                    if let entry = store.todayEntry {
                        DailyPhotoHeroPreview(entry: entry, store: store)
                    } else {
                        ContentUnavailableView {
                            Label("No photo yet", systemImage: "camera.viewfinder")
                        } description: {
                            Text("Take a photo or select one to save today's entry.")
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous))
            }
        }
    }

    private var actionBar: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            if isSaving {
                ProgressView("Saving today's photo...")
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if canUseCamera {
                Button(action: startCameraCapture) {
                    Label(cameraButtonTitle, systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(AIscendTheme.Colors.accentSoft)
                .disabled(isSaving)
            }

            if canUseCamera {
                Button(action: openPhotoLibrary) {
                    Label(libraryButtonTitle, systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(isSaving)
            } else {
                Button(action: openPhotoLibrary) {
                    Label(libraryButtonTitle, systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(AIscendTheme.Colors.accentSoft)
                .disabled(isSaving)
            }

            Button(store.hasPhotoToday ? "Done" : "Later", action: onDismiss)
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.top, AIscendTheme.Spacing.xxSmall)
                .disabled(isSaving)
        }
        .padding(.horizontal, AIscendTheme.Spacing.mediumLarge)
        .padding(.top, AIscendTheme.Spacing.small)
        .padding(.bottom, AIscendTheme.Spacing.medium)
        .background(.bar)
    }

    private func feedbackBanner(_ message: String) -> some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(AIscendTheme.Colors.accentGlow)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private func openPhotoLibrary() {
        selectedItem = nil
        showingPhotoLibrary = true
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

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(url)
    }

    @MainActor
    private func importPhoto(from item: PhotosPickerItem) async {
        defer {
            selectedItem = nil
        }

        do {
            isSaving = true
            feedbackMessage = nil

            guard let data = try await item.loadTransferable(type: Data.self) else {
                feedbackMessage = "That photo could not be loaded."
                isSaving = false
                return
            }

            guard let image = UIImage(data: data),
                  let compressedData = image.jpegData(compressionQuality: 0.88) else {
                feedbackMessage = "That photo format is not supported."
                isSaving = false
                return
            }

            await savePhotoData(compressedData)
        } catch {
            feedbackMessage = error.localizedDescription
            isSaving = false
        }
    }

    @MainActor
    private func saveCapturedImage(_ image: UIImage) async {
        guard let compressedData = image.jpegData(compressionQuality: 0.88) else {
            feedbackMessage = "That photo format is not supported."
            return
        }

        await savePhotoData(compressedData)
    }

    @MainActor
    private func savePhotoData(_ data: Data) async {
        do {
            isSaving = true
            feedbackMessage = nil

            _ = try store.saveTodayPhoto(data: data)
            feedbackMessage = "Today's photo was saved locally."
            isSaving = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onDismiss()
            }
        } catch {
            feedbackMessage = error.localizedDescription
            isSaving = false
        }
    }
}

private struct DailyPhotoHeroPreview: View {
    let entry: DailyPhotoEntry
    @ObservedObject var store: DailyPhotoStore

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let url = store.imageURL(for: entry),
               let image = UIImage(contentsOfFile: url.path)
            {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }

            LinearGradient(
                colors: [
                    Color.clear,
                    AIscendTheme.Colors.overlayDark
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text("Today's local capture")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .aiscendTextStyle(.cardTitle)
            }
            .padding(AIscendTheme.Spacing.medium)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct DailyPhotoThumbnailTile: View {
    let entry: DailyPhotoEntry
    @ObservedObject var store: DailyPhotoStore

    private var label: String {
        if let date = DailyPhotoStore.date(from: entry.ymd) {
            return date.formatted(.dateTime.day().month(.abbreviated))
        }

        return entry.ymd
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.62))
                    .frame(height: 92)

                if let url = store.imageURL(for: entry),
                   let image = UIImage(contentsOfFile: url.path)
                {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 92)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    Image(systemName: "camera.aperture")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(AIscendTheme.Colors.textMuted)
                }
            }

            Text(label)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum DailyPhotoCameraAlert: Int, Identifiable {
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
            "This device does not have a camera available for in-app capture."
        case .denied:
            "Allow camera access in Settings to capture today's photo without leaving the app."
        }
    }
}

private struct DailyPhotoSheetCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            content
        }
        .padding(AIscendTheme.Spacing.mediumLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct DailyPhotoCameraPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.modalPresentationStyle = .fullScreen
        picker.allowsEditing = false
        picker.delegate = context.coordinator

        if UIImagePickerController.isCameraDeviceAvailable(.front) {
            picker.cameraDevice = .front
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onImagePicked: (UIImage) -> Void
        private let onCancel: () -> Void

        init(
            onImagePicked: @escaping (UIImage) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onImagePicked = onImagePicked
            self.onCancel = onCancel
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            } else {
                onCancel()
            }
        }
    }
}
