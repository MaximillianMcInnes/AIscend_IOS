//
//  FacialTrainingView.swift
//  AIscend
//
//  Created by Codex on 5/10/26.
//

import SwiftUI

struct FacialTrainingView: View {
    @ObservedObject var store: FacialTrainingStore
    let onDismiss: () -> Void

    @State private var activeRoutine: FacialRoutine?
    @State private var showingPlan = false
    @State private var showingOnboarding = false

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            if store.hasGeneratedPlan {
                trainingDashboard
            } else {
                FacialTrainingOnboardingView(store: store)
            }
        }
        .safeAreaInset(edge: .top) {
            topBar
        }
        .sheet(isPresented: $showingPlan) {
            FacialTrainingPlanView(store: store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: $activeRoutine) { routine in
            FacialTrainingSessionView(routine: routine, store: store)
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            AIscendBadge(title: store.syncState.title, symbol: "bolt.horizontal.circle.fill", style: .neutral)
            Spacer(minLength: 0)
            AIscendTopBarButton(symbol: "xmark", highlighted: false, action: onDismiss)
                .accessibilityLabel("Close Facial Training")
        }
        .padding(.horizontal, AIscendTheme.Spacing.screenInset)
        .padding(.top, AIscendTheme.Spacing.small)
        .padding(.bottom, AIscendTheme.Spacing.xSmall)
        .background(.ultraThinMaterial.opacity(0.18))
    }

    private var trainingDashboard: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                header
                if let routine = store.todayRoutine {
                    todayHero(routine)
                    weeklySnapshot
                    planActions(routine)
                    exerciseStack(routine)
                }
                safetyPanel
            }
            .padding(.horizontal, AIscendTheme.Spacing.screenInset)
            .padding(.bottom, AIscendTheme.Spacing.xxLarge)
        }
        .contentMargins(.top, AIscendTheme.Spacing.large, for: .scrollContent)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            AIscendBadge(title: "Structured facial performance", symbol: "scope", style: .accent)

            Text("Facial Training")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text("Six weeks of jaw, hyoid, neck, posture, breathing, and recovery work built like a performance protocol.")
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func todayHero(_ routine: FacialRoutine) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: AIscendTheme.Spacing.large) {
                    todayCopy(routine)
                    Spacer(minLength: 0)
                    FacialTrainingProgressDial(progress: store.completionProgress, value: "\(routine.estimatedMinutes)", label: "min")
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    todayCopy(routine)
                    HStack {
                        Spacer(minLength: 0)
                        FacialTrainingProgressDial(progress: store.completionProgress, value: "\(routine.estimatedMinutes)", label: "min")
                        Spacer(minLength: 0)
                    }
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    AIscendStatChip(title: "Week", value: "\(routine.weekIndex)/6", symbol: "calendar", accent: .sky)
                    AIscendStatChip(title: "Streak", value: "\(store.currentStreak)d", symbol: "flame.fill", accent: .dawn)
                    AIscendStatChip(title: "Readiness", value: "\(Int(store.latestReadinessScore * 100))%", symbol: "gauge.with.dots.needle.50percent", accent: .mint)
                    AIscendStatChip(title: "Load", value: routine.dayType.title, symbol: "waveform.path.ecg", accent: .dawn)
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    AIscendStatChip(title: "Week", value: "\(routine.weekIndex)/6", symbol: "calendar", accent: .sky)
                    AIscendStatChip(title: "Streak", value: "\(store.currentStreak)d", symbol: "flame.fill", accent: .dawn)
                    AIscendStatChip(title: "Readiness", value: "\(Int(store.latestReadinessScore * 100))%", symbol: "gauge.with.dots.needle.50percent", accent: .mint)
                    AIscendStatChip(title: "Load", value: routine.dayType.title, symbol: "waveform.path.ecg", accent: .dawn)
                }
            }
        }
        .padding(AIscendTheme.Spacing.xLarge)
        .background(FacialTrainingLuxuryPanel())
    }

    private func todayCopy(_ routine: FacialRoutine) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            AIscendBadge(
                title: store.hasCompletedToday ? "Completed today" : "Today ready",
                symbol: store.hasCompletedToday ? "checkmark.seal.fill" : "play.fill",
                style: store.hasCompletedToday ? .success : .accent
            )

            Text(routine.title)
                .aiscendTextStyle(.sectionTitle, color: AIscendTheme.Colors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text(routine.focus)
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var weeklySnapshot: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendSectionHeader(
                eyebrow: "Adaptive plan",
                title: store.currentWeek?.phase ?? "Calibration",
                subtitle: store.plan?.adaptationState.coachingSummary ?? store.currentWeek?.improvementGoal ?? "Generate your six-week protocol to begin."
            )

            HStack(spacing: AIscendTheme.Spacing.small) {
                ForEach(0..<7, id: \.self) { day in
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(dayFill(day))
                        .frame(height: 42)
                        .overlay(alignment: .bottom) {
                            if day == Calendar.current.component(.weekday, from: .now) - 1 {
                                Capsule()
                                    .fill(AIscendTheme.Colors.accentGlow)
                                    .frame(width: 18, height: 3)
                                    .padding(.bottom, 5)
                            }
                        }
                }
            }
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.elevated)
    }

    private func dayFill(_ day: Int) -> AnyShapeStyle {
        guard let currentWeek = store.currentWeek else {
            return AnyShapeStyle(AIscendTheme.Colors.surfaceHighlight.opacity(0.68))
        }

        if currentWeek.deloadDays.contains(day) {
            return AnyShapeStyle(RoutineAccent.mint.gradient.opacity(0.38))
        }

        if let todayRoutine = store.todayRoutine, todayRoutine.dayIndex == day {
            return AnyShapeStyle(RoutineAccent.sky.gradient)
        }

        return AnyShapeStyle(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
    }

    private func planActions(_ routine: FacialRoutine) -> some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                activeRoutine = routine
            } label: {
                AIscendButtonLabel(title: store.hasCompletedToday ? "Review Today's Session" : "Start Today's Session", leadingSymbol: "play.fill")
            }
            .buttonStyle(AIscendButtonStyle(variant: .primary))

            Button {
                showingPlan = true
            } label: {
                AIscendButtonLabel(title: "View 6 Week Plan", leadingSymbol: "calendar.badge.clock")
            }
            .buttonStyle(AIscendButtonStyle(variant: .secondary))
        }
    }

    private func exerciseStack(_ routine: FacialRoutine) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendSectionHeader(
                eyebrow: "Today",
                title: "Session stack",
                subtitle: routine.progressionSummary
            )

            VStack(spacing: AIscendTheme.Spacing.small) {
                ForEach(routine.prescriptions) { prescription in
                    FacialTrainingExerciseRow(prescription: prescription)
                }
            }
        }
    }

    private var safetyPanel: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.warning)
                .padding(.top, 2)

            Text("This is training guidance, not medical care. Skip loaded neck or chewing work if you have pain, TMJ symptoms, dental issues, dizziness, headaches, or nerve symptoms.")
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.muted)
    }
}

struct FacialTrainingRoutineCard: View {
    @ObservedObject var store: FacialTrainingStore
    let onOpen: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            onOpen()
        } label: {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                protocolHeader

                Text(store.todayRoutine?.title ?? "Generate your 6-week protocol")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .minimumScaleFactor(0.88)
                    .fixedSize(horizontal: false, vertical: true)

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: AIscendTheme.Spacing.mediumLarge) {
                        protocolDial
                        protocolDetail
                    }

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                        HStack {
                            Spacer(minLength: 0)
                            protocolDial
                            Spacer(minLength: 0)
                        }
                        protocolDetail
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        FacialTrainingCardAction(title: "View 6 Week Plan", symbol: "calendar.badge.clock")
                        FacialTrainingCardAction(title: "Start Today's Session", symbol: "play.fill", isPrimary: true)
                    }

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        FacialTrainingCardAction(title: "View 6 Week Plan", symbol: "calendar.badge.clock")
                        FacialTrainingCardAction(title: "Start Today's Session", symbol: "play.fill", isPrimary: true)
                    }
                }
            }
            .padding(AIscendTheme.Spacing.large)
            .background(FacialTrainingLuxuryPanel())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Facial Training")
    }

    private var protocolHeader: some View {
        HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.accentAmber.opacity(0.30),
                                AIscendTheme.Colors.accentPrimary.opacity(0.20),
                                AIscendTheme.Colors.surfaceHighlight.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 62, height: 62)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(AIscendTheme.Colors.accentGlow.opacity(0.34), lineWidth: 1)
                    )

                Image(systemName: "face.smiling.inverse")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                AIscendBadge(title: "Facial Training", symbol: "sparkles", style: .accent)
                AIscendBadge(
                    title: store.hasCompletedToday ? "Completed" : "\(store.currentStreak)d streak",
                    symbol: store.hasCompletedToday ? "checkmark.seal.fill" : "flame.fill",
                    style: store.hasCompletedToday ? .success : .neutral
                )
            }

            Spacer(minLength: 0)
        }
    }

    private var protocolDial: some View {
        FacialTrainingProgressDial(
            progress: max(store.completionProgress, store.hasGeneratedPlan ? 0.08 : 0.0),
            value: store.todayRoutine.map { "\($0.estimatedMinutes)" } ?? "6",
            label: store.todayRoutine == nil ? "wk" : "min",
            size: 96,
            lineWidth: 8
        )
    }

    private var protocolDetail: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text(cardDetail)
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text("Jaw, neck, posture, hyoid control, breathing, and recovery in one adaptive plan.")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .layoutPriority(1)
    }

    private var cardDetail: String {
        guard let routine = store.todayRoutine else {
            return "Elite, clinical facial performance training across jaw, neck, posture, hyoid control, breathing, and recovery."
        }

        return "Week \(routine.weekIndex) / \(routine.prescriptions.count) movements / \(routine.estimatedMinutes) minutes / adaptive feedback progression."
    }
}

private struct FacialTrainingCardAction: View {
    let title: String
    let symbol: String
    var isPrimary = false

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .aiscendTextStyle(.buttonLabel, color: AIscendTheme.Colors.textPrimary)
        .frame(maxWidth: .infinity, minHeight: 48)
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .background(
            Capsule(style: .continuous)
                .fill(isPrimary ? AnyShapeStyle(RoutineAccent.dawn.gradient.opacity(0.95)) : AnyShapeStyle(AIscendTheme.Colors.surfaceHighlight.opacity(0.70)))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(isPrimary ? AIscendTheme.Colors.accentAmber.opacity(0.44) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct FacialTrainingExerciseRow: View {
    let prescription: FacialExercisePrescription

    var body: some View {
        HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: symbol, accent: prescription.exercise.animation.accent, size: 42)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(prescription.exercise.name)
                    .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)

                Text("\(prescription.exercise.muscleFocus) / Rest \(prescription.restSeconds)s")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Text(prescription.doseLabel)
                .aiscendTextStyle(.caption, color: prescription.exercise.animation.accent.tint)
                .monospacedDigit()
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(prescription.exercise.animation.accent.tint.opacity(0.18), lineWidth: 1)
        )
    }

    private var symbol: String {
        switch prescription.exercise.category {
        case .neck:
            "figure.strengthtraining.traditional"
        case .jawHyoid:
            "face.smiling.inverse"
        case .posture:
            "figure.stand"
        case .recovery:
            "wind"
        }
    }
}

private struct FacialTrainingProgressDial: View {
    let progress: Double
    let value: String
    let label: String
    var size: CGFloat = 132
    var lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            Circle()
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(max(progress, 0.04), 1))
                .stroke(
                    RoutineAccent.dawn.gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: AIscendTheme.Colors.accentAmber.opacity(0.26), radius: 16, x: 0, y: 0)

            VStack(spacing: AIscendTheme.Spacing.xxSmall) {
                Text(value)
                    .font(.system(size: max(20, size * 0.21), weight: .bold, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()

                Text(label)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }
        }
        .frame(width: size, height: size)
    }
}

struct FacialTrainingLuxuryPanel: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: "0D0E12").opacity(0.98),
                        Color(hex: "171822").opacity(0.98),
                        AIscendTheme.Colors.accentDeep.opacity(0.34),
                        Color(hex: "0A0B0F").opacity(0.99)
                    ],
                    startPoint: pulse ? .topTrailing : .topLeading,
                    endPoint: pulse ? .bottomLeading : .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.accentAmber.opacity(0.34),
                                AIscendTheme.Colors.accentGlow.opacity(0.22),
                                AIscendTheme.Colors.borderSubtle
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.42), radius: 28, x: 0, y: 18)
            .shadow(color: AIscendTheme.Colors.accentAmber.opacity(pulse ? 0.16 : 0.08), radius: 34, x: 0, y: 0)
            .onAppear {
                guard !reduceMotion else {
                    return
                }
                withAnimation(.easeInOut(duration: 4.8).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

private struct FacialTrainingOnboardingView: View {
    @ObservedObject var store: FacialTrainingStore

    @State private var profile = UserTrainingGoals.empty
    @State private var page = 0

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
            onboardingHeader

            TabView(selection: $page) {
                onboardingPageScroll {
                    basicsPage
                }
                .tag(0)

                onboardingPageScroll {
                    goalsPage
                }
                .tag(1)

                onboardingPageScroll {
                    equipmentPage
                }
                .tag(2)

                onboardingPageScroll {
                    reviewPage
                }
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .padding(.horizontal, AIscendTheme.Spacing.screenInset)
        .safeAreaPadding(.top, AIscendTheme.Spacing.large)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            onboardingCTA
        }
    }

    private var onboardingHeader: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            AIscendBadge(title: "Plan generation", symbol: "wand.and.stars", style: .accent)

            Text("Build the protocol")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.86)

            Text("AIscend will generate a six-week progression with intensity, recovery, and equipment constraints built in.")
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func onboardingPageScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView(showsIndicators: false) {
            content()
                .padding(.bottom, AIscendTheme.Spacing.large)
        }
        .contentMargins(.bottom, AIscendTheme.Spacing.medium, for: .scrollContent)
    }

    private var onboardingCTA: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Button {
                withAnimation(AIscendTheme.Motion.reveal) {
                    page = max(page - 1, 0)
                }
            } label: {
                AIscendButtonLabel(title: "Back", leadingSymbol: "chevron.left")
            }
            .buttonStyle(AIscendButtonStyle(variant: .secondary))
            .opacity(page == 0 ? 0.45 : 1)
            .disabled(page == 0)

            Button {
                if page < 3 {
                    withAnimation(AIscendTheme.Motion.reveal) {
                        page += 1
                    }
                } else {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    store.generateInitialPlan(profile: profile)
                }
            } label: {
                AIscendButtonLabel(title: page == 3 ? "Generate Plan" : "Continue", trailingSymbol: page == 3 ? "sparkles" : "chevron.right")
            }
            .buttonStyle(AIscendButtonStyle(variant: .primary))
        }
        .padding(.horizontal, AIscendTheme.Spacing.screenInset)
        .padding(.top, AIscendTheme.Spacing.small)
        .padding(.bottom, AIscendTheme.Spacing.medium)
        .background(
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.appBackground.opacity(0.04),
                    AIscendTheme.Colors.appBackground.opacity(0.86)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private var basicsPage: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            FacialTrainingOptionSection(title: "Gender") {
                optionGrid(FacialTrainingGender.allCases, selection: $profile.gender)
            }

            FacialTrainingStepper(title: "Age", value: $profile.age, range: 13...85, suffix: "years")
            FacialTrainingStepper(title: "Daily time", value: $profile.availableDailyMinutes, range: 10...15, suffix: "minutes")

            FacialTrainingOptionSection(title: "Current bodyfat estimate") {
                bodyFatGrid
            }

            FacialTrainingOptionSection(title: "Current capacity") {
                VStack(spacing: AIscendTheme.Spacing.small) {
                    capacityPicker(title: "Neck strength", selection: $profile.neckStrengthLevel)
                    capacityPicker(title: "Posture control", selection: $profile.postureLevel)
                }
            }
        }
    }

    private var goalsPage: some View {
        FacialTrainingOptionSection(title: "Facial goals") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                ForEach(FacialTrainingGoal.allCases) { goal in
                    FacialTrainingSelectionChip(
                        title: goal.title,
                        isSelected: profile.goals.contains(goal),
                        action: {
                            toggle(goal, in: &profile.goals)
                        }
                    )
                }
            }
        }
    }

    private var equipmentPage: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            FacialTrainingOptionSection(title: "Equipment access") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
                    ForEach(FacialTrainingEquipment.allCases) { item in
                        FacialTrainingSelectionChip(
                            title: item.title,
                            isSelected: profile.equipment.contains(item),
                            action: {
                                toggleEquipment(item)
                            }
                        )
                    }
                }
            }

            FacialTrainingOptionSection(title: "Training experience") {
                optionGrid(FacialTrainingExperience.allCases, selection: $profile.experience)
            }
        }
    }

    private var reviewPage: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            FacialTrainingReviewRow(title: "Difficulty tier", value: profile.experience == .advanced ? "Advanced" : profile.experience == .trained ? "Performance" : "Foundation")
            FacialTrainingReviewRow(title: "Primary goals", value: profile.goals.prefix(3).map(\.shortTitle).joined(separator: " / "))
            FacialTrainingReviewRow(title: "Session cap", value: "\(profile.availableDailyMinutes) minutes")
            FacialTrainingReviewRow(title: "Neck strength", value: profile.neckStrengthLevel.title)
            FacialTrainingReviewRow(title: "Posture control", value: profile.postureLevel.title)
            FacialTrainingReviewRow(title: "Recovery", value: "2 deload days weekly")
            FacialTrainingReviewRow(title: "Progression", value: "Feedback-adjusted weekly overload")
        }
        .padding(AIscendTheme.Spacing.large)
        .background(FacialTrainingLuxuryPanel())
    }

    private var bodyFatGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
            ForEach(FacialBodyFatEstimate.allCases) { option in
                FacialTrainingSelectionChip(
                    title: option.title,
                    subtitle: bodyFatSubtitle(for: option),
                    isSelected: profile.bodyFatEstimate == option,
                    minHeight: option == .unsure ? 74 : 92,
                    action: { profile.bodyFatEstimate = option }
                )
                .gridCellColumns(option == .unsure ? 2 : 1)
            }
        }
    }

    private func optionGrid<T: Identifiable & Equatable>(_ options: [T], selection: Binding<T>) -> some View where T.ID == String {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AIscendTheme.Spacing.small) {
            ForEach(options) { option in
                let title = title(for: option)
                FacialTrainingSelectionChip(
                    title: title,
                    isSelected: selection.wrappedValue == option,
                    action: { selection.wrappedValue = option }
                )
            }
        }
    }

    private func bodyFatSubtitle(for option: FacialBodyFatEstimate) -> String {
        switch option {
        case .lean:
            "Visible definition, lower softness"
        case .athletic:
            "Balanced definition and fullness"
        case .average:
            "Moderate softness, typical range"
        case .higher:
            "Softer features, higher storage"
        case .unsure:
            "Let AIScend adapt conservatively"
        }
    }

    private func title<T>(for option: T) -> String {
        switch option {
        case let option as FacialTrainingGender:
            return option.title
        case let option as FacialBodyFatEstimate:
            return option.title
        case let option as FacialTrainingExperience:
            return option.title
        case let option as FacialTrainingCapacityLevel:
            return option.title
        default:
            return ""
        }
    }

    private func capacityPicker(title: String, selection: Binding<FacialTrainingCapacityLevel>) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            optionGrid(FacialTrainingCapacityLevel.allCases, selection: selection)
        }
    }

    private func toggle<T: Equatable>(_ value: T, in array: inout [T]) {
        if array.contains(value) {
            array.removeAll { $0 == value }
        } else {
            array.append(value)
        }
    }

    private func toggleEquipment(_ item: FacialTrainingEquipment) {
        if item == .none {
            profile.equipment = [.none]
            return
        }

        profile.equipment.removeAll { $0 == .none }
        toggle(item, in: &profile.equipment)
        if profile.equipment.isEmpty {
            profile.equipment = [.none]
        }
    }
}

private struct FacialTrainingOptionSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
            content
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.standard)
    }
}

private struct FacialTrainingSelectionChip: View {
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    var minHeight: CGFloat = 48
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(title)
                    .aiscendTextStyle(.caption, color: isSelected ? AIscendTheme.Colors.textPrimary : AIscendTheme.Colors.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .aiscendTextStyle(.caption, color: isSelected ? AIscendTheme.Colors.textPrimary.opacity(0.78) : AIscendTheme.Colors.textMuted)
                        .lineLimit(3)
                        .minimumScaleFactor(0.82)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .padding(.horizontal, AIscendTheme.Spacing.small)
            .padding(.vertical, AIscendTheme.Spacing.xSmall)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(RoutineAccent.dawn.gradient.opacity(0.86)) : AnyShapeStyle(AIscendTheme.Colors.surfaceHighlight.opacity(0.74)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                    .stroke(isSelected ? AIscendTheme.Colors.accentAmber.opacity(0.48) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct FacialTrainingStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let suffix: String

    var body: some View {
        HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                Text("\(value) \(suffix)")
                    .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)
            }
            .layoutPriority(1)

            Spacer(minLength: 0)

            HStack(spacing: 0) {
                stepButton(symbol: "minus", isEnabled: value > range.lowerBound) {
                    value = max(value - 1, range.lowerBound)
                }

                Rectangle()
                    .fill(AIscendTheme.Colors.borderSubtle)
                    .frame(width: 1, height: 28)

                stepButton(symbol: "plus", isEnabled: value < range.upperBound) {
                    value = min(value + 1, range.upperBound)
                }
            }
            .background(
                Capsule(style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
            .fixedSize()
        }
        .padding(.horizontal, AIscendTheme.Spacing.large)
        .padding(.vertical, AIscendTheme.Spacing.medium)
        .aiscendPanel(.standard)
    }

    private func stepButton(symbol: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isEnabled ? AIscendTheme.Colors.textPrimary : AIscendTheme.Colors.textMuted.opacity(0.45))
                .frame(width: 44, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(symbol == "minus" ? "Decrease \(title)" : "Increase \(title)")
    }
}

private struct FacialTrainingReviewRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            Spacer(minLength: 16)
            Text(value.isEmpty ? "Adaptive" : value)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct FacialTrainingPlanView: View {
    @ObservedObject var store: FacialTrainingStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AIscendBackdrop()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                        if let plan = store.plan {
                            AIscendSectionHeader(
                                eyebrow: plan.difficultyTier.title,
                                title: "6 Week Plan",
                                subtitle: plan.recoverySchedule
                            )

                            ForEach(plan.weeks) { week in
                                weekCard(week)
                            }
                        }
                    }
                    .padding(AIscendTheme.Spacing.screenInset)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func weekCard(_ week: TrainingWeek) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendSectionHeader(
                eyebrow: week.title,
                title: week.phase,
                subtitle: week.improvementGoal
            )

            ForEach(week.routines) { routine in
                HStack(spacing: AIscendTheme.Spacing.medium) {
                    Text("D\(routine.dayIndex + 1)")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                        .frame(width: 34)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(routine.title)
                            .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                        Text("\(routine.dayType.title) / \(routine.estimatedMinutes)m / \(routine.prescriptions.count) movements")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    }

                    Spacer(minLength: 0)
                }
                .padding(AIscendTheme.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                        .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.68))
                )
            }
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.elevated)
    }
}
