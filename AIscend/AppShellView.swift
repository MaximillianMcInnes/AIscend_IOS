//
//  AppShellView.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import SwiftUI

struct AppShellView: View {
    @Bindable var model: AppModel
    @Bindable var session: AuthSessionStore

    var body: some View {
        TabView {
            NavigationStack {
                AIscendChatScreenContainer(session: session)
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem {
                Label("Advisor", systemImage: "message.fill")
            }

            NavigationStack {
                RoutineDashboardView(model: model)
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem {
                Label("Today", systemImage: "waveform.path.ecg")
            }

            NavigationStack {
                RoutineBlueprintView(model: model)
                    .aiscendNavigationChrome()
            }
            .tabItem {
                Label("Routine", systemImage: "square.grid.2x2.fill")
            }

            NavigationStack {
                AccountView(model: model, session: session)
                    .aiscendNavigationChrome()
            }
            .tabItem {
                Label("Account", systemImage: "person.crop.circle.fill")
            }
        }
        .tint(AIscendTheme.Colors.accentGlow)
        .toolbarBackground(AIscendTheme.Colors.secondaryBackground.opacity(0.96), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}

private struct RoutineBlueprintView: View {
    @Bindable var model: AppModel

    var body: some View {
        ZStack {
            AIscendBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                    blueprintHero
                    intentionPanel
                    anchorPanel
                    routineSections
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
        }
        .navigationTitle("Routine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(AIscendTheme.Motion.reveal) {
                        model.resetOnboarding()
                    }
                } label: {
                    Text("Refine")
                        .aiscendTextStyle(.buttonLabel, color: AIscendTheme.Colors.textPrimary)
                }
            }
        }
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

private struct AccountView: View {
    @Bindable var model: AppModel
    @Bindable var session: AuthSessionStore

    var body: some View {
        ZStack {
            AIscendBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                    userPanel
                    routineStatePanel
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
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var userPanel: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            HStack {
                AIscendBadge(
                    title: "Identity",
                    symbol: "person.crop.rectangle.stack.fill",
                    style: .accent
                )

                Spacer()
            }

            HStack(spacing: AIscendTheme.Spacing.mediumLarge) {
                ZStack {
                    Circle()
                        .fill(AIscendTheme.Colors.accentPrimary.opacity(0.18))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(AIscendTheme.Colors.accentGlow.opacity(0.34), lineWidth: AIscendTheme.Stroke.thin)
                        )

                    Text(session.user?.initials ?? "AI")
                        .aiscendTextStyle(.metricCompact)
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text(session.user?.displayName ?? "Signed-in user")
                        .aiscendTextStyle(.sectionTitle)

                    Text(session.user?.subtitle ?? "No email available")
                        .aiscendTextStyle(.body)

                    Text(session.providerSummary)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                }
            }

            if let photoURL = session.user?.photoURL {
                Text(photoURL.absoluteString)
                    .aiscendTextStyle(.caption)
                    .lineLimit(1)
            }
        }
        .padding(AIscendTheme.Spacing.xLarge)
        .aiscendPanel(.hero)
    }

    private var routineStatePanel: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendSectionHeader(
                eyebrow: "State",
                title: "Current dashboard metrics",
                subtitle: "A quick readout of the account-linked routine profile."
            )

            HStack(spacing: AIscendTheme.Spacing.small) {
                AIscendMetricCard(
                    title: "Progress",
                    value: model.progressLabel,
                    detail: "Completion of the active daily sequence.",
                    symbol: "chart.pie.fill",
                    accent: .sky,
                    highlighted: true
                )
                AIscendMetricCard(
                    title: "Focus",
                    value: model.profile.focusTrack.title,
                    detail: model.profile.focusTrack.routinePrompt,
                    symbol: model.profile.focusTrack.symbol,
                    accent: .dawn
                )
            }

            HStack(spacing: AIscendTheme.Spacing.small) {
                AIscendMetricCard(
                    title: "Wake-up",
                    value: model.profile.wakeLabel,
                    detail: "Configured launch time for the routine.",
                    symbol: "alarm.fill",
                    accent: .dawn
                )
                AIscendMetricCard(
                    title: "Anchors",
                    value: "\(model.profile.anchors.count)",
                    detail: model.profile.anchorSummary,
                    symbol: "sparkles",
                    accent: .mint
                )
            }
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.standard)
    }

    private var actionsPanel: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendSectionHeader(
                eyebrow: "Actions",
                title: "Manage this workspace",
                subtitle: "Keep the environment current without disturbing your account state."
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

    private func messagePanel(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendBadge(title: title, symbol: "info.circle.fill", style: .neutral)

            Text(message)
                .aiscendTextStyle(.body)
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.muted)
    }
}

#Preview {
    AppShellView(model: AppModel(), session: AuthSessionStore())
}
