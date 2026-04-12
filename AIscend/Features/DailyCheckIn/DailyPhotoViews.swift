//
//  DailyPhotoViews.swift
//  AIscend
//
//  Created by Codex on 4/9/26.
//

import PhotosUI
import SwiftUI
import UIKit

struct DashboardDailyPhotoCard: View {
    @ObservedObject var store: DailyPhotoStore
    let onCapture: () -> Void

    private var recentEntries: [DailyPhotoEntry] {
        store.recentEntries()
    }

    var body: some View {
        DashboardGlassCard(tone: .standard) {
            HStack(alignment: .center, spacing: AIscendTheme.Spacing.large) {
                AIscendIconOrb(
                    symbol: store.hasPhotoToday ? "checkmark.viewfinder" : "camera.aperture",
                    accent: .dawn,
                    size: 50
                )

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    AIscendBadge(
                        title: store.hasPhotoToday ? "Today's photo locked" : "Daily photo open",
                        symbol: store.hasPhotoToday ? "checkmark.seal.fill" : "camera.aperture",
                        style: .accent
                    )

                    Text(store.hasPhotoToday ? "Today's baseline is stored locally." : "Capture today's baseline before the read drifts.")
                        .aiscendTextStyle(.sectionTitle)

                    Text("Everything stays on this device. AIScend can nudge you on first open and then up to three more random times until today's photo is done.")
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: AIscendTheme.Spacing.small) {
                dailyPhotoMetric(
                    title: "Stored",
                    value: "\(store.captureCount)",
                    detail: "local captures"
                )
                dailyPhotoMetric(
                    title: "Streak",
                    value: "\(store.currentStreakDays())d",
                    detail: "days in a row"
                )
                dailyPhotoMetric(
                    title: "Prompts left",
                    value: "\(store.hasPhotoToday ? 0 : store.randomPromptsRemainingToday)",
                    detail: "random today"
                )
            }
            .padding(.top, AIscendTheme.Spacing.large)

            if !recentEntries.isEmpty {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    Text("Recent captures")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                    HStack(spacing: AIscendTheme.Spacing.small) {
                        ForEach(recentEntries) { entry in
                            DailyPhotoThumbnailTile(entry: entry, store: store)
                        }
                    }
                }
                .padding(.top, AIscendTheme.Spacing.large)
            }

            Button(action: onCapture) {
                AIscendButtonLabel(
                    title: store.hasPhotoToday ? "Update Today's Photo" : "Add Today's Photo",
                    leadingSymbol: "photo.badge.plus"
                )
            }
            .buttonStyle(AIscendButtonStyle(variant: store.hasPhotoToday ? .secondary : .primary))
            .padding(.top, AIscendTheme.Spacing.large)
        }
    }

    private func dailyPhotoMetric(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            Text(value)
                .aiscendTextStyle(.sectionTitle)

            Text(detail)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.62))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

struct DailyPhotoCaptureSheet: View {
    @ObservedObject var store: DailyPhotoStore
    let onDismiss: () -> Void

    @State private var selectedItem: PhotosPickerItem?
    @State private var isSaving = false
    @State private var feedbackMessage: String?

    private var pickerTitle: String {
        if isSaving {
            return "Saving..."
        }

        return store.hasPhotoToday ? "Replace today's photo" : "Choose photo"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AIscendBackdrop()
                DashboardAmbientLayer()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                        AIscendBadge(
                            title: store.hasPhotoToday ? "Today's photo is live" : "Daily photo prompt",
                            symbol: "camera.aperture",
                            style: .accent
                        )

                        AIscendSectionHeader(
                            title: store.hasPhotoToday ? "Update today's baseline if you want a cleaner comparison" : "Lock today's baseline before the day gets noisy",
                            subtitle: "AIScend stores every daily photo locally on this device. Nothing in this flow requires cloud sync."
                        )

                        ZStack {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.62))
                                .frame(height: 240)

                            if let entry = store.todayEntry {
                                DailyPhotoHeroPreview(entry: entry, store: store)
                            } else {
                                VStack(spacing: AIscendTheme.Spacing.small) {
                                    Image(systemName: "camera.aperture")
                                        .font(.system(size: 42, weight: .medium))
                                        .foregroundStyle(AIscendTheme.Colors.accentGlow)

                                    Text("No photo saved for today yet")
                                        .aiscendTextStyle(.cardTitle)

                                    Text("Choose a photo from your library and AIScend will pin it to today's local archive.")
                                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: 280)
                                }
                                .padding(AIscendTheme.Spacing.large)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )

                        HStack(spacing: AIscendTheme.Spacing.small) {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                AIscendButtonLabel(
                                    title: pickerTitle,
                                    leadingSymbol: "photo.badge.plus"
                                )
                            }
                            .buttonStyle(AIscendButtonStyle(variant: .primary))
                            .disabled(isSaving)

                            Button(action: onDismiss) {
                                AIscendButtonLabel(title: "Later", leadingSymbol: "clock")
                            }
                            .buttonStyle(AIscendButtonStyle(variant: .secondary))
                            .disabled(isSaving)
                        }

                        if let feedbackMessage {
                            Text(feedbackMessage)
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                        }

                        if !store.recentEntries(limit: 3).isEmpty {
                            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                                Text("Recent local archive")
                                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                                HStack(spacing: AIscendTheme.Spacing.small) {
                                    ForEach(store.recentEntries(limit: 3)) { entry in
                                        DailyPhotoThumbnailTile(entry: entry, store: store)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                    .padding(.top, AIscendTheme.Spacing.large)
                    .padding(.bottom, AIscendTheme.Spacing.xxLarge)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onChange(of: selectedItem) { _, newValue in
            guard let newValue else {
                return
            }

            Task {
                await importPhoto(from: newValue)
            }
        }
    }

    private func importPhoto(from item: PhotosPickerItem) async {
        do {
            isSaving = true

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

            _ = try store.saveTodayPhoto(data: compressedData)
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
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
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
