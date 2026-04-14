//
//  DailyPhotoArchiveView.swift
//  AIscend
//
//  Created by Codex on 4/14/26.
//

import SwiftUI
import UIKit

struct DailyPhotoArchiveView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ObservedObject var store: DailyPhotoStore
    let onDismiss: () -> Void

    @State private var selectedEntryID: DailyPhotoEntry.ID?
    @State private var showingCaptureSheet = false

    private let columns = [
        GridItem(.flexible(), spacing: AIscendTheme.Spacing.medium),
        GridItem(.flexible(), spacing: AIscendTheme.Spacing.medium)
    ]

    private var sortedEntries: [DailyPhotoEntry] {
        store.sortedEntries()
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
        HStack(spacing: AIscendTheme.Spacing.medium) {
            AIscendTopBarButton(symbol: "chevron.left", action: onDismiss)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                AIscendBadge(
                    title: "Daily Photo Archive",
                    symbol: "camera.aperture",
                    style: .accent
                )

                Text("Sorted visual history with a focused preview")
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
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
                    eyebrow: "Focused preview",
                    title: archiveHeroTitle(for: entry),
                    subtitle: "Newest photos stay first. Tap any tile below to bring that day into focus."
                )

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        DailyPhotoArchiveMetaPill(title: "Saved", value: captureCountLabel)
                        DailyPhotoArchiveMetaPill(title: "Current streak", value: streakLabel)
                        DailyPhotoArchiveMetaPill(title: "Sort", value: "Newest first")
                    }

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        DailyPhotoArchiveMetaPill(title: "Saved", value: captureCountLabel)
                        DailyPhotoArchiveMetaPill(title: "Current streak", value: streakLabel)
                        DailyPhotoArchiveMetaPill(title: "Sort", value: "Newest first")
                    }
                }

                DailyPhotoArchiveHero(entry: entry, store: store)

                Button(action: { showingCaptureSheet = true }) {
                    AIscendButtonLabel(title: captureButtonTitle, leadingSymbol: captureButtonSymbol)
                }
                .buttonStyle(AIscendButtonStyle(variant: store.hasPhotoToday ? .secondary : .primary))
            }
        }
    }

    private func gridCard(selectedEntryID: DailyPhotoEntry.ID) -> some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                AIscendSectionHeader(
                    eyebrow: "Date grid",
                    title: "Every saved day at a glance",
                    subtitle: "A cleaner calendar-style read of your photo streak, ordered by most recent capture."
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
