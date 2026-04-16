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

    private var archiveLabel: String {
        store.captureCount == 1 ? "1 day saved" : "\(store.captureCount) days saved"
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

                    VStack(alignment: .trailing, spacing: AIscendTheme.Spacing.xSmall) {
                        AIscendTopBarButton(symbol: "arrow.up.right", highlighted: true, action: onOpenArchive)

                        Text("Widget")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    }
                }

                HStack(spacing: AIscendTheme.Spacing.small) {
                    DailyPhotoArchiveMetaPill(title: "Archive", value: archiveLabel)
                    DailyPhotoArchiveMetaPill(title: "Order", value: "Newest first")
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

struct DailyPhotoArchiveView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ObservedObject var store: DailyPhotoStore
    let onDismiss: () -> Void

    @State private var selectedEntryID: DailyPhotoEntry.ID?
    @State private var showingCaptureSheet = false
    @State private var sortOrder: DailyPhotoSortOrder = .newestFirst

    private let columns = [
        GridItem(.flexible(), spacing: AIscendTheme.Spacing.medium),
        GridItem(.flexible(), spacing: AIscendTheme.Spacing.medium)
    ]

    private var sortedEntries: [DailyPhotoEntry] {
        store.sortedEntries(order: sortOrder)
    }

    private var featuredEntry: DailyPhotoEntry? {
        if let selectedEntryID,
           let selectedEntry = sortedEntries.first(where: { $0.id == selectedEntryID })
        {
            return selectedEntry
        }

        return sortedEntries.first
    }

    private var captureButtonTitle: String {
        store.hasPhotoToday ? "Update Today's Photo" : "Take Today's Photo"
    }

    private var captureButtonSymbol: String {
        store.hasPhotoToday ? "camera.fill" : "camera.aperture"
    }

    private var captureCountLabel: String {
        store.captureCount == 1 ? "1 capture" : "\(store.captureCount) captures"
    }

    private var streakLabel: String {
        "\(store.currentStreakDays())-day run"
    }

    private var timelineLead: String {
        switch sortOrder {
        case .newestFirst:
            return "Newest photos stay on top so today's momentum is easiest to read."
        case .oldestFirst:
            return "Oldest photos rise first so you can watch the archive build from day one."
        }
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                    topBar

                    if let featuredEntry {
                        heroCard(featuredEntry)
                        gridCard(selectedEntryID: featuredEntry.id)
                    } else {
                        emptyStateCard
                    }
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .onAppear {
            if selectedEntryID == nil {
                selectedEntryID = sortedEntries.first?.id
            }
        }
        .onChange(of: sortOrder) { _, _ in
            guard let currentSelection = selectedEntryID,
                  sortedEntries.contains(where: { $0.id == currentSelection }) else {
                selectedEntryID = sortedEntries.first?.id
                return
            }

            selectedEntryID = currentSelection
        }
        .sheet(isPresented: $showingCaptureSheet) {
            DailyPhotoCaptureSheet(
                store: store,
                onDismiss: {
                    selectedEntryID = store.todayEntry?.id ?? selectedEntryID
                    showingCaptureSheet = false
                }
            )
        }
    }

    private var topBar: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    AIscendTopBarButton(symbol: "chevron.left", action: onDismiss)

                    AIscendBadge(
                        title: "Daily Photos",
                        symbol: "camera.aperture",
                        style: .accent
                    )
                }

                Text("A dedicated photo timeline without a navbar, built for quick comparison and cleaner browsing.")
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            AIscendTopBarButton(
                symbol: store.hasPhotoToday ? "camera.rotate.fill" : "camera.fill",
                highlighted: true,
                action: { showingCaptureSheet = true }
            )
        }
    }

    private func heroCard(_ entry: DailyPhotoEntry) -> some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                AIscendSectionHeader(
                    eyebrow: "Photo timeline",
                    title: archiveHeroTitle(for: entry),
                    subtitle: timelineLead
                )

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        DailyPhotoArchiveMetaPill(title: "Saved", value: captureCountLabel)
                        DailyPhotoArchiveMetaPill(title: "Current streak", value: streakLabel)
                        DailyPhotoArchiveMetaPill(title: "Sort", value: sortOrder.accessibilityLabel)
                    }

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        DailyPhotoArchiveMetaPill(title: "Saved", value: captureCountLabel)
                        DailyPhotoArchiveMetaPill(title: "Current streak", value: streakLabel)
                        DailyPhotoArchiveMetaPill(title: "Sort", value: sortOrder.accessibilityLabel)
                    }
                }

                DailyPhotoSortToggle(value: sortOrder) { option in
                    if reduceMotion {
                        sortOrder = option
                    } else {
                        withAnimation(AIscendTheme.Motion.reveal) {
                            sortOrder = option
                        }
                    }
                }

                DailyPhotoArchiveHero(entry: entry, store: store)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        Button(action: { showingCaptureSheet = true }) {
                            AIscendButtonLabel(title: captureButtonTitle, leadingSymbol: captureButtonSymbol)
                        }
                        .buttonStyle(AIscendButtonStyle(variant: store.hasPhotoToday ? .secondary : .primary))

                        Button(action: {
                            if let firstEntry = sortedEntries.first {
                                select(firstEntry)
                            }
                        }) {
                            AIscendButtonLabel(
                                title: sortOrder == .newestFirst ? "Jump to Latest" : "Jump to First",
                                leadingSymbol: sortOrder == .newestFirst ? "arrow.up.forward.square.fill" : "clock.arrow.circlepath"
                            )
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .ghost))
                    }

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        Button(action: { showingCaptureSheet = true }) {
                            AIscendButtonLabel(title: captureButtonTitle, leadingSymbol: captureButtonSymbol)
                        }
                        .buttonStyle(AIscendButtonStyle(variant: store.hasPhotoToday ? .secondary : .primary))

                        Button(action: {
                            if let firstEntry = sortedEntries.first {
                                select(firstEntry)
                            }
                        }) {
                            AIscendButtonLabel(
                                title: sortOrder == .newestFirst ? "Jump to Latest" : "Jump to First",
                                leadingSymbol: sortOrder == .newestFirst ? "arrow.up.forward.square.fill" : "clock.arrow.circlepath"
                            )
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .ghost))
                    }
                }
            }
        }
    }

    private func gridCard(selectedEntryID: DailyPhotoEntry.ID) -> some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                AIscendSectionHeader(
                    eyebrow: "Date grid",
                    title: "Every saved day at a glance",
                    subtitle: sortOrder == .newestFirst
                        ? "The grid is now ordered from newest to oldest, so your latest changes stay visible first."
                        : "The grid is now ordered from oldest to newest, so the archive reads like a timeline."
                )

                LazyVGrid(columns: columns, spacing: AIscendTheme.Spacing.medium) {
                    ForEach(sortedEntries) { entry in
                        Button {
                            select(entry)
                        } label: {
                            DailyPhotoArchiveGridTile(
                                entry: entry,
                                store: store,
                                isSelected: entry.id == selectedEntryID
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyStateCard: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                AIscendSectionHeader(
                    eyebrow: "Visual archive",
                    title: "Your daily photo grid will build itself from here",
                    subtitle: "Save the first photo and this screen will turn into a sorted archive with full previews and dated tiles."
                )

                HStack(spacing: AIscendTheme.Spacing.medium) {
                    AIscendIconOrb(symbol: "camera.aperture", accent: .dawn, size: 54)

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                        Text("Nothing saved yet")
                            .aiscendTextStyle(.cardTitle)

                        Text("A single photo is enough to start the archive and give the home widget something real to preview.")
                            .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    }
                }
                .padding(AIscendTheme.Spacing.mediumLarge)
                .background(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                        .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                        .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                )

                Button(action: { showingCaptureSheet = true }) {
                    AIscendButtonLabel(title: "Take Your First Daily Photo", leadingSymbol: "camera.aperture")
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))
            }
        }
    }

    private func archiveHeroTitle(for entry: DailyPhotoEntry) -> String {
        guard let date = DailyPhotoStore.date(from: entry.ymd) else {
            return entry.ymd
        }

        return date.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private func select(_ entry: DailyPhotoEntry) {
        if reduceMotion {
            selectedEntryID = entry.id
        } else {
            withAnimation(AIscendTheme.Motion.reveal) {
                selectedEntryID = entry.id
            }
        }
    }
}

private struct DailyPhotoSortToggle: View {
    let value: DailyPhotoSortOrder
    let onChange: (DailyPhotoSortOrder) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(DailyPhotoSortOrder.allCases) { option in
                Button {
                    onChange(option)
                } label: {
                    VStack(spacing: 2) {
                        Text(option.title)
                            .aiscendTextStyle(.caption, color: value == option ? .white : AIscendTheme.Colors.textSecondary)

                        Text(option == .newestFirst ? "Latest first" : "Earliest first")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(value == option ? Color.white.opacity(0.82) : AIscendTheme.Colors.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, AIscendTheme.Spacing.small)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                value == option
                                    ? LinearGradient(
                                        colors: [
                                            AIscendTheme.Colors.accentPrimary,
                                            AIscendTheme.Colors.accentDeep
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [
                                            AIscendTheme.Colors.surfaceHighlight.opacity(0.9),
                                            AIscendTheme.Colors.surfaceMuted.opacity(0.88)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(
                                value == option ? AIscendTheme.Colors.accentGlow.opacity(0.54) : AIscendTheme.Colors.borderSubtle,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.accessibilityLabel)
            }
        }
        .padding(5)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.26))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct DailyPhotoArchiveHero: View {
    let entry: DailyPhotoEntry
    @ObservedObject var store: DailyPhotoStore

    private var timestampLabel: String {
        entry.createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    private var isToday: Bool {
        entry.id == DailyPhotoStore.ymd(for: .now)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.62))

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
                    AIscendTheme.Colors.mediaScrimTop,
                    AIscendTheme.Colors.mediaScrimBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                if isToday {
                    AIscendBadge(title: "Today", symbol: "sun.max.fill", style: .success)
                }

                Text(timestampLabel)
                    .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)

                Text("Stored locally and ready to compare against the rest of your grid.")
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
            }
            .padding(AIscendTheme.Spacing.mediumLarge)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
        )
    }
}

private struct DailyPhotoArchiveGridTile: View {
    let entry: DailyPhotoEntry
    @ObservedObject var store: DailyPhotoStore
    let isSelected: Bool

    private var dayLabel: String {
        guard let date = DailyPhotoStore.date(from: entry.ymd) else {
            return entry.ymd
        }

        return date.formatted(.dateTime.day())
    }

    private var monthLabel: String {
        guard let date = DailyPhotoStore.date(from: entry.ymd) else {
            return ""
        }

        return date.formatted(.dateTime.month(.abbreviated).weekday(.abbreviated))
    }

    private var isToday: Bool {
        entry.id == DailyPhotoStore.ymd(for: .now)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.68))

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
                        AIscendTheme.Colors.overlayDark.opacity(0.74)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                if isToday {
                    AIscendBadge(title: "Today", symbol: "sun.max.fill", style: .success)
                        .padding(AIscendTheme.Spacing.small)
                }
            }
            .frame(height: 172)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        isSelected ? AIscendTheme.Colors.accentGlow.opacity(0.52) : AIscendTheme.Colors.borderSubtle,
                        lineWidth: isSelected ? 1.4 : 1
                    )
            )

            HStack(alignment: .firstTextBaseline, spacing: AIscendTheme.Spacing.xSmall) {
                Text(dayLabel)
                    .font(.system(size: 30, weight: .bold, design: .default))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()

                Text(monthLabel.uppercased())
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}

private struct DailyPhotoArchiveMetaPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            Text(value)
                .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            Capsule(style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.82))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

#Preview {
    DailyPhotoArchiveView(store: DailyPhotoStore(), onDismiss: {})
}
