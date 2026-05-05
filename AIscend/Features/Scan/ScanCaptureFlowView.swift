//
//  ScanCaptureFlowView.swift
//  AIscend
//

import SwiftUI
import PhotosUI
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

    @State private var frontPickerItem: PhotosPickerItem?
    @State private var sidePickerItem: PhotosPickerItem?
    @State private var frontPreview: UIImage?
    @State private var sidePreview: UIImage?
    @State private var showingResults = false

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

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    HStack {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(AIscendTheme.Colors.surfaceGlass)
                                )
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }

                    AIscendSectionHeader(
                        eyebrow: "Scan",
                        title: "Capture your front and side profile",
                        subtitle: "Choose two clear images to continue into the results flow."
                    )

                    VStack(spacing: AIscendTheme.Spacing.medium) {
                        captureCard(
                            title: "Front Photo",
                            subtitle: "Clear, straight-on image",
                            image: frontPreview,
                            pickerItem: $frontPickerItem
                        )

                        captureCard(
                            title: "Side Photo",
                            subtitle: "Clean side profile image",
                            image: sidePreview,
                            pickerItem: $sidePickerItem
                        )
                    }

                    Button {
                        showingResults = true
                    } label: {
                        AIscendButtonLabel(
                            title: canContinue ? "Continue to Results" : "Select Both Photos",
                            leadingSymbol: "arrow.right"
                        )
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .primary))
                    .disabled(!canContinue)
                    .opacity(canContinue ? 1 : 0.6)
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, 120)
            }
        }
        .preferredColorScheme(ColorScheme.dark)
        .onChange(of: frontPickerItem) { _, newItem in
            guard let newItem else { return }
            loadImage(from: newItem) { image in
                frontPreview = image
            }
        }
        .onChange(of: sidePickerItem) { _, newItem in
            guard let newItem else { return }
            loadImage(from: newItem) { image in
                sidePreview = image
            }
        }
        .fullScreenCover(isPresented: $showingResults) {
            ScanResultsFlowView(
                session: session,
                initialResult: nil,
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

    private var canContinue: Bool {
        frontPreview != nil && sidePreview != nil
    }

    @ViewBuilder
    private func captureCard(
        title: String,
        subtitle: String,
        image: UIImage?,
        pickerItem: Binding<PhotosPickerItem?>
    ) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(title)
                    .aiscendTextStyle(.cardTitle)

                Text(subtitle)
                    .aiscendTextStyle(.secondaryBody)
            }

            ZStack {
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceGlass)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                        )
                } else {
                    VStack(spacing: AIscendTheme.Spacing.small) {
                        Image(systemName: "photo")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(AIscendTheme.Colors.textMuted)

                        Text("No image selected")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(ScanPhotoLayout.portraitAspectRatio, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
            .clipped()

            PhotosPicker(selection: pickerItem, matching: .images) {
                AIscendButtonLabel(title: "Choose Photo", leadingSymbol: "photo.on.rectangle")
            }
            .buttonStyle(AIscendButtonStyle(variant: .secondary))
        }
        .padding(AIscendTheme.Spacing.mediumLarge)
        .aiscendPanel(.standard)
    }

    private func loadImage(from item: PhotosPickerItem, completion: @escaping (UIImage?) -> Void) {
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                await MainActor.run {
                    completion(nil)
                }
                return
            }

            let scanImage = image.aiscendCroppedToScanPortrait()
            await MainActor.run {
                completion(scanImage)
            }
        }
    }
}
