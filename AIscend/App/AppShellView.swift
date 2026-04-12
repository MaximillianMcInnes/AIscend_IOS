//
//  AppShellView.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import Foundation
import PhotosUI
import SwiftUI

struct AppShellView: View {
    @Bindable var model: AppModel
    @Bindable var session: AuthSessionStore

    var body: some View {
        MainTabContainer(model: model, session: session)
    }
}

struct RoutineBlueprintView: View {
    @Bindable var model: AppModel
    @ObservedObject var dailyCheckInStore: DailyCheckInStore
    @ObservedObject var badgeManager: BadgeManager
    let onOpenCheckIn: () -> Void
    let onOpenConsistency: () -> Void

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                    blueprintHero
                    consistencyPanel
                    intentionPanel
                    anchorPanel
                    routineSections
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var consistencyPanel: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendSectionHeader(
                eyebrow: "Consistency",
                title: dailyCheckInStore.hasCheckedInToday ? "Today's chain is protected" : "Today's chain is still open",
                subtitle: "AIScend keeps the routine tied to a daily accountability loop so the plan feels lived, not just admired."
            )

            HStack(spacing: AIscendTheme.Spacing.small) {
                AIscendMetricCard(
                    title: "Current streak",
                    value: "\(dailyCheckInStore.snapshot.currentStreak)d",
                    detail: dailyCheckInStore.snapshot.motivationalLine,
                    symbol: dailyCheckInStore.hasCheckedInToday ? "checkmark.seal.fill" : "flame.fill",
                    accent: .sky,
                    highlighted: true
                )
                AIscendMetricCard(
                    title: "Badges",
                    value: "\(badgeManager.earnedCount)",
                    detail: "Quiet status markers earned through follow-through.",
                    symbol: "sparkles",
                    accent: .mint
                )
            }

            HStack(spacing: AIscendTheme.Spacing.small) {
                Button(action: onOpenCheckIn) {
                    AIscendButtonLabel(
                        title: dailyCheckInStore.hasCheckedInToday ? "Review Daily Check-In" : "Complete Daily Check-In",
                        leadingSymbol: "calendar.badge.checkmark"
                    )
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))

                Button(action: onOpenConsistency) {
                    AIscendButtonLabel(title: "Open Streaks", leadingSymbol: "flame.fill")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
            }

            Button {
                withAnimation(AIscendTheme.Motion.reveal) {
                    model.resetOnboarding()
                }
            } label: {
                AIscendButtonLabel(title: "Refine routine", leadingSymbol: "slider.horizontal.3")
            }
            .buttonStyle(AIscendButtonStyle(variant: .secondary))
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.elevated)
    }

    private var blueprintHero: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            HStack {
                AIscendBadge(
                    title: "Blueprint",
                    symbol: "square.grid.2x2.fill",
                    style: .accent
                )

                Spacer()
            }

            AIscendSectionHeader(
                title: "The current operating structure",
                subtitle: "AIScend is applying the following routine model. Refine onboarding any time you want to alter the tempo or intent.",
                prominence: .hero
            )

            HStack(spacing: AIscendTheme.Spacing.small) {
                AIscendCapsule(title: model.profile.focusTrack.title, symbol: model.profile.focusTrack.symbol, isActive: true)
                AIscendCapsule(title: model.profile.wakeLabel, symbol: "alarm.fill", isActive: false)
            }
        }
        .padding(AIscendTheme.Spacing.xLarge)
        .aiscendPanel(.hero)
    }

    private var intentionPanel: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendSectionHeader(
                eyebrow: "Intent",
                title: "What the system is optimized around",
                subtitle: model.profile.intention
            )

            HStack(spacing: AIscendTheme.Spacing.small) {
                compactMetric(
                    title: "Identity",
                    value: model.profile.displayName,
                    symbol: "figure.hiking"
                )
                compactMetric(
                    title: "Wake-up",
                    value: model.profile.wakeLabel,
                    symbol: "clock.fill"
                )
            }
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.elevated)
    }

    private var anchorPanel: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendSectionHeader(
                eyebrow: "Anchors",
                title: "Stability drivers",
                subtitle: "These are the habit anchors currently supporting the operating model."
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                ForEach(model.profile.anchors, id: \.self) { anchor in
                    AIscendCapsule(title: anchor.title, symbol: anchor.symbol, isActive: true)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AIscendTheme.Spacing.xSmall)
                }
            }

            if model.profile.anchors.isEmpty {
                Text("No anchors are active yet.")
                    .aiscendTextStyle(.secondaryBody)
            }
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.standard)
    }

    private var routineSections: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendSectionHeader(
                eyebrow: "Flow",
                title: "How the day is sequenced",
                subtitle: "Each section below maps the current operating mode into a concrete cadence."
            )

            ForEach(model.routineSections) { section in
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                    HStack {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                            Text(section.title)
                                .aiscendTextStyle(.sectionTitle)

                            Text(section.subtitle)
                                .aiscendTextStyle(.body)
                        }

                        Spacer()

                        AIscendBadge(
                            title: "\(section.steps.count) steps",
                            symbol: "list.number",
                            style: .neutral
                        )
                    }

                    ForEach(section.steps) { step in
                        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                            AIscendIconOrb(symbol: step.symbol, accent: step.accent, size: 40)

                            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                                Text(step.title)
                                    .aiscendTextStyle(.cardTitle)

                                Text(step.detail)
                                    .aiscendTextStyle(.body)
                            }

                            Spacer()
                        }
                        .padding(AIscendTheme.Spacing.medium)
                        .background(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.68))
                        )
                    }
                }
                .padding(AIscendTheme.Spacing.large)
                .aiscendPanel(.standard)
            }
        }
    }

    private func compactMetric(title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            AIscendIconOrb(symbol: symbol, accent: .dawn, size: 38)

            Text(title)
                .aiscendTextStyle(.caption)

            Text(value)
                .aiscendTextStyle(.cardTitle)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.mediumLarge)
        .aiscendPanel(.muted)
    }
}

struct AccountView: View {
    @Bindable var model: AppModel
    @Bindable var session: AuthSessionStore
    @ObservedObject var dailyCheckInStore: DailyCheckInStore
    @ObservedObject var badgeManager: BadgeManager
    @ObservedObject var notificationManager: NotificationManager
    @State private var showingDailyCheckIn = false
    @State private var showingStreaks = false
    @State private var draftName = ""
    @State private var draftIntention = ""
    @State private var draftWakeTime = Date.now
    @State private var draftFocusTrack: FocusTrack = .momentum
    @State private var draftAnchors: [HabitAnchor] = []
    @State private var selectedAvatarItem: PhotosPickerItem?
    @State private var profileMessage: String?
    @State private var isSavingProfile = false
    @State private var hasHydratedProfileEditor = false

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                    userPanel
                    routineStatePanel
                    consistencyPanel
                    actionsPanel

                    if let errorMessage = session.errorMessage {
                        messagePanel(title: "Auth status", message: errorMessage)
                    } else if let configurationMessage = session.configurationMessage {
                        messagePanel(title: "Firebase setup", message: configurationMessage)
                    }
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await notificationManager.refreshAuthorizationStatus()
            hydrateProfileEditorIfNeeded()
        }
        .onChange(of: selectedAvatarItem) { _, newValue in
            guard let newValue else {
                return
            }

            Task {
                await importAvatar(from: newValue)
            }
        }
        .sheet(isPresented: $showingDailyCheckIn) {
            DailyCheckInView(
                dailyCheckInStore: dailyCheckInStore,
                badgeManager: badgeManager,
                notificationManager: notificationManager,
                isPremium: badgeManager.earnedBadges.contains(where: { $0.id == .premiumUnlocked }),
                onComplete: {},
                onDismiss: { showingDailyCheckIn = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingStreaks) {
            StreaksView(
                dailyCheckInStore: dailyCheckInStore,
                badgeManager: badgeManager,
                notificationManager: notificationManager,
                onOpenCheckIn: {
                    showingStreaks = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        showingDailyCheckIn = true
                    }
                },
                onDismiss: { showingStreaks = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var userPanel: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            HStack {
                AIscendBadge(
                    title: "Profile",
                    symbol: "person.crop.rectangle.stack.fill",
                    style: .accent
                )

                Spacer()
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(spacing: AIscendTheme.Spacing.mediumLarge) {
                    ProfileAvatarView(
                        localURL: model.profileAvatarURL,
                        remoteURL: session.user?.photoURL,
                        initials: session.user?.initials ?? String(model.profile.displayName.prefix(2)).uppercased()
                    )

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                        Text(session.user?.displayName ?? model.profile.displayName)
                            .aiscendTextStyle(.sectionTitle)

                        Text(session.user?.subtitle ?? "Local profile")
                            .aiscendTextStyle(.body)

                        Text(session.providerSummary)
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                    }
                }

                HStack(spacing: AIscendTheme.Spacing.small) {
                    PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                        AIscendButtonLabel(title: "Change photo", leadingSymbol: "photo.badge.plus")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .secondary))

                    if model.profileAvatarURL != nil {
                        Button {
                            model.removeProfileAvatar()
                            profileMessage = "Profile photo removed."
                        } label: {
                            AIscendButtonLabel(title: "Remove photo", leadingSymbol: "trash")
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .destructive))
                    }
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    Text("Display name")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                    TextField("Your name", text: $draftName)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .aiscendInputField()
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    Text("Climb statement")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                    TextEditor(text: $draftIntention)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .font(.system(size: 15, weight: .regular))
                        .frame(minHeight: 108)
                        .padding(AIscendTheme.Spacing.small)
                        .background(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                                .fill(AIscendTheme.Colors.fieldFill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                }

                if let profileMessage {
                    Text(profileMessage)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                }
            }
        }
        .padding(AIscendTheme.Spacing.xLarge)
        .aiscendPanel(.hero)
    }

    private var routineStatePanel: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendSectionHeader(
                eyebrow: "Preferences",
                title: "Tune how your profile behaves",
                subtitle: "Keep the account identity and routine layer aligned in one place."
            )

            HStack(spacing: AIscendTheme.Spacing.small) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    Text("Wake-up time")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                    DatePicker(
                        "Wake-up time",
                        selection: $draftWakeTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .datePickerStyle(.wheel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AIscendTheme.Spacing.mediumLarge)
                .aiscendPanel(.muted)

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    Text("Focus track")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                    Picker("Focus track", selection: $draftFocusTrack) {
                        ForEach(FocusTrack.allCases) { track in
                            Text(track.title).tag(track)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(draftFocusTrack.routinePrompt)
                        .aiscendTextStyle(.secondaryBody)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AIscendTheme.Spacing.mediumLarge)
                .aiscendPanel(.muted)
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                Text("Habit anchors")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                    ForEach(HabitAnchor.allCases) { anchor in
                        Button {
                            toggleDraftAnchor(anchor)
                        } label: {
                            HStack(spacing: AIscendTheme.Spacing.small) {
                                Image(systemName: anchor.symbol)
                                    .font(.system(size: 14, weight: .semibold))

                                Text(anchor.title)
                                    .aiscendTextStyle(.buttonLabel, color: AIscendTheme.Colors.textPrimary)

                                Spacer()
                            }
                            .padding(.horizontal, AIscendTheme.Spacing.medium)
                            .padding(.vertical, AIscendTheme.Spacing.medium)
                            .background(
                                RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                                    .fill(
                                        draftAnchors.contains(anchor)
                                        ? AIscendTheme.Colors.accentPrimary.opacity(0.18)
                                        : AIscendTheme.Colors.surfaceHighlight.opacity(0.78)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                                    .stroke(
                                        draftAnchors.contains(anchor)
                                        ? AIscendTheme.Colors.accentGlow.opacity(0.38)
                                        : AIscendTheme.Colors.borderSubtle,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                Task {
                    await saveProfile()
                }
            } label: {
                AIscendButtonLabel(
                    title: isSavingProfile ? "Saving Profile" : "Save Profile",
                    leadingSymbol: "checkmark.circle.fill"
                )
            }
            .buttonStyle(AIscendButtonStyle(variant: .primary))
            .disabled(isSavingProfile)
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.standard)
    }

    private var actionsPanel: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendSectionHeader(
                eyebrow: "Actions",
                title: "Manage this workspace",
                subtitle: "Keep the environment current without losing your profile setup."
            )

            Button {
                withAnimation(AIscendTheme.Motion.reveal) {
                    model.resetOnboarding()
                }
            } label: {
                AIscendButtonLabel(title: "Refine onboarding", leadingSymbol: "slider.horizontal.3")
            }
            .buttonStyle(AIscendButtonStyle(variant: .secondary))

            Button {
                withAnimation(AIscendTheme.Motion.reveal) {
                    model.resetRoutineProgress()
                }
            } label: {
                AIscendButtonLabel(title: "Reset today's progress", leadingSymbol: "arrow.counterclockwise")
            }
            .buttonStyle(AIscendButtonStyle(variant: .secondary))

            Button {
                session.signOut()
            } label: {
                AIscendButtonLabel(title: "Sign out", leadingSymbol: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(AIscendButtonStyle(variant: .destructive))
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.elevated)
    }

    private var consistencyPanel: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendSectionHeader(
                eyebrow: "Consistency",
                title: "Your private discipline layer",
                subtitle: "Streaks, badges, and daily accountability now sit inside the account hub instead of floating as isolated features."
            )

            HStack(spacing: AIscendTheme.Spacing.small) {
                AIscendMetricCard(
                    title: "Current streak",
                    value: "\(dailyCheckInStore.snapshot.currentStreak)d",
                    detail: dailyCheckInStore.snapshot.statusTitle,
                    symbol: dailyCheckInStore.hasCheckedInToday ? "checkmark.seal.fill" : "flame.fill",
                    accent: .sky,
                    highlighted: true
                )
                AIscendMetricCard(
                    title: "Best streak",
                    value: "\(dailyCheckInStore.snapshot.bestStreak)d",
                    detail: "Highest sustained run so far.",
                    symbol: "scope",
                    accent: .mint
                )
            }

            HStack(spacing: AIscendTheme.Spacing.small) {
                AIscendMetricCard(
                    title: "Badges",
                    value: "\(badgeManager.earnedCount)",
                    detail: badgeManager.earnedBadges.first?.title ?? "No markers earned yet.",
                    symbol: "sparkles",
                    accent: .dawn
                )
                AIscendMetricCard(
                    title: "Reminders",
                    value: "\(notificationManager.preferences.enabledCount)",
                    detail: notificationManager.authorizationState.badgeTitle,
                    symbol: "bell.badge.fill",
                    accent: .sky
                )
            }

            if !badgeManager.earnedBadges.isEmpty {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    Text("Latest badges")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                    ForEach(Array(badgeManager.earnedBadges.prefix(3))) { badge in
                        HStack(spacing: AIscendTheme.Spacing.small) {
                            AIscendIconOrb(symbol: badge.symbol, accent: badge.accent, size: 34)

                            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                                Text(badge.title)
                                    .aiscendTextStyle(.cardTitle)

                                Text(badge.detail)
                                    .aiscendTextStyle(.secondaryBody)
                                    .lineLimit(2)
                            }
                        }
                        .padding(AIscendTheme.Spacing.medium)
                        .background(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.68))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                    }
                }
            }

            HStack(spacing: AIscendTheme.Spacing.small) {
                Button {
                    showingDailyCheckIn = true
                } label: {
                    AIscendButtonLabel(
                        title: dailyCheckInStore.hasCheckedInToday ? "Review Daily Check-In" : "Complete Daily Check-In",
                        leadingSymbol: "calendar.badge.checkmark"
                    )
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))

                Button {
                    showingStreaks = true
                } label: {
                    AIscendButtonLabel(title: "Open Streaks", leadingSymbol: "flame.fill")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
            }
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.standard)
    }

    private func messagePanel(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendBadge(title: title, symbol: "info.circle.fill", style: .neutral)

            Text(message)
                .aiscendTextStyle(.body)
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.muted)
    }

    private func hydrateProfileEditorIfNeeded() {
        guard !hasHydratedProfileEditor else {
            return
        }

        draftName = model.profile.name
        draftIntention = model.profile.intention
        draftWakeTime = model.profile.wakeDate
        draftFocusTrack = model.profile.focusTrack
        draftAnchors = model.profile.anchors
        hasHydratedProfileEditor = true
    }

    private func toggleDraftAnchor(_ anchor: HabitAnchor) {
        if let index = draftAnchors.firstIndex(of: anchor) {
            if draftAnchors.count > 1 {
                draftAnchors.remove(at: index)
            }
        } else {
            draftAnchors.append(anchor)
        }
    }

    private func saveProfile() async {
        let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIntention = draftIntention.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            profileMessage = "Add a name before saving."
            return
        }

        isSavingProfile = true
        defer { isSavingProfile = false }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: draftWakeTime)

        model.profile.name = trimmedName
        model.profile.intention = trimmedIntention.isEmpty
            ? "Move with clarity and make today's climb count."
            : trimmedIntention
        model.profile.focusTrack = draftFocusTrack
        model.profile.anchors = draftAnchors.isEmpty ? [.movement] : draftAnchors
        model.profile.wakeUpHour = components.hour ?? 7
        model.profile.wakeUpMinute = components.minute ?? 0

        if session.user != nil {
            await session.updateDisplayName(trimmedName)
        }

        if let errorMessage = session.errorMessage, !errorMessage.isEmpty {
            profileMessage = errorMessage
        } else {
            profileMessage = "Profile updated."
        }
    }

    private func importAvatar(from item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                profileMessage = "That photo could not be loaded."
                return
            }

            guard let image = UIImage(data: data),
                  let compressedData = image.jpegData(compressionQuality: 0.86) else {
                profileMessage = "That photo format is not supported."
                return
            }

            try model.saveProfileAvatar(data: compressedData)
            profileMessage = "Profile photo updated."
        } catch {
            profileMessage = error.localizedDescription
        }
    }
}

private struct ProfileAvatarView: View {
    let localURL: URL?
    let remoteURL: URL?
    let initials: String

    var body: some View {
        ZStack {
            Circle()
                .fill(AIscendTheme.Colors.accentPrimary.opacity(0.18))
                .frame(width: 88, height: 88)
                .overlay(
                    Circle()
                        .stroke(AIscendTheme.Colors.accentGlow.opacity(0.34), lineWidth: AIscendTheme.Stroke.thin)
                )

            if let localURL,
               let image = UIImage(contentsOfFile: localURL.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 88, height: 88)
                    .clipShape(Circle())
            } else if let remoteURL {
                AsyncImage(url: remoteURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Text(initials.isEmpty ? "AI" : initials)
                            .aiscendTextStyle(.metricCompact)
                    }
                }
                .frame(width: 88, height: 88)
                .clipShape(Circle())
            } else {
                Text(initials.isEmpty ? "AI" : initials)
                    .aiscendTextStyle(.metricCompact)
            }
        }
    }
}

#Preview {
    AppShellView(model: AppModel(), session: AuthSessionStore())
}
