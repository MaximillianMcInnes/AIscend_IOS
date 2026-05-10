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

private enum RoutineWorkspaceTab: String, CaseIterable, Identifiable {
    case routine
    case exercises
    case tracking

    var id: String { rawValue }

    var title: String {
        switch self {
        case .routine:
            "Routine"
        case .exercises:
            "Exercises"
        case .tracking:
            "Tracking"
        }
    }
}

private enum RoutinePlanTab: String, CaseIterable, Identifiable {
    case daily
    case skinCare
    case weekly
    case leaderboard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily:
            "Daily"
        case .skinCare:
            "Skin Care"
        case .weekly:
            "Weekly"
        case .leaderboard:
            "Leaderboard"
        }
    }
}

private enum RoutineTrackerTab: String, CaseIterable, Identifiable {
    case hydration
    case electrolytes
    case calories

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hydration:
            "Hydration"
        case .electrolytes:
            "Electrolytes"
        case .calories:
            "Calories"
        }
    }
}

struct RoutineCleanSlateView: View {
    @Bindable var model: AppModel
    @ObservedObject var dailyCheckInStore: DailyCheckInStore
    @ObservedObject var hydrationStore: HydrationTrackingStore
    @ObservedObject var electrolyteStore: ElectrolyteTrackingStore
    @ObservedObject var badgeManager: BadgeManager
    let onOpenCheckIn: () -> Void
    let onOpenConsistency: () -> Void
    let onOpenHydrationChat: (String) -> Void
    let onOpenNutrition: () -> Void
    let onRefine: () -> Void

    @State private var selectedTab: RoutineWorkspaceTab = .routine
    @State private var selectedRoutinePlanTab: RoutinePlanTab = .daily
    @State private var selectedTrackerTab: RoutineTrackerTab = .hydration
    @State private var showingJawTraining = false
    @StateObject private var jawTrainingStore = JawTrainingStore()

    private var baseWaterSummary: WaterDailySummary {
        hydrationStore.todaySummary()
    }

    private var hydrationElectrolyteSummary: ElectrolyteDailySummary {
        electrolyteStore.todaySummary(waterIntakeMl: baseWaterSummary.totalWaterMl)
    }

    private var hydrationWaterSummary: WaterDailySummary {
        hydrationStore.todaySummary(electrolyteSummary: hydrationElectrolyteSummary)
    }

    private var hydrationCompletionCount: Int {
        [
            hydrationWaterSummary.hydrationState == .optimal || hydrationWaterSummary.hydrationState == .high,
            hydrationElectrolyteSummary.balanceState == .balanced
        ]
        .filter { $0 }
        .count
    }

    private var hydrationHeroTitle: String {
        if hydrationWaterSummary.totalWaterMl == 0 {
            return "Hydration ready"
        }

        return "\(HydrationTrackingEngine.formatWater(hydrationWaterSummary.totalWaterMl, prefersCompact: true)) logged"
    }

    private var hydrationHeroDetail: String {
        hydrationStore.combinedInsight(electrolyteSummary: hydrationElectrolyteSummary)
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    routineHeader
                    routineTabBar
                    selectedRoutineContent
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Layout.floatingTabBarClearance)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingJawTraining) {
            JawTrainingView(store: jawTrainingStore)
        }
    }

    private var routineHeader: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            AIscendBadge(
                title: "Routine OS",
                symbol: "sparkles",
                style: .accent
            )

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
                    routineTitle
                    routineStreakButton
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    routineTitle
                    routineStreakButton
                }
            }

            Text("Daily execution, facial exercise planning, and health tracking in one calmer routine workspace.")
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
        }
    }

    private var routineTitle: some View {
        Text("Routine")
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundStyle(AIscendTheme.Colors.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
    }

    private var routineStreakButton: some View {
        Button(action: onOpenConsistency) {
            RoutineStreakBadge(
                streakDays: dailyCheckInStore.snapshot.currentStreak,
                checkedInToday: dailyCheckInStore.hasCheckedInToday
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open daily streak")
    }

    private var routineTabBar: some View {
        RoutineWorkspaceToggle(selection: $selectedTab)
    }

    @ViewBuilder
    private var selectedRoutineContent: some View {
        switch selectedTab {
        case .routine:
            routineHero
            RoutinePlanToggle(selection: $selectedRoutinePlanTab)
            selectedRoutinePlanContent
        case .exercises:
            exerciseRoutinePlaceholderTab
        case .tracking:
            routineHero
            trackersTab
        }
    }

    @ViewBuilder
    private var selectedRoutinePlanContent: some View {
        switch selectedRoutinePlanTab {
        case .daily:
            dailyRoutineTab
        case .skinCare:
            skinCareRoutineTab
        case .weekly:
            weeklyRoutineTab
        case .leaderboard:
            leaderboardComingSoonTab
        }
    }

    private var nutritionEntryCard: some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            onOpenNutrition()
        } label: {
            HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentPrimary.opacity(0.28),
                                    AIscendTheme.Colors.accentCyan.opacity(0.14)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(AIscendTheme.Colors.accentGlow.opacity(0.34), lineWidth: 1)
                        )

                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    HStack(spacing: AIscendTheme.Spacing.xSmall) {
                        AIscendBadge(
                            title: "Nutrition OS",
                            symbol: "sparkles",
                            style: .accent
                        )

                        AIscendBadge(
                            title: "AI facial impact",
                            symbol: "face.smiling.inverse",
                            style: .neutral
                        )
                    }

                    Text("Aesthetic nutrition intelligence")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .multilineTextAlignment(.leading)

                    Text("Calories, macros, sodium, hydration, and recovery mapped to puffiness risk, skin support, and jawline sharpness.")
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)
            }
            .padding(AIscendTheme.Spacing.large)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.cardGradientStart.opacity(0.97),
                                AIscendTheme.Colors.accentPrimary.opacity(0.18),
                                AIscendTheme.Colors.cardGradientEnd.opacity(0.98)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                    .stroke(AIscendTheme.Colors.accentGlow.opacity(0.24), lineWidth: 1)
            )
            .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.14), radius: 26, x: 0, y: 14)
        }
        .buttonStyle(.plain)
    }

    private var jawTrainingEntryCard: some View {
        Button {
            showingJawTraining = true
        } label: {
            HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(RoutineAccent.sky.gradient.opacity(0.24))
                        .frame(width: 64, height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(AIscendTheme.Colors.accentGlow.opacity(0.34), lineWidth: 1)
                        )

                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    HStack(spacing: AIscendTheme.Spacing.xSmall) {
                        AIscendBadge(
                            title: jawTrainingStore.hasCompletedToday ? "Completed today" : "Jaw Training",
                            symbol: jawTrainingStore.hasCompletedToday ? "checkmark.seal.fill" : "sparkles",
                            style: jawTrainingStore.hasCompletedToday ? .success : .accent
                        )

                        AIscendBadge(
                            title: "\(jawTrainingStore.currentStreak)d streak",
                            symbol: "flame.fill",
                            style: .neutral
                        )
                    }

                    Text("Facial posture and tension reset")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .multilineTextAlignment(.leading)

                    Text("Gentle jaw, neck, and tongue posture routines with safety notes and local completion tracking.")
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.accentGlow)
            }
            .padding(AIscendTheme.Spacing.large)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.cardGradientStart.opacity(0.96),
                                AIscendTheme.Colors.accentDeep.opacity(0.28),
                                AIscendTheme.Colors.cardGradientEnd.opacity(0.98)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                    .stroke(AIscendTheme.Colors.accentGlow.opacity(0.24), lineWidth: 1)
            )
            .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.12), radius: 24, x: 0, y: 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Jaw Training")
    }

    private var routineHero: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    Text(routineHeroEyebrow)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                    Text(routineHeroTitle)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)

                    Text(routineHeroDetail)
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: AIscendTheme.Spacing.xSmall) {
                    Text("LVL \(model.routineLevel)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)

                    Text("\(model.routineXP) XP")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                HStack {
                    Text("XP progress")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                    Spacer()

                    Text("\(model.xpIntoCurrentLevel)/\(model.xpRequiredForNextLevel)")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                }

                RoutineSlateProgressBar(progress: max(model.xpProgress, 0.04))
            }
        }
        .padding(AIscendTheme.Spacing.xLarge)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "111114").opacity(0.96),
                            AIscendTheme.Colors.secondaryBackground.opacity(0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(AIscendTheme.Colors.accentGlow.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.42), radius: 28, x: 0, y: 18)
    }

    private var routineHeroEyebrow: String {
        switch selectedTab {
        case .routine:
            "Today's progress"
        case .exercises:
            "Facial exercise"
        case .tracking:
            selectedTrackerTab.title
        }
    }

    private var routineHeroTitle: String {
        switch selectedTab {
        case .routine:
            "\(model.completedRoutineCount)/\(max(model.totalRoutineCount, 1)) complete"
        case .exercises:
            "Routine builder coming soon"
        case .tracking:
            hydrationHeroTitle
        }
    }

    private var routineHeroDetail: String {
        switch selectedTab {
        case .routine:
            model.nextOpenStep?.detail ?? "Everything is handled. Keep the streak protected and close the day cleanly."
        case .exercises:
            "A guided facial exercise routine space is being staged for jaw, posture, and tension work."
        case .tracking:
            hydrationHeroDetail
        }
    }

    private var dailyRoutineTab: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    RoutineSlateMetric(
                        title: "Completion",
                        value: model.progressLabel,
                        detail: model.currentLevelTitle,
                        accent: .sky
                    )

                    RoutineSlateMetric(
                        title: "Live streak",
                        value: "\(dailyCheckInStore.snapshot.currentStreak)d",
                        detail: dailyCheckInStore.hasCheckedInToday ? "Protected today" : "Still open",
                        accent: .mint
                    )

                    RoutineSlateMetric(
                        title: "Badges",
                        value: "\(badgeManager.earnedCount)",
                        detail: "Quiet rewards",
                        accent: .dawn
                    )
                }

                VStack(spacing: AIscendTheme.Spacing.small) {
                    RoutineSlateMetric(
                        title: "Completion",
                        value: model.progressLabel,
                        detail: model.currentLevelTitle,
                        accent: .sky
                    )

                    RoutineSlateMetric(
                        title: "Live streak",
                        value: "\(dailyCheckInStore.snapshot.currentStreak)d",
                        detail: dailyCheckInStore.hasCheckedInToday ? "Protected today" : "Still open",
                        accent: .mint
                    )

                    RoutineSlateMetric(
                        title: "Badges",
                        value: "\(badgeManager.earnedCount)",
                        detail: "Quiet rewards",
                        accent: .dawn
                    )
                }
            }

            ForEach(model.dailyRoutineSections) { section in
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                    HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
                        AIscendIconOrb(symbol: section.steps.first?.symbol ?? "checkmark.circle", accent: section.accent, size: 40)

                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                            Text(section.title)
                                .aiscendTextStyle(.cardTitle)

                            Text(section.subtitle)
                                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                        }
                    }

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        ForEach(section.steps) { step in
                            routineChecklistRow(step)
                        }
                    }
                }
                .padding(AIscendTheme.Spacing.large)
                .aiscendPanel(.elevated)
            }
        }
    }

    private var skinCareRoutineTab: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendEditorialHeroCard(
                eyebrow: "Skin Care",
                title: "Daily skin support",
                subtitle: "A simple AM and PM care layer for consistency, texture support, and recovery without overloading the routine.",
                accent: .mint
            ) {
                VStack(spacing: AIscendTheme.Spacing.small) {
                    routineCareRow(title: "Morning cleanse", detail: "Reset oil and sleep buildup before the day starts.", symbol: "drop.fill", accent: .sky)
                    routineCareRow(title: "Moisturizer", detail: "Keep the barrier supported before training or outdoor time.", symbol: "sparkles", accent: .mint)
                    routineCareRow(title: "SPF check", detail: "Protect progress from UV exposure and texture drift.", symbol: "sun.max.fill", accent: .dawn)
                    routineCareRow(title: "Evening reset", detail: "Cleanse, calm, and let the skin recover overnight.", symbol: "moon.stars.fill", accent: .sky)
                }
            }
        }
    }

    private var weeklyRoutineTab: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendEditorialHeroCard(
                eyebrow: "Weekly",
                title: "Plan the bigger rhythm",
                subtitle: "Use the weekly layer for lower-frequency care, progress review, and recovery choices that do not need to be daily chores.",
                accent: .dawn
            ) {
                VStack(spacing: AIscendTheme.Spacing.small) {
                    routineCareRow(title: "Progress photo review", detail: "Compare lighting, angles, and notes once a week.", symbol: "photo.on.rectangle.angled", accent: .sky)
                    routineCareRow(title: "De-puff reset", detail: "Pick one lower-sodium, higher-potassium day if the week ran heavy.", symbol: "leaf.fill", accent: .mint)
                    routineCareRow(title: "Routine tune-up", detail: "Adjust your anchors around what actually happened this week.", symbol: "slider.horizontal.3", accent: .dawn)
                }
            }

            VStack(spacing: AIscendTheme.Spacing.small) {
                Button(action: onOpenCheckIn) {
                    AIscendButtonLabel(
                        title: dailyCheckInStore.hasCheckedInToday ? "Review Daily Check-In" : "Complete Daily Check-In",
                        leadingSymbol: "calendar.badge.checkmark"
                    )
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))

                Button(action: onRefine) {
                    AIscendButtonLabel(title: "Refine Plan", leadingSymbol: "slider.horizontal.3")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
            }
        }
    }

    private var leaderboardComingSoonTab: some View {
        RoutineComingSoonCard(
            eyebrow: "Leaderboard",
            title: "Leaderboard coming soon",
            subtitle: "A low-pressure XP board for consistency, streaks, and routine completion is being prepared.",
            symbol: "trophy.fill",
            accent: .dawn
        )
    }

    private var exerciseRoutinePlaceholderTab: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            RoutineComingSoonCard(
                eyebrow: "Exercises",
                title: "Facial exercise routine",
                subtitle: "A guided placeholder for jaw relaxation, tongue posture, neck alignment, and facial tension work.",
                symbol: "face.smiling.inverse",
                accent: .sky
            )

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendSectionHeader(
                    eyebrow: "Preview",
                    title: "Routine structure",
                    subtitle: "The final flow will keep exercise short, safe, and repeatable."
                )

                routineCareRow(title: "Warm-up", detail: "Gentle neck and jaw mobility before any hold.", symbol: "wind", accent: .sky)
                routineCareRow(title: "Posture set", detail: "Tongue posture, shoulder position, and nasal breathing cues.", symbol: "figure.mind.and.body", accent: .mint)
                routineCareRow(title: "Tension release", detail: "Masseter and temple relaxation work with safety limits.", symbol: "waveform.path.ecg", accent: .dawn)
            }
            .padding(AIscendTheme.Spacing.large)
            .aiscendPanel(.elevated)
        }
    }

    private var planTab: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendEditorialHeroCard(
                eyebrow: "Plan",
                title: "What today is built around",
                subtitle: "Keep the planning layer brief so it guides the day instead of replacing action.",
                accent: .sky
            ) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        AIscendStatChip(title: "Focus", value: model.profile.focusTrack.title, symbol: model.profile.focusTrack.symbol, accent: .sky)
                        AIscendStatChip(title: "Wake", value: model.profile.wakeLabel, symbol: "alarm.fill", accent: .dawn)
                        AIscendStatChip(title: "XP title", value: model.currentLevelTitle, symbol: "sparkles.rectangle.stack", accent: .mint)
                    }

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        AIscendStatChip(title: "Focus", value: model.profile.focusTrack.title, symbol: model.profile.focusTrack.symbol, accent: .sky)
                        AIscendStatChip(title: "Wake", value: model.profile.wakeLabel, symbol: "alarm.fill", accent: .dawn)
                        AIscendStatChip(title: "XP title", value: model.currentLevelTitle, symbol: "sparkles.rectangle.stack", accent: .mint)
                    }
                }
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendSectionHeader(
                    eyebrow: "Intent",
                    title: "Main directive",
                    subtitle: model.profile.intention
                )
            }
            .padding(AIscendTheme.Spacing.large)
            .aiscendPanel(.elevated)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendSectionHeader(
                    eyebrow: "Anchors",
                    title: "Stability drivers",
                    subtitle: "These are the behaviors supporting the day when motivation is inconsistent."
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                    ForEach(model.profile.anchors, id: \.self) { anchor in
                        AIscendCapsule(title: anchor.title, symbol: anchor.symbol, isActive: true)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AIscendTheme.Spacing.xSmall)
                    }
                }
            }
            .padding(AIscendTheme.Spacing.large)
            .aiscendPanel(.standard)

            VStack(spacing: AIscendTheme.Spacing.small) {
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

                Button(action: onRefine) {
                    AIscendButtonLabel(title: "Refine Plan", leadingSymbol: "slider.horizontal.3")
                }
                .buttonStyle(AIscendButtonStyle(variant: .ghost))
            }
        }
    }

    private var trackersTab: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            RoutineTrackerToggle(selection: $selectedTrackerTab)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    RoutineSlateMetric(
                        title: "Water",
                        value: HydrationTrackingEngine.formatWater(hydrationWaterSummary.totalWaterMl, prefersCompact: true),
                        detail: "Target \(HydrationTrackingEngine.formatWater(hydrationWaterSummary.targetWaterMl, prefersCompact: true))",
                        accent: .mint
                    )

                    RoutineSlateMetric(
                        title: "Balance",
                        value: hydrationElectrolyteSummary.balanceState.title,
                        detail: "\(hydrationCompletionCount)/2 signals aligned",
                        accent: .dawn
                    )
                }

                VStack(spacing: AIscendTheme.Spacing.small) {
                    RoutineSlateMetric(
                        title: "Water",
                        value: HydrationTrackingEngine.formatWater(hydrationWaterSummary.totalWaterMl, prefersCompact: true),
                        detail: "Target \(HydrationTrackingEngine.formatWater(hydrationWaterSummary.targetWaterMl, prefersCompact: true))",
                        accent: .mint
                    )

                    RoutineSlateMetric(
                        title: "Balance",
                        value: hydrationElectrolyteSummary.balanceState.title,
                        detail: "\(hydrationCompletionCount)/2 signals aligned",
                        accent: .dawn
                    )
                }
            }

            switch selectedTrackerTab {
            case .hydration:
                hydrationTrackerCard
            case .electrolytes:
                electrolyteTrackerCard
            case .calories:
                caloriesComingSoonCard
            }
        }
    }

    private var hydrationTrackerCard: some View {
        RoutineTrackerDetailCard(
            eyebrow: "Hydration",
            title: "\(HydrationTrackingEngine.formatWater(hydrationWaterSummary.totalWaterMl, prefersCompact: true)) logged",
            subtitle: hydrationWaterSummary.shortInsight,
            accent: .mint,
            progress: hydrationWaterSummary.progress,
            progressLabel: "Target \(HydrationTrackingEngine.formatWater(hydrationWaterSummary.targetWaterMl, prefersCompact: true))",
            stats: [
                RoutineTrackerStat(title: "Logged", value: HydrationTrackingEngine.formatWater(hydrationWaterSummary.totalWaterMl, prefersCompact: true), symbol: "drop.fill", accent: .mint),
                RoutineTrackerStat(title: "Status", value: hydrationWaterSummary.hydrationState.title, symbol: "gauge.with.dots.needle.50percent", accent: .sky),
                RoutineTrackerStat(title: "Entries", value: "\(hydrationWaterSummary.entries.count)", symbol: "list.bullet.clipboard.fill", accent: .dawn)
            ],
            actions: [
                RoutineTrackerAction(
                    id: "hydration-remove",
                    title: "Remove Last Log",
                    symbol: "minus",
                    variant: .secondary,
                    action: { hydrationStore.removeLastEntry() }
                ),
                RoutineTrackerAction(
                    id: "hydration-plus",
                    title: "Add 250 ml",
                    symbol: "plus",
                    variant: .primary,
                    action: { hydrationStore.addWater(amountMl: 250, sourceName: "Routine quick add") }
                )
            ]
        )
    }

    private var electrolyteTrackerCard: some View {
        RoutineTrackerDetailCard(
            eyebrow: "Electrolytes",
            title: hydrationElectrolyteSummary.balanceState.title,
            subtitle: hydrationElectrolyteSummary.shortInsight,
            accent: .dawn,
            progress: electrolyteProgress,
            progressLabel: "\(hydrationElectrolyteSummary.entries.count) logs today",
            stats: [
                RoutineTrackerStat(title: "Sodium", value: "\(hydrationElectrolyteSummary.totalSodiumMg) mg", symbol: "bolt.heart.fill", accent: .dawn),
                RoutineTrackerStat(title: "Potassium", value: "\(hydrationElectrolyteSummary.totalPotassiumMg) mg", symbol: "leaf.fill", accent: .mint),
                RoutineTrackerStat(title: "Magnesium", value: "\(hydrationElectrolyteSummary.totalMagnesiumMg) mg", symbol: "capsule.fill", accent: .sky)
            ],
            actions: electrolyteQuickActions
        )
    }

    private var caloriesComingSoonCard: some View {
        RoutineComingSoonCard(
            eyebrow: "Calories",
            title: "Calories coming soon",
            subtitle: "Calories will return as a dedicated nutrition tracker once the food logging flow is ready for this tab.",
            symbol: "fork.knife.circle.fill",
            accent: .dawn
        )
    }

    private var electrolyteProgress: Double {
        switch hydrationElectrolyteSummary.balanceState {
        case .balanced:
            1
        case .moderate:
            0.66
        case .low, .lowSodiumHighWater, .highSodiumLowPotassium:
            0.38
        case .unknown:
            0.08
        }
    }

    private var electrolyteQuickActions: [RoutineTrackerAction] {
        Array(electrolyteStore.presets.prefix(2)).enumerated().map { index, preset in
            RoutineTrackerAction(
                id: "electrolyte-\(preset.id)",
                title: "Add \(preset.title)",
                symbol: preset.iconName,
                variant: index == 0 ? .primary : .secondary,
                action: { electrolyteStore.addPreset(preset) }
            )
        }
    }

    private var calorieProgressLabel: String {
        let remaining = model.trackerState.calorieGoal - model.trackerState.caloriesLogged
        return remaining >= 0 ? "\(remaining) kcal remaining" : "\(abs(remaining)) kcal above target"
    }

    private var calorieStatusLabel: String {
        if model.trackerState.caloriesLogged == 0 {
            return "Not started"
        }

        return model.trackerState.caloriesLogged > model.trackerState.calorieGoal ? "Above target" : "On track"
    }

    private func trackerProgress(_ value: Int, goal: Int) -> Double {
        guard goal > 0 else {
            return 0
        }

        return min(max(Double(value) / Double(goal), 0), 1)
    }

    private func routineChecklistRow(_ step: RoutineStep) -> some View {
        Button {
            withAnimation(AIscendTheme.Motion.reveal) {
                model.toggleStep(step.id)
            }

            badgeManager.recordRoutineProgress(
                progress: model.progress,
                streak: dailyCheckInStore.snapshot.currentStreak
            )
        } label: {
            HStack(spacing: AIscendTheme.Spacing.medium) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            step.isComplete
                                ? AnyShapeStyle(step.accent.gradient)
                                : AnyShapeStyle(AIscendTheme.Colors.surfaceHighlight.opacity(0.8))
                        )
                        .frame(width: 28, height: 28)

                    if step.isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(step.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .strikethrough(step.isComplete, color: AIscendTheme.Colors.textMuted.opacity(0.8))

                    Text(step.detail)
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Text("+\(xpRewardLabel(for: step.id)) XP")
                    .aiscendTextStyle(.caption, color: step.accent.tint)
            }
            .padding(.horizontal, AIscendTheme.Spacing.medium)
            .padding(.vertical, AIscendTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.68))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .stroke(step.isComplete ? step.accent.tint.opacity(0.34) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func routineCareRow(title: String, detail: String, symbol: String, accent: RoutineAccent) -> some View {
        HStack(spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: symbol, accent: accent, size: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)

                Text(detail)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(accent.tint.opacity(0.18), lineWidth: 1)
        )
    }

    private func xpRewardLabel(for stepID: String) -> Int {
        switch stepID {
        case "mission", "pace":
            12
        case "deep-work", "noise-down":
            18
        case "primary-anchor", "secondary-anchor":
            14
        default:
            10
        }
    }
}

private struct RoutineWorkspaceToggle: View {
    @Binding var selection: RoutineWorkspaceTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(RoutineWorkspaceTab.allCases) { tab in
                Button {
                    withAnimation(AIscendTheme.Motion.reveal) {
                        selection = tab
                    }
                } label: {
                    Text(tab.title)
                        .aiscendTextStyle(.caption, color: selection == tab ? .white : AIscendTheme.Colors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, AIscendTheme.Spacing.xxSmall)
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    selection == tab
                                        ? AnyShapeStyle(RoutineAccent.sky.gradient)
                                        : AnyShapeStyle(Color.clear)
                                )
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(
                                    selection == tab ? AIscendTheme.Colors.accentGlow.opacity(0.5) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.24))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct RoutinePlanToggle: View {
    @Binding var selection: RoutinePlanTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(RoutinePlanTab.allCases) { tab in
                Button {
                    withAnimation(AIscendTheme.Motion.reveal) {
                        selection = tab
                    }
                } label: {
                    Text(tab.title)
                        .aiscendTextStyle(.caption, color: selection == tab ? .white : AIscendTheme.Colors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .padding(.horizontal, AIscendTheme.Spacing.xxSmall)
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    selection == tab
                                        ? AnyShapeStyle(RoutineAccent.mint.gradient)
                                        : AnyShapeStyle(Color.clear)
                                )
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(
                                    selection == tab ? AIscendTheme.Colors.accentGlow.opacity(0.46) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.24))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct RoutineTrackerToggle: View {
    @Binding var selection: RoutineTrackerTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(RoutineTrackerTab.allCases) { tab in
                Button {
                    withAnimation(AIscendTheme.Motion.reveal) {
                        selection = tab
                    }
                } label: {
                    Text(tab.title)
                        .aiscendTextStyle(.caption, color: selection == tab ? .white : AIscendTheme.Colors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, AIscendTheme.Spacing.xxSmall)
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    selection == tab
                                        ? AnyShapeStyle(RoutineAccent.mint.gradient)
                                        : AnyShapeStyle(Color.clear)
                                )
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(
                                    selection == tab ? AIscendTheme.Colors.accentGlow.opacity(0.5) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.24))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct RoutineTrackerStat: Identifiable {
    let id: String
    let title: String
    let value: String
    let symbol: String
    let accent: RoutineAccent

    init(title: String, value: String, symbol: String, accent: RoutineAccent) {
        self.id = title
        self.title = title
        self.value = value
        self.symbol = symbol
        self.accent = accent
    }
}

private struct RoutineTrackerAction: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let variant: AIscendButtonVariant
    let action: () -> Void
}

private struct RoutineTrackerDetailCard: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let accent: RoutineAccent
    let progress: Double
    let progressLabel: String
    let stats: [RoutineTrackerStat]
    let actions: [RoutineTrackerAction]

    var body: some View {
        AIscendEditorialHeroCard(
            eyebrow: eyebrow,
            title: title,
            subtitle: subtitle,
            accent: accent
        ) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    HStack {
                        Text("Progress")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                        Spacer()

                        Text(progressLabel)
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                    }

                    RoutineSlateProgressBar(progress: max(progress, 0.04))
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        ForEach(stats) { stat in
                            AIscendStatChip(
                                title: stat.title,
                                value: stat.value,
                                symbol: stat.symbol,
                                accent: stat.accent
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        ForEach(stats) { stat in
                            AIscendStatChip(
                                title: stat.title,
                                value: stat.value,
                                symbol: stat.symbol,
                                accent: stat.accent
                            )
                        }
                    }
                }

                VStack(spacing: AIscendTheme.Spacing.small) {
                    ForEach(actions) { action in
                        Button(action: action.action) {
                            AIscendButtonLabel(title: action.title, leadingSymbol: action.symbol)
                        }
                        .buttonStyle(AIscendButtonStyle(variant: action.variant))
                    }
                }
            }
        }
    }
}

private struct RoutineComingSoonCard: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let symbol: String
    let accent: RoutineAccent

    var body: some View {
        AIscendEditorialHeroCard(
            eyebrow: eyebrow,
            title: title,
            subtitle: subtitle,
            accent: accent
        ) {
            HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(accent.gradient.opacity(0.22))
                        .frame(width: 64, height: 64)

                    Image(systemName: symbol)
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    AIscendBadge(title: "Coming soon", symbol: "clock.fill", style: .neutral)

                    Text("Preview mode")
                        .aiscendTextStyle(.cardTitle)

                    Text("The space is ready for the finished flow without making the feature feel live too early.")
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

struct MoreHubView: View {
    @Bindable var model: AppModel
    @Bindable var session: AuthSessionStore
    @ObservedObject var dailyCheckInStore: DailyCheckInStore
    @ObservedObject var badgeManager: BadgeManager
    @ObservedObject var notificationManager: NotificationManager
    @State private var selectedTab: MoreHubTab = .profile

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    NavigationLink(value: MoreHubDestination.profile) {
                        MoreHubTabChip(tab: .profile, isSelected: selectedTab == .profile)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        selectedTab = .profile
                    })
                    .buttonStyle(.plain)

                    ForEach(MoreHubTab.placeholderTabs) { tab in
                        NavigationLink(value: tab.destination) {
                            MoreHubTabChip(tab: tab, isSelected: selectedTab == tab)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            selectedTab = tab
                        })
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Layout.floatingTabBarClearance)

                Spacer(minLength: 0)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: MoreHubDestination.self) { destination in
            switch destination {
            case .profile:
                AccountView(
                    model: model,
                    session: session,
                    dailyCheckInStore: dailyCheckInStore,
                    badgeManager: badgeManager,
                    notificationManager: notificationManager
                )
            case .lookalike:
                MoreLabDetailView(section: .lookalike)
            case .skinLab:
                MoreLabDetailView(section: .skinLab)
            }
        }
    }
}

private enum MoreHubTab: String, CaseIterable, Identifiable {
    case profile = "Profile"
    case lookalike = "Lookalike"
    case skinLab = "Skin Lab"

    var id: String { rawValue }

    static var placeholderTabs: [MoreHubTab] {
        [.lookalike, .skinLab]
    }

    var symbol: String {
        switch self {
        case .profile:
            "person.crop.circle.fill"
        case .lookalike:
            "person.2.fill"
        case .skinLab:
            "sparkles"
        }
    }

    var destination: MoreHubDestination {
        switch self {
        case .profile:
            .profile
        case .lookalike:
            .lookalike
        case .skinLab:
            .skinLab
        }
    }
}

private enum MoreHubDestination: Hashable {
    case profile
    case lookalike
    case skinLab
}

private struct MoreHubTabChip: View {
    let tab: MoreHubTab
    let isSelected: Bool

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: tab.symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? AIscendTheme.Colors.textPrimary : AIscendTheme.Colors.textSecondary)

            Text(tab.rawValue)
                .aiscendTextStyle(
                    .caption,
                    color: isSelected ? AIscendTheme.Colors.textPrimary : AIscendTheme.Colors.textSecondary
                )
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(
                    isSelected
                    ? AIscendTheme.Colors.surfaceHighlight.opacity(0.96)
                    : AIscendTheme.Colors.surfaceMuted.opacity(0.82)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(
                    isSelected
                    ? AIscendTheme.Colors.accentGlow.opacity(0.34)
                    : AIscendTheme.Colors.borderSubtle,
                    lineWidth: 1
                )
        )
    }
}

private enum MoreHubSection: String, CaseIterable, Identifiable {
    case profile = "Profile"
    case lookalike = "Lookalike"
    case skinLab = "Skin Lab"
    case threeDLab = "3D Lab"

    var id: String { rawValue }

    var title: String { rawValue }

    var symbol: String {
        switch self {
        case .profile:
            "person.crop.circle.fill"
        case .lookalike:
            "person.2.fill"
        case .skinLab:
            "sparkles"
        case .threeDLab:
            "cube.fill"
        }
    }

    var accent: RoutineAccent {
        switch self {
        case .profile:
            .sky
        case .lookalike:
            .dawn
        case .skinLab:
            .mint
        case .threeDLab:
            .sky
        }
    }

    var heroEyebrow: String {
        switch self {
        case .profile:
            "Profile"
        case .lookalike:
            "Instant match"
        case .skinLab:
            "Skin diagnostics"
        case .threeDLab:
            "Spatial read"
        }
    }

    var heroTitle: String {
        switch self {
        case .profile:
            "Profile"
        case .lookalike:
            "Celebrity Lookalike"
        case .skinLab:
            "Skin Lab"
        case .threeDLab:
            "3D Lab"
        }
    }

    var heroSubtitle: String {
        switch self {
        case .profile:
            "Your private AIscend workspace"
        case .lookalike:
            "Fast similarity matching, reference stacks, and aesthetic inspiration boards are being shaped into a one-tap experience."
        case .skinLab:
            "Texture reads, clarity tracking, and routine-response visuals are being built as a calmer diagnostics layer."
        case .threeDLab:
            "Depth-guided face maps, angle replay, and structure overlays are on deck for a more spatial read of progress."
        }
    }

    var modeLabel: String {
        switch self {
        case .profile:
            "Live"
        case .lookalike:
            "Style"
        case .skinLab:
            "Analysis"
        case .threeDLab:
            "Depth"
        }
    }

    var rootSummary: String {
        switch self {
        case .profile:
            "Open your full profile page with account identity, routine settings, and workspace controls."
        case .lookalike:
            "Preview the future similarity and reference engine as its own dedicated lab page."
        case .skinLab:
            "Open the upcoming skin diagnostics surface with cleaner tracking and visual feedback."
        case .threeDLab:
            "Step into the future 3D structure page for depth, angle, and symmetry experiments."
        }
    }

    var previewTitle: String {
        switch self {
        case .profile:
            "Profile"
        case .lookalike:
            "A fast celebrity-reference layer without turning the app into a gimmick"
        case .skinLab:
            "A cleaner diagnostics board for tone, texture, and routine feedback"
        case .threeDLab:
            "A spatial lab for structure, angles, and 3D-style visual context"
        }
    }

    var previewBody: String {
        switch self {
        case .profile:
            "Profile"
        case .lookalike:
            "The goal is instant visual payoff: take a scan, surface strong public-reference matches, and translate them into styling ideas that still feel aligned with your own face."
        case .skinLab:
            "This lab is aimed at sharper feedback loops around skin quality, not louder dashboards. Expect cleaner scoring, visual overlays, and easier before-and-after reads."
        case .threeDLab:
            "3D Lab is being designed as a premium-feeling structure surface with depth-aware comparisons, rotation previews, and a more architectural read of change over time."
        }
    }

    var teasers: [MoreHubTeaser] {
        switch self {
        case .profile:
            return []
        case .lookalike:
            return [
                MoreHubTeaser(title: "Instant match", detail: "One-tap celebrity similarity board with ranked visual matches.", symbol: "bolt.fill", accent: .dawn),
                MoreHubTeaser(title: "Reference wall", detail: "Swipe through styling references that echo your strongest facial cues.", symbol: "square.stack.fill", accent: .sky),
                MoreHubTeaser(title: "Vibe transfer", detail: "Translate public looks into grounded haircut, beard, or framing ideas.", symbol: "sparkles", accent: .mint)
            ]
        case .skinLab:
            return [
                MoreHubTeaser(title: "Texture map", detail: "See surface changes with cleaner visual emphasis instead of noisy charts.", symbol: "waveform.path.ecg", accent: .mint),
                MoreHubTeaser(title: "Barrier read", detail: "Track recovery, irritation risk, and support signals in one place.", symbol: "shield.fill", accent: .sky),
                MoreHubTeaser(title: "Routine response", detail: "Understand what products and habits are actually moving the skin.", symbol: "drop.fill", accent: .dawn)
            ]
        case .threeDLab:
            return [
                MoreHubTeaser(title: "Depth mesh", detail: "Preview a more dimensional read of face structure and volume.", symbol: "cube.fill", accent: .sky),
                MoreHubTeaser(title: "Angle replay", detail: "Spin through saved viewpoints and compare them more naturally.", symbol: "rotate.right.fill", accent: .dawn),
                MoreHubTeaser(title: "Symmetry volume", detail: "Spot asymmetry and structural balance with a stronger spatial frame.", symbol: "square.grid.3x3.fill", accent: .mint)
            ]
        }
    }
}

private struct MoreHubTeaser: Identifiable {
    let title: String
    let detail: String
    let symbol: String
    let accent: RoutineAccent

    var id: String { title }
}

private struct MoreHubSectionChip: View {
    let section: MoreHubSection
    let isSelected: Bool

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: section.symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? AIscendTheme.Colors.textPrimary : AIscendTheme.Colors.textSecondary)

            Text(section.title)
                .aiscendTextStyle(.caption, color: isSelected ? AIscendTheme.Colors.textPrimary : AIscendTheme.Colors.textSecondary)
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            Capsule(style: .continuous)
                .fill(
                    isSelected
                    ? AnyShapeStyle(section.accent.gradient)
                    : AnyShapeStyle(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
                )
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(
                    isSelected ? section.accent.tint.opacity(0.20) : AIscendTheme.Colors.borderSubtle,
                    lineWidth: 1
                )
        )
        .shadow(color: isSelected ? section.accent.glow : .clear, radius: 18, x: 0, y: 8)
    }
}

private struct MoreHubTeaserCard: View {
    let teaser: MoreHubTeaser

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(alignment: .top) {
                AIscendIconOrb(symbol: teaser.symbol, accent: teaser.accent, size: 42)

                Spacer(minLength: 0)

                AIscendBadge(title: "Soon", symbol: "clock.fill", style: .neutral)
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                Text(teaser.title)
                    .aiscendTextStyle(.cardTitle)

                Text(teaser.detail)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 176, alignment: .topLeading)
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.elevated)
    }
}

private struct MoreHubDestinationCard: View {
    let section: MoreHubSection

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: section.symbol, accent: section.accent, size: 48)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                HStack(spacing: AIscendTheme.Spacing.xSmall) {
                    Text(section.title)
                        .aiscendTextStyle(.cardTitle)

                    if section != .profile {
                        AIscendBadge(title: "Preview", symbol: "clock.fill", style: .neutral)
                    }
                }

                Text(section.rootSummary)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AIscendTheme.Spacing.small)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AIscendTheme.Colors.textMuted)
        }
        .padding(AIscendTheme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceMuted.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .stroke(section.accent.tint.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct MoreLabDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let section: MoreHubSection

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
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
                        .accessibilityLabel("Close \(section.title)")

                        Spacer(minLength: 0)
                    }

                    AIscendEditorialHeroCard(
                        eyebrow: section.heroEyebrow,
                        title: section.heroTitle,
                        subtitle: section.heroSubtitle,
                        accent: section.accent
                    ) {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                            AIscendBadge(
                                title: "Coming soon",
                                symbol: "clock.fill",
                                style: .accent
                            )

                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: AIscendTheme.Spacing.small) {
                                    AIscendStatChip(title: "Status", value: "Preview", symbol: "sparkles", accent: section.accent)
                                    AIscendStatChip(title: "Mode", value: section.modeLabel, symbol: section.symbol, accent: section.accent)
                                    AIscendStatChip(title: "Launch", value: "Soon", symbol: "arrow.up.right", accent: .dawn)
                                }

                                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                                    AIscendStatChip(title: "Status", value: "Preview", symbol: "sparkles", accent: section.accent)
                                    AIscendStatChip(title: "Mode", value: section.modeLabel, symbol: section.symbol, accent: section.accent)
                                    AIscendStatChip(title: "Launch", value: "Soon", symbol: "arrow.up.right", accent: .dawn)
                                }
                            }
                        }
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                        ForEach(section.teasers) { teaser in
                            MoreHubTeaserCard(teaser: teaser)
                        }
                    }

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                        AIscendBadge(
                            title: "Early preview",
                            symbol: "square.stack.fill",
                            style: .neutral
                        )

                        Text(section.previewTitle)
                            .aiscendTextStyle(.sectionTitle)

                        Text(section.previewBody)
                            .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    }
                    .padding(AIscendTheme.Spacing.large)
                    .aiscendPanel(.hero)
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Layout.floatingTabBarClearance)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct RoutineSlateMetric: View {
    let title: String
    let value: String
    let detail: String
    let accent: RoutineAccent

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)

            Text(detail)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(accent.tint.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct RoutineStreakBadge: View {
    let streakDays: Int
    let checkedInToday: Bool

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: checkedInToday ? "flame.fill" : "flame")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AIscendTheme.Colors.accentAmber)

            Text("\(streakDays)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.88))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.accentAmber.opacity(0.28), lineWidth: 1)
        )
    }
}

private struct RoutineSlateProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.6))

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.accentGlow,
                                AIscendTheme.Colors.accentPrimary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(14, geometry.size.width * progress))
            }
        }
        .frame(height: 10)
    }
}

private struct ProfileSignalCard: View {
    let title: String
    let value: String
    let detail: String
    let accent: RoutineAccent

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)

            Text(detail)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AIscendTheme.Spacing.mediumLarge)
        .padding(.vertical, AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.86))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accent.tint.opacity(0.16), lineWidth: 1)
        )
    }
}

private struct ProfileActionRow: View {
    let title: String
    let detail: String
    let symbol: String
    let accent: RoutineAccent
    var destructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AIscendTheme.Spacing.medium) {
                AIscendIconOrb(symbol: symbol, accent: accent, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(destructive ? AIscendTheme.Colors.error : AIscendTheme.Colors.textPrimary)

                    Text(detail)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                }

                Spacer(minLength: AIscendTheme.Spacing.small)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.textMuted)
            }
            .padding(.horizontal, AIscendTheme.Spacing.large)
            .padding(.vertical, AIscendTheme.Spacing.mediumLarge)
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileActionDivider: View {
    var body: some View {
        Rectangle()
            .fill(AIscendTheme.Colors.borderSubtle)
            .frame(height: 1)
            .padding(.horizontal, AIscendTheme.Spacing.large)
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
                .padding(.bottom, AIscendTheme.Layout.floatingTabBarClearance)
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
        AIscendEditorialHeroCard(
            eyebrow: "Routine blueprint",
            title: "Your current operating structure",
            subtitle: "AIScend is applying the following routine model. Refine onboarding any time you want to alter the tempo or intent.",
            accent: .sky
        ) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    AIscendStatChip(title: "Focus", value: model.profile.focusTrack.title, symbol: model.profile.focusTrack.symbol, accent: .sky)
                    AIscendStatChip(title: "Wake", value: model.profile.wakeLabel, symbol: "alarm.fill", accent: .dawn)
                    AIscendStatChip(title: "Anchors", value: "\(max(model.profile.anchors.count, 1)) active", symbol: "sparkles.rectangle.stack", accent: .mint)
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    AIscendStatChip(title: "Focus", value: model.profile.focusTrack.title, symbol: model.profile.focusTrack.symbol, accent: .sky)
                    AIscendStatChip(title: "Wake", value: model.profile.wakeLabel, symbol: "alarm.fill", accent: .dawn)
                    AIscendStatChip(title: "Anchors", value: "\(max(model.profile.anchors.count, 1)) active", symbol: "sparkles.rectangle.stack", accent: .mint)
                }
            }
        }
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

                    ForEach(Array(section.steps.enumerated()), id: \.element.id) { index, step in
                        routineStepRow(
                            step: step,
                            index: index + 1,
                            isLast: index == section.steps.count - 1
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

    private func routineStepRow(step: RoutineStep, index: Int, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(step.accent.gradient.opacity(0.24))
                        .frame(width: 34, height: 34)

                    Text("\(index)")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                }

                if !isLast {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(step.accent.tint.opacity(0.22))
                        .frame(width: 2, height: 34)
                        .padding(.top, AIscendTheme.Spacing.xSmall)
                }
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    AIscendIconOrb(symbol: step.symbol, accent: step.accent, size: 38)

                    Text(step.title)
                        .aiscendTextStyle(.cardTitle)
                }

                Text(step.detail)
                    .aiscendTextStyle(.body)
            }

            Spacer()
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.68))
                .overlay(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                        .fill(Color.white.opacity(0.02))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
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
    @State private var isDeletingAccount = false
    @State private var showingAccountDeletionConfirmation = false
    @State private var hasHydratedProfileEditor = false
    @State private var subscriptionQuota: AIscendChatQuota = .unknown
    @State private var isLoadingSubscription = true
    @State private var scanArchive: [PersistedScanRecord] = []
    @State private var isLoadingScanStats = true

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    topBar
                    profileIdentitySection
                    profileSubscriptionSection
                    profileScanStatsSection
                    profileProgressSection
                    profileSettingsSection
                    profilePrivacySection
                    profileLogoutSection

                    if let errorMessage = session.errorMessage {
                        profileMessageSection(title: "Auth status", message: errorMessage)
                    } else if let configurationMessage = session.configurationMessage {
                        profileMessageSection(title: "Firebase setup", message: configurationMessage)
                    }
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Layout.floatingTabBarClearance)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            "Delete account?",
            isPresented: $showingAccountDeletionConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete account", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your AIscend account and clears this device's account data. You may need to sign in again first if the session is old.")
        }
        .task {
            await notificationManager.refreshAuthorizationStatus()
            hydrateProfileEditorIfNeeded()
            await refreshProfileStatus()
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

    private var topBar: some View {
        HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
            AIscendTopBarButton(symbol: "chevron.left", action: { dismiss() })

            AIscendBadge(
                title: "Profile",
                symbol: "person.crop.circle.fill",
                style: .neutral
            )

            Spacer(minLength: 0)
        }
    }

    private var profileIdentitySection: some View {
        ProfileSectionCard(
            eyebrow: "Identity",
            title: displayName,
            subtitle: primaryEmail,
            symbol: "person.crop.circle.fill",
            accent: .sky,
            tone: .hero
        ) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .center, spacing: AIscendTheme.Spacing.mediumLarge) {
                    ProfileAvatarView(
                        localURL: model.profileAvatarURL,
                        remoteURL: session.user?.photoURL,
                        initials: session.user?.initials ?? String(model.profile.displayName.prefix(2)).uppercased(),
                        size: 76
                    )

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        ProfileStatusPill(
                            title: session.user == nil ? "Local profile" : "Signed in",
                            symbol: session.user == nil ? "iphone" : "checkmark.seal.fill",
                            accent: session.user == nil ? .dawn : .mint
                        )

                        Text(session.providerSummary)
                            .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                            .lineLimit(2)

                        Text("Your account identity, routine preferences, and private progress live here.")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                            .lineLimit(3)
                    }
                }

                ViewThatFits(in: .horizontal) {
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
                                AIscendButtonLabel(title: "Remove", leadingSymbol: "trash")
                            }
                            .buttonStyle(AIscendButtonStyle(variant: .ghost))
                        }
                    }

                    VStack(spacing: AIscendTheme.Spacing.small) {
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
                            .buttonStyle(AIscendButtonStyle(variant: .ghost))
                        }
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

                if let profileMessage {
                    Text(profileMessage)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var profileSubscriptionSection: some View {
        ProfileSectionCard(
            eyebrow: "Subscription",
            title: hasPremiumAccess ? "Premium layer active" : "Free layer",
            subtitle: subscriptionDetail,
            symbol: hasPremiumAccess ? "crown.fill" : "lock.open.fill",
            accent: hasPremiumAccess ? .sky : .dawn,
            tone: hasPremiumAccess ? .hero : .standard
        ) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                if isLoadingSubscription {
                    ProfileLoadingRows()
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: AIscendTheme.Spacing.small) {
                            ProfileMetricTile(
                                title: "Status",
                                value: hasPremiumAccess ? "Premium" : "Free",
                                detail: hasPremiumAccess ? "Full access signal" : "Preview access",
                                symbol: hasPremiumAccess ? "crown.fill" : "person.fill",
                                accent: hasPremiumAccess ? .sky : .dawn
                            )

                            ProfileMetricTile(
                                title: "Advisor",
                                value: subscriptionQuota.compactLabel,
                                detail: subscriptionQuota.sourceDescription ?? "Current account limits",
                                symbol: "message.fill",
                                accent: .mint
                            )
                        }

                        VStack(spacing: AIscendTheme.Spacing.small) {
                            ProfileMetricTile(
                                title: "Status",
                                value: hasPremiumAccess ? "Premium" : "Free",
                                detail: hasPremiumAccess ? "Full access signal" : "Preview access",
                                symbol: hasPremiumAccess ? "crown.fill" : "person.fill",
                                accent: hasPremiumAccess ? .sky : .dawn
                            )

                            ProfileMetricTile(
                                title: "Advisor",
                                value: subscriptionQuota.compactLabel,
                                detail: subscriptionQuota.sourceDescription ?? "Current account limits",
                                symbol: "message.fill",
                                accent: .mint
                            )
                        }
                    }
                }
            }
        }
    }

    private var profileScanStatsSection: some View {
        ProfileSectionCard(
            eyebrow: "Scan stats",
            title: "Archive signal",
            subtitle: latestScanSubtitle,
            symbol: "viewfinder.circle.fill",
            accent: .mint
        ) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                if isLoadingScanStats {
                    ProfileLoadingRows()
                } else if scanArchive.isEmpty {
                    ProfileEmptyState(
                        title: "No scans archived yet",
                        detail: "Run your first scan to build a private baseline and start tracking the read over time.",
                        symbol: "viewfinder"
                    )
                } else {
                    LazyVGrid(columns: profileMetricColumns, spacing: AIscendTheme.Spacing.small) {
                        ProfileMetricTile(
                            title: "Scans",
                            value: "\(scanArchive.count)",
                            detail: "Saved locally",
                            symbol: "tray.full.fill",
                            accent: .sky
                        )
                        ProfileMetricTile(
                            title: "Latest",
                            value: latestScoreText,
                            detail: latestScan?.tierTitle ?? "No score",
                            symbol: "sparkles.rectangle.stack.fill",
                            accent: .dawn
                        )
                        ProfileMetricTile(
                            title: "Best",
                            value: bestScoreText,
                            detail: "Highest archived score",
                            symbol: "arrow.up.right",
                            accent: .mint
                        )
                        ProfileMetricTile(
                            title: "Access",
                            value: latestScan?.accessLevel.profileTitle ?? "None",
                            detail: latestScanDateText,
                            symbol: latestScan?.accessLevel == .premium ? "crown.fill" : "lock.open.fill",
                            accent: latestScan?.accessLevel == .premium ? .sky : .dawn
                        )
                    }
                }
            }
        }
    }

    private var profileProgressSection: some View {
        ProfileSectionCard(
            eyebrow: "Progress",
            title: "Streak and routine summary",
            subtitle: dailyCheckInStore.snapshot.statusTitle,
            symbol: dailyCheckInStore.hasCheckedInToday ? "checkmark.seal.fill" : "flame.fill",
            accent: .dawn
        ) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                LazyVGrid(columns: profileMetricColumns, spacing: AIscendTheme.Spacing.small) {
                    ProfileMetricTile(
                        title: "Current streak",
                        value: "\(dailyCheckInStore.snapshot.currentStreak)d",
                        detail: dailyCheckInStore.hasCheckedInToday ? "Protected today" : "Open today",
                        symbol: "flame.fill",
                        accent: .dawn
                    )
                    ProfileMetricTile(
                        title: "Best streak",
                        value: "\(dailyCheckInStore.snapshot.bestStreak)d",
                        detail: "\(dailyCheckInStore.snapshot.totalCheckIns) check-ins",
                        symbol: "scope",
                        accent: .mint
                    )
                    ProfileMetricTile(
                        title: "Routine",
                        value: model.progressLabel,
                        detail: "\(model.completedRoutineCount) of \(model.totalRoutineCount) steps",
                        symbol: "square.grid.2x2.fill",
                        accent: .sky
                    )
                    ProfileMetricTile(
                        title: "Badges",
                        value: "\(badgeManager.earnedCount)",
                        detail: badgeManager.earnedBadges.first?.title ?? "No badges yet",
                        symbol: "sparkles",
                        accent: .mint
                    )
                }

                ProfileWeeklyProgressStrip(
                    title: "7-day check-in rate",
                    completed: dailyCheckInStore.completionCount(days: 7),
                    total: 7
                )

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        Button {
                            showingDailyCheckIn = true
                        } label: {
                            AIscendButtonLabel(
                                title: dailyCheckInStore.hasCheckedInToday ? "Review Check-In" : "Complete Check-In",
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

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        Button {
                            showingDailyCheckIn = true
                        } label: {
                            AIscendButtonLabel(
                                title: dailyCheckInStore.hasCheckedInToday ? "Review Check-In" : "Complete Check-In",
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
            }
        }
    }

    private var profileSettingsSection: some View {
        ProfileSectionCard(
            eyebrow: "Settings",
            title: "Routine controls",
            subtitle: "Keep the account surface clean and the daily system tuned.",
            symbol: "slider.horizontal.3",
            accent: .sky
        ) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    Text("Climb statement")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                    TextEditor(text: $draftIntention)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .font(.system(size: 15, weight: .regular))
                        .frame(minHeight: 86)
                        .padding(AIscendTheme.Spacing.small)
                        .background(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                .fill(AIscendTheme.Colors.fieldFill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                    ProfileInfoRow(
                        title: "Wake-up time",
                        detail: model.profile.wakeLabel,
                        symbol: "alarm.fill",
                        accent: .dawn
                    ) {
                        DatePicker(
                            "Wake-up time",
                            selection: $draftWakeTime,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }

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
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    }
                    .padding(AIscendTheme.Spacing.medium)
                    .aiscendPanel(.muted)
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    Text("Habit anchors")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                    LazyVGrid(columns: profileMetricColumns, spacing: AIscendTheme.Spacing.small) {
                        ForEach(HabitAnchor.allCases) { anchor in
                            Button {
                                toggleDraftAnchor(anchor)
                            } label: {
                                ProfileAnchorChip(
                                    title: anchor.title,
                                    symbol: anchor.symbol,
                                    isSelected: draftAnchors.contains(anchor)
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
        }
    }

    private var profilePrivacySection: some View {
        ProfileSectionCard(
            eyebrow: "Privacy & security",
            title: "Account controls",
            subtitle: session.user == nil ? "Local profile mode" : "Firebase-authenticated session",
            symbol: "lock.shield.fill",
            accent: .mint
        ) {
            VStack(spacing: AIscendTheme.Spacing.small) {
                ProfileInfoRow(
                    title: "Provider",
                    detail: session.providerSummary,
                    symbol: "person.badge.key.fill",
                    accent: .sky
                )

                ProfileInfoRow(
                    title: "Notifications",
                    detail: "\(notificationManager.preferences.enabledCount) active · \(notificationManager.authorizationState.badgeTitle)",
                    symbol: "bell.badge.fill",
                    accent: .dawn
                )

                ProfileInfoRow(
                    title: "Local data",
                    detail: "Profile settings, streaks, and archived scan summaries stay on this device unless synced by an app feature.",
                    symbol: "iphone.gen3",
                    accent: .mint
                )

                Button {
                    withAnimation(AIscendTheme.Motion.reveal) {
                        model.resetOnboarding()
                    }
                } label: {
                    ProfileActionButton(title: "Refine onboarding", detail: "Retune goals and first-run preferences.", symbol: "slider.horizontal.3", accent: .sky)
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(AIscendTheme.Motion.reveal) {
                        model.resetRoutineProgress()
                    }
                } label: {
                    ProfileActionButton(title: "Reset today's progress", detail: "Clear only the current routine completion state.", symbol: "arrow.counterclockwise", accent: .dawn)
                }
                .buttonStyle(.plain)

                Button {
                    showingAccountDeletionConfirmation = true
                } label: {
                    ProfileActionButton(
                        title: isDeletingAccount ? "Deleting account" : "Delete account",
                        detail: "Permanently remove the account and clear local account data.",
                        symbol: "trash.fill",
                        accent: .dawn,
                        destructive: true
                    )
                }
                .buttonStyle(.plain)
                .disabled(isDeletingAccount || session.isPerformingAuthAction)
                .accessibilityIdentifier("profile-delete-account-button")
            }
        }
    }

    private var profileLogoutSection: some View {
        Button {
            session.signOut()
        } label: {
            HStack(spacing: AIscendTheme.Spacing.medium) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 17, weight: .bold))

                Text("Log out")
                    .aiscendTextStyle(.buttonLabel, color: AIscendTheme.Colors.textPrimary)

                Spacer()
            }
            .padding(AIscendTheme.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(AIscendTheme.Colors.error.opacity(0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .stroke(AIscendTheme.Colors.error.opacity(0.32), lineWidth: AIscendTheme.Stroke.thin)
            )
        }
        .buttonStyle(.plain)
    }

    private var displayName: String {
        let value = session.user?.displayName ?? model.profile.displayName
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? "AIScend profile" : trimmedValue
    }

    private var primaryEmail: String {
        let value = session.user?.email ?? ""
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? "Local profile mode" : trimmedValue
    }

    private var hasPremiumAccess: Bool {
        subscriptionQuota.isPremium || badgeManager.earnedBadges.contains(where: { $0.id == .premiumUnlocked })
    }

    private var subscriptionDetail: String {
        if isLoadingSubscription {
            return "Checking account access..."
        }

        return hasPremiumAccess
            ? "Full advisor and results access is active."
            : "Preview access is active with upgrade paths available."
    }

    private var latestScan: PersistedScanRecord? {
        scanArchive
            .filter(\.isDisplayable)
            .max { lhs, rhs in
                (lhs.savedAt ?? .distantPast) < (rhs.savedAt ?? .distantPast)
            }
    }

    private var bestScan: PersistedScanRecord? {
        scanArchive
            .filter(\.isDisplayable)
            .max { lhs, rhs in
                lhs.overallScore < rhs.overallScore
            }
    }

    private var latestScanSubtitle: String {
        guard let latestScan else {
            return "No archived scans yet."
        }

        return "Latest result saved \(formattedScanDate(latestScan.savedAt))."
    }

    private var latestScoreText: String {
        scoreText(latestScan?.overallScore)
    }

    private var bestScoreText: String {
        scoreText(bestScan?.overallScore)
    }

    private var latestScanDateText: String {
        formattedScanDate(latestScan?.savedAt)
    }

    private var profileMetricColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: AIscendTheme.Spacing.small),
            GridItem(.flexible(), spacing: AIscendTheme.Spacing.small)
        ]
    }

    private func profileMessageSection(title: String, message: String) -> some View {
        messagePanel(title: title, message: message)
    }

    private func formattedScanDate(_ date: Date?) -> String {
        guard let date else {
            return "No scan date"
        }

        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private func scoreText(_ value: Double?) -> String {
        guard let value, value.isFinite else {
            return "--"
        }

        return "\(Int(value.rounded()))"
    }

    private func refreshProfileStatus() async {
        // Performance: profile data is fetched from task scope instead of from body/onAppear loops.
        async let archive = ScanResultsRepository().loadPersistedArchive()
        async let repositoryQuota = AIscendChatRepository().loadQuota(
            for: session.user?.email,
            userID: session.user?.id
        )
        async let authQuota = AIscendChatService().loadAuthQuotaSnapshot()

        let loadedArchive = await archive
            .filter(\.isDisplayable)
            .sorted { lhs, rhs in
                (lhs.savedAt ?? .distantPast) > (rhs.savedAt ?? .distantPast)
            }
        let resolvedQuota = mergeQuota(repository: await repositoryQuota, auth: await authQuota)

        scanArchive = loadedArchive
        subscriptionQuota = resolvedQuota
        isLoadingScanStats = false
        isLoadingSubscription = false
    }

    private func mergeQuota(repository: AIscendChatQuota, auth: AIscendChatQuota) -> AIscendChatQuota {
        var merged = repository
        merged.isPremium = repository.isPremium || auth.isPremium

        if merged.remainingChats == nil {
            merged.remainingChats = auth.remainingChats
        }

        if merged.monthlyLimit == nil {
            merged.monthlyLimit = auth.monthlyLimit
        }

        if merged.usedChats == nil {
            merged.usedChats = auth.usedChats
        }

        merged.trialEligible = repository.trialEligible && auth.trialEligible

        if merged.sourceDescription == nil {
            merged.sourceDescription = auth.sourceDescription
        }

        return merged
    }

    private var userPanel: some View {
        AIscendEditorialHeroCard(
            eyebrow: "Profile hub",
            title: session.user?.displayName ?? model.profile.displayName,
            subtitle: session.user?.subtitle ?? "Local profile",
            accent: .sky
        ) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.mediumLarge) {
                    ProfileAvatarView(
                        localURL: model.profileAvatarURL,
                        remoteURL: session.user?.photoURL,
                        initials: session.user?.initials ?? String(model.profile.displayName.prefix(2)).uppercased()
                    )

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        Text(session.providerSummary)
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                        Text("A cleaner identity surface for your account, routine posture, and personal operating settings.")
                            .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: AIscendTheme.Spacing.small) {
                                AIscendStatChip(title: "Mode", value: model.profile.focusTrack.title, symbol: model.profile.focusTrack.symbol, accent: .sky)
                                AIscendStatChip(title: "Wake", value: model.profile.wakeLabel, symbol: "alarm.fill", accent: .dawn)
                            }

                            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                                AIscendStatChip(title: "Mode", value: model.profile.focusTrack.title, symbol: model.profile.focusTrack.symbol, accent: .sky)
                                AIscendStatChip(title: "Wake", value: model.profile.wakeLabel, symbol: "alarm.fill", accent: .dawn)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    Text("Climb statement")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                    Text(model.profile.intention)
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AIscendTheme.Spacing.mediumLarge)
                        .background(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.78))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )
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
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                .fill(AIscendTheme.Colors.fieldFill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                }

                if let profileMessage {
                    Text(profileMessage)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                }
            }
        }
    }

    private var profileSnapshotPanel: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendSectionHeader(
                eyebrow: "Snapshot",
                title: "Your profile at a glance",
                subtitle: "See the identity, consistency, and habit structure together before changing settings."
            )

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    ProfileSignalCard(
                        title: "Streak",
                        value: "\(dailyCheckInStore.snapshot.currentStreak)d",
                        detail: dailyCheckInStore.hasCheckedInToday ? "Protected today" : "Still open",
                        accent: .dawn
                    )
                    ProfileSignalCard(
                        title: "Badges",
                        value: "\(badgeManager.earnedCount)",
                        detail: badgeManager.earnedBadges.first?.title ?? "Quiet progress",
                        accent: .mint
                    )
                    ProfileSignalCard(
                        title: "Reminders",
                        value: "\(notificationManager.preferences.enabledCount)",
                        detail: notificationManager.authorizationState.badgeTitle,
                        accent: .sky
                    )
                }

                VStack(spacing: AIscendTheme.Spacing.small) {
                    ProfileSignalCard(
                        title: "Streak",
                        value: "\(dailyCheckInStore.snapshot.currentStreak)d",
                        detail: dailyCheckInStore.hasCheckedInToday ? "Protected today" : "Still open",
                        accent: .dawn
                    )
                    ProfileSignalCard(
                        title: "Badges",
                        value: "\(badgeManager.earnedCount)",
                        detail: badgeManager.earnedBadges.first?.title ?? "Quiet progress",
                        accent: .mint
                    )
                    ProfileSignalCard(
                        title: "Reminders",
                        value: "\(notificationManager.preferences.enabledCount)",
                        detail: notificationManager.authorizationState.badgeTitle,
                        accent: .sky
                    )
                }
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                Text("Active anchors")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                    ForEach(model.profile.anchors.isEmpty ? [.movement] : model.profile.anchors, id: \.self) { anchor in
                        AIscendCapsule(title: anchor.title, symbol: anchor.symbol, isActive: true)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AIscendTheme.Spacing.xSmall)
                    }
                }
            }
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.standard)
    }

    private var routineStatePanel: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendSectionHeader(
                eyebrow: "Preferences",
                title: "Tune how your profile behaves",
                subtitle: "Keep the account identity and routine layer aligned in one place."
            )

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
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

            ProfileActionDivider()

            Button {
                showingAccountDeletionConfirmation = true
            } label: {
                AIscendButtonLabel(
                    title: isDeletingAccount ? "Deleting account" : "Delete account",
                    leadingSymbol: "trash.fill"
                )
            }
            .buttonStyle(AIscendButtonStyle(variant: .destructive))
            .disabled(isDeletingAccount || session.isPerformingAuthAction)
            .accessibilityIdentifier("profile-delete-account-button")
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

    private func deleteAccount() async {
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        let didDelete = await session.deleteAccount()
        if didDelete {
            model.clearLocalAccountData()
        } else if let errorMessage = session.errorMessage, !errorMessage.isEmpty {
            profileMessage = errorMessage
        }
    }

    private func importAvatar(from item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                profileMessage = "That photo could not be loaded."
                return
            }

            guard let compressedData = await Task.detached(priority: .userInitiated, operation: {
                UIImage(data: data)?.jpegData(compressionQuality: 0.86)
            }).value else {
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

private struct ProfileSectionCard<Content: View>: View {
    enum Tone {
        case standard
        case hero
    }

    let eyebrow: String
    let title: String
    let subtitle: String
    let symbol: String
    let accent: RoutineAccent
    var tone: Tone = .standard
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                AIscendIconOrb(symbol: symbol, accent: accent, size: tone == .hero ? 50 : 42)

                AIscendSectionHeader(
                    eyebrow: eyebrow,
                    title: title,
                    subtitle: subtitle,
                    prominence: tone == .hero ? .hero : .standard
                )
            }

            content
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(tone == .hero ? .hero : .standard)
    }
}

private struct ProfileStatusPill: View {
    let title: String
    let symbol: String
    let accent: RoutineAccent

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
        }
        .foregroundStyle(AIscendTheme.Colors.textPrimary)
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 8)
        .background(Capsule(style: .continuous).fill(accent.tint.opacity(0.18)))
        .overlay(Capsule(style: .continuous).stroke(accent.tint.opacity(0.30), lineWidth: 1))
    }
}

private struct ProfileLoadingRows: View {
    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.62))
                    .frame(height: 48)
                    .redacted(reason: .placeholder)
            }
        }
    }
}

private struct ProfileEmptyState: View {
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            AIscendIconOrb(symbol: symbol, accent: .sky, size: 42)

            Text(title)
                .aiscendTextStyle(.cardTitle)

            Text(detail)
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .aiscendPanel(.muted)
    }
}

private struct ProfileMetricTile: View {
    let title: String
    let value: String
    let detail: String
    let symbol: String
    let accent: RoutineAccent

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            AIscendIconOrb(symbol: symbol, accent: accent, size: 36)

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            Text(value)
                .aiscendTextStyle(.cardTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(detail)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .aiscendPanel(.muted)
    }
}

private struct ProfileWeeklyProgressStrip: View {
    let title: String
    let completed: Int
    let total: Int

    private var progress: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(min(max(completed, 0), total)) / CGFloat(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                Spacer()

                Text("\(min(max(completed, 0), total))/\(total)")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    .monospacedDigit()
            }

            GeometryReader { geometry in
                Capsule(style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceInteractive.opacity(0.66))
                    .overlay(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(AIscendTheme.Colors.accentGlow)
                            .frame(width: max(8, geometry.size.width * progress))
                    }
            }
            .frame(height: 8)
        }
        .padding(AIscendTheme.Spacing.medium)
        .aiscendPanel(.muted)
    }
}

private struct ProfileInfoRow<Trailing: View>: View {
    let title: String
    let detail: String
    let symbol: String
    let accent: RoutineAccent
    @ViewBuilder let trailing: Trailing

    init(
        title: String,
        detail: String,
        symbol: String,
        accent: RoutineAccent,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.detail = detail
        self.symbol = symbol
        self.accent = accent
        self.trailing = trailing()
    }

    init(
        title: String,
        detail: String,
        symbol: String,
        accent: RoutineAccent
    ) where Trailing == EmptyView {
        self.init(title: title, detail: detail, symbol: symbol, accent: accent) {
            EmptyView()
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: symbol, accent: accent, size: 38)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                Text(detail)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AIscendTheme.Spacing.small)

            trailing
        }
        .padding(AIscendTheme.Spacing.medium)
        .aiscendPanel(.muted)
    }
}

private struct ProfileAnchorChip: View {
    let title: String
    let symbol: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))

            Text(title)
                .aiscendTextStyle(.buttonLabel, color: AIscendTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.76)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(isSelected ? AIscendTheme.Colors.accentPrimary.opacity(0.18) : AIscendTheme.Colors.surfaceHighlight.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(isSelected ? AIscendTheme.Colors.accentGlow.opacity(0.38) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct ProfileActionButton: View {
    let title: String
    let detail: String
    let symbol: String
    let accent: RoutineAccent
    var destructive = false

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: symbol, accent: accent, size: 38)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(title)
                    .aiscendTextStyle(.buttonLabel, color: AIscendTheme.Colors.textPrimary)

                Text(detail)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AIscendTheme.Colors.textMuted)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill((destructive ? AIscendTheme.Colors.error : accent.tint).opacity(destructive ? 0.14 : 0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke((destructive ? AIscendTheme.Colors.error : accent.tint).opacity(0.28), lineWidth: 1)
        )
    }
}

private extension ScanResultsAccess {
    var profileTitle: String {
        switch self {
        case .free:
            "Free"
        case .premium:
            "Premium"
        }
    }
}

struct ProfileAvatarView: View {
    let localURL: URL?
    let remoteURL: URL?
    let initials: String
    var size: CGFloat = 88

    var body: some View {
        ZStack {
            Circle()
                .fill(AIscendTheme.Colors.accentPrimary.opacity(0.18))
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(AIscendTheme.Colors.accentGlow.opacity(0.34), lineWidth: AIscendTheme.Stroke.thin)
                )

            if localURL != nil || remoteURL != nil {
                AIscendCachedImage(
                    localURL: localURL,
                    remoteURL: remoteURL,
                    maxPixelDimension: size * 3
                ) {
                    fallbackInitials
                }
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                fallbackInitials
            }
        }
        .frame(width: size, height: size)
    }

    private var fallbackInitials: some View {
        Text(initials.isEmpty ? "AI" : initials)
            .font(.system(size: max(13, size * 0.3), weight: .bold, design: .rounded))
            .foregroundStyle(AIscendTheme.Colors.textPrimary)
    }
}

#Preview {
    AppShellView(model: AppModel(), session: AuthSessionStore())
}
