//
//  EntryOnboardingFlowView.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import SwiftUI

private enum EntryOnboardingStep: Int, CaseIterable, Identifiable {
    case hero
    case value
    case process
    case trust
    case goals
    case permissions
    case capture

    var id: Int { rawValue }

    var eyebrow: String {
        switch self {
        case .hero:
            "AIScend"
        case .value:
            "Clarity"
        case .process:
            "How It Works"
        case .trust:
            "Privacy"
        case .goals:
            "Intent"
        case .permissions:
            "Access"
        case .capture:
            "Preparation"
        }
    }

    var title: String {
        switch self {
        case .hero:
            "See your features with more clarity."
        case .value:
            "Structured facial analysis, built for self-improvement."
        case .process:
            "A guided flow from capture to organised insight."
        case .trust:
            "Private by default, careful by design."
        case .goals:
            "Choose the kind of feedback you want first."
        case .permissions:
            "Prime access before the first guided capture."
        case .capture:
            "Set up the first scan properly."
        }
    }

    var subtitle: String {
        switch self {
        case .hero:
            "AIScend turns front and side captures into a refined analysis environment designed to reduce guesswork, surface stronger patterns, and keep the experience private."
        case .value:
            "The product is designed to help you understand facial structure, see standout strengths, and find cleaner refinement opportunities without turning the experience into noise."
        case .process:
            "You capture or upload the right angles, AIScend maps facial signals, and the app organises the output into sections that are easier to interpret and revisit."
        case .trust:
            "Facial analysis is sensitive. The experience should feel secure, measured, and intentional from the first screen to the final result."
        case .goals:
            "This helps AIScend frame the experience around what you care about most, so the first session already feels more personal and useful."
        case .permissions:
            "Camera and library access should never feel abrupt. AIScend explains what is needed first, why it matters, and how to get stronger image quality."
        case .capture:
            "Good lighting, clean framing, and neutral expression make the output more consistent. You'll secure the workspace next so the authenticated setup is ready for future capture flows."
        }
    }

    var ctaTitle: String {
        switch self {
        case .hero:
            "Enter the system"
        case .value:
            "See the structure"
        case .process:
            "Continue"
        case .trust:
            "Set intent"
        case .goals:
            "Lock this focus"
        case .permissions:
            "Prepare the capture"
        case .capture:
            "Continue to secure sign-in"
        }
    }
}

struct EntryOnboardingFlowView: View {
    @Bindable var model: AppModel

    @State private var currentStepIndex = 0

    private var steps: [EntryOnboardingStep] { EntryOnboardingStep.allCases }

    private var currentStep: EntryOnboardingStep {
        steps[currentStepIndex]
    }

    private var isLastStep: Bool {
        currentStepIndex == steps.count - 1
    }

    private var canAdvance: Bool {
        if currentStep == .goals {
            return !model.analysisGoals.isEmpty
        }

        return true
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()

            VStack(spacing: AIscendTheme.Spacing.large) {
                topBar
                    .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                    .padding(.top, AIscendTheme.Spacing.medium)

                progressHeader
                    .padding(.horizontal, AIscendTheme.Spacing.screenInset)

                TabView(selection: $currentStepIndex) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        page(for: step)
                            .tag(index)
                            .padding(.bottom, 156)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(AIscendTheme.Motion.reveal, value: currentStepIndex)
            }
        }
        .safeAreaInset(edge: .bottom) {
            footer
                .padding(.horizontal, AIscendTheme.Spacing.mediumLarge)
                .padding(.top, AIscendTheme.Spacing.small)
                .padding(.bottom, AIscendTheme.Spacing.mediumLarge)
                .background(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.appBackground.opacity(0),
                            AIscendTheme.Colors.appBackground.opacity(0.84),
                            AIscendTheme.Colors.appBackground
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    private var topBar: some View {
        HStack {
            AIscendBrandMark(size: 50)

            Spacer()

            Button {
                withAnimation(AIscendTheme.Motion.reveal) {
                    model.completeEntryOnboarding()
                }
            } label: {
                AIscendBadge(
                    title: "Sign In",
                    symbol: "arrow.up.right",
                    style: .subtle
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack {
                Text("Stage \(currentStepIndex + 1) of \(steps.count)")
                    .aiscendTextStyle(.caption)

                Spacer()

                Text(currentStep.eyebrow.uppercased())
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
            }

            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, _ in
                    Capsule(style: .continuous)
                        .fill(
                            index <= currentStepIndex
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        AIscendTheme.Colors.accentGlow,
                                        AIscendTheme.Colors.accentPrimary
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyShapeStyle(AIscendTheme.Colors.surfaceHighlight)
                        )
                        .frame(height: 6)
                }
            }
        }
    }

    @ViewBuilder
    private func page(for step: EntryOnboardingStep) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                switch step {
                case .hero:
                    heroPage
                case .value:
                    valuePage
                case .process:
                    processPage
                case .trust:
                    trustPage
                case .goals:
                    goalsPage
                case .permissions:
                    permissionsPage
                case .capture:
                    capturePage
                }
            }
            .frame(maxWidth: 620, alignment: .leading)
            .padding(.horizontal, AIscendTheme.Spacing.screenInset)
            .padding(.top, AIscendTheme.Spacing.small)
        }
    }

    private var heroPage: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
            pageHeader(for: .hero)

            EntryHeroArtwork()
                .padding(AIscendTheme.Spacing.large)
                .aiscendPanel(.hero)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    EntryMiniSignalCard(
                        title: "Structured",
                        detail: "Clarity on facial shape, profile, and presentation.",
                        symbol: "square.grid.2x2.fill",
                        accent: .sky
                    )
                    EntryMiniSignalCard(
                        title: "Private",
                        detail: "A calmer, higher-trust experience from the start.",
                        symbol: "lock.fill",
                        accent: .dawn
                    )
                    EntryMiniSignalCard(
                        title: "Guided",
                        detail: "Front and side capture instructions built into the flow.",
                        symbol: "camera.aperture",
                        accent: .mint
                    )
                }
                VStack(spacing: AIscendTheme.Spacing.small) {
                    EntryMiniSignalCard(
                        title: "Structured",
                        detail: "Clarity on facial shape, profile, and presentation.",
                        symbol: "square.grid.2x2.fill",
                        accent: .sky
                    )
                    EntryMiniSignalCard(
                        title: "Private",
                        detail: "A calmer, higher-trust experience from the start.",
                        symbol: "lock.fill",
                        accent: .dawn
                    )
                    EntryMiniSignalCard(
                        title: "Guided",
                        detail: "Front and side capture instructions built into the flow.",
                        symbol: "camera.aperture",
                        accent: .mint
                    )
                }
            }
        }
    }

    private var valuePage: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
            pageHeader(for: .value)

            VStack(spacing: AIscendTheme.Spacing.small) {
                EntryFeatureCard(
                    eyebrow: "01",
                    title: "Understand structure with more objectivity",
                    detail: "AIScend helps separate vague first impressions from cleaner, more repeatable analysis.",
                    symbol: "viewfinder.circle.fill",
                    accent: .sky
                )
                EntryFeatureCard(
                    eyebrow: "02",
                    title: "See where you already stand out",
                    detail: "Strengths matter. The point is not to flatten you into numbers, but to show what reads well so improvement can stay strategic.",
                    symbol: "sparkles",
                    accent: .dawn
                )
                EntryFeatureCard(
                    eyebrow: "03",
                    title: "Focus effort where it actually moves presentation",
                    detail: "Better grooming, stronger framing, and clearer improvement direction feel more useful when the feedback is organised well.",
                    symbol: "slider.horizontal.3",
                    accent: .mint
                )
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendBadge(
                    title: "Positioning",
                    symbol: "line.3.horizontal.decrease.circle.fill",
                    style: .neutral
                )

                Text("Move beyond vague self-judgment.")
                    .aiscendTextStyle(.sectionTitle)

                Text("AIScend is designed to replace scattered opinions with a more composed, more private analysis environment that supports deliberate self-improvement.")
                    .aiscendTextStyle(.body)
            }
            .padding(AIscendTheme.Spacing.large)
            .aiscendPanel(.elevated)
        }
    }

    private var processPage: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
            pageHeader(for: .process)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                    processTimeline
                    EntryResultsPreviewCard()
                }
                VStack(spacing: AIscendTheme.Spacing.small) {
                    processTimeline
                    EntryResultsPreviewCard()
                }
            }
        }
    }

    private var processTimeline: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            EntryProcessStepView(
                index: "01",
                title: "Capture or upload the right angles",
                detail: "AIScend is built around front and side profile input so the analysis starts from stronger source material.",
                symbol: "camera.metering.matrix",
                accent: .dawn
            )
            EntryProcessStepView(
                index: "02",
                title: "AI maps visible facial signals",
                detail: "The system reads structure, balance, profile, and presentation-relevant cues with a calmer, more organised frame.",
                symbol: "waveform.path.ecg.rectangle",
                accent: .sky
            )
            EntryProcessStepView(
                index: "03",
                title: "Results are organised into readable sections",
                detail: "Instead of a cluttered dump, AIScend groups the output so key takeaways are easier to navigate and revisit.",
                symbol: "rectangle.split.3x3.fill",
                accent: .mint
            )
            EntryProcessStepView(
                index: "04",
                title: "Use the output to refine presentation",
                detail: "The goal is more clarity around what to preserve, what to improve, and how to track change with more intention.",
                symbol: "arrow.up.forward.square.fill",
                accent: .sky
            )
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.standard)
    }

    private var trustPage: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
            pageHeader(for: .trust)

            VStack(spacing: AIscendTheme.Spacing.small) {
                EntryTrustRow(
                    title: "Your results are framed as personal insight",
                    detail: "AIScend is built to help users understand visual strengths, weaker areas, and improvement direction in a more composed way.",
                    symbol: "person.badge.shield.checkmark.fill"
                )
                EntryTrustRow(
                    title: "Capture guidance improves consistency",
                    detail: "Lighting, neutral expression, and correct angles matter. The app explains that up front so the analysis starts cleanly.",
                    symbol: "viewfinder"
                )
                EntryTrustRow(
                    title: "The experience stays restrained and private",
                    detail: "Nothing in the funnel is meant to feel noisy, performative, or socially exposed. It should feel like a controlled personal workspace.",
                    symbol: "lock.rectangle.stack.fill"
                )
            }
            .padding(AIscendTheme.Spacing.large)
            .aiscendPanel(.hero)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendBadge(
                    title: "High Trust",
                    symbol: "checkmark.shield.fill",
                    style: .success
                )

                Text("Sensitive inputs deserve a calmer product experience.")
                    .aiscendTextStyle(.sectionTitle)

                Text("The onboarding is explicit about privacy, capture quality, and purpose because facial analysis only feels premium when it also feels careful.")
                    .aiscendTextStyle(.body)
            }
            .padding(AIscendTheme.Spacing.large)
            .aiscendPanel(.muted)
        }
    }

    private var goalsPage: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
            pageHeader(for: .goals)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: AIscendTheme.Spacing.small),
                    GridItem(.flexible(), spacing: AIscendTheme.Spacing.small)
                ],
                spacing: AIscendTheme.Spacing.small
            ) {
                ForEach(AnalysisGoal.allCases) { goal in
                    Button {
                        withAnimation(AIscendTheme.Motion.reveal) {
                            model.toggleAnalysisGoal(goal)
                        }
                    } label: {
                        EntryGoalCard(
                            goal: goal,
                            isSelected: model.analysisGoals.contains(goal)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendBadge(
                    title: "Current Focus",
                    symbol: "sparkles",
                    style: .accent
                )

                Text(model.analysisGoalSummary)
                    .aiscendTextStyle(.sectionTitle)

                Text(
                    model.analysisGoals.isEmpty
                    ? "Choose at least one angle of improvement so AIScend can frame the entry experience more intentionally."
                    : "These selections shape the tone of the entry experience now and help the app feel less generic as you move into sign-in."
                )
                .aiscendTextStyle(.body)
            }
            .padding(AIscendTheme.Spacing.large)
            .aiscendPanel(model.analysisGoals.isEmpty ? .muted : .hero)
        }
    }

    private var permissionsPage: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
            pageHeader(for: .permissions)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    EntryPermissionCard(
                        title: "Camera access",
                        detail: "Capture guided front and side photos directly inside AIScend when you want the cleanest first pass.",
                        symbol: "camera.fill"
                    )
                    EntryPermissionCard(
                        title: "Photo library access",
                        detail: "Import existing images if you prefer, then let the app guide you toward stronger captures later.",
                        symbol: "photo.on.rectangle.angled"
                    )
                }
                VStack(spacing: AIscendTheme.Spacing.small) {
                    EntryPermissionCard(
                        title: "Camera access",
                        detail: "Capture guided front and side photos directly inside AIScend when you want the cleanest first pass.",
                        symbol: "camera.fill"
                    )
                    EntryPermissionCard(
                        title: "Photo library access",
                        detail: "Import existing images if you prefer, then let the app guide you toward stronger captures later.",
                        symbol: "photo.on.rectangle.angled"
                    )
                }
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendBadge(
                    title: "Why Both Matter",
                    symbol: "rectangle.on.rectangle.angled",
                    style: .neutral
                )

                Text("Front and side views create a better read of structure and profile.")
                    .aiscendTextStyle(.sectionTitle)

                Text("AIScend primes permissions before any system prompt appears so the request feels expected, contextual, and tied to better results.")
                    .aiscendTextStyle(.body)

                HStack(spacing: AIscendTheme.Spacing.small) {
                    AIscendCapsule(title: "Better lighting", symbol: "sun.max.fill", isActive: true)
                    AIscendCapsule(title: "Cleaner framing", symbol: "crop", isActive: true)
                }
            }
            .padding(AIscendTheme.Spacing.large)
            .aiscendPanel(.standard)
        }
    }

    private var capturePage: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
            pageHeader(for: .capture)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    EntryShotGuideCard(
                        title: "Front profile",
                        detail: "Center the face, keep the chin relaxed, and use even lighting that doesn't blow out the skin.",
                        alignmentSymbol: "person.crop.square.fill"
                    )
                    EntryShotGuideCard(
                        title: "Side profile",
                        detail: "Keep the camera level, maintain a neutral expression, and make sure the profile line is unobstructed.",
                        alignmentSymbol: "person.crop.square.filled.and.at.rectangle"
                    )
                }
                VStack(spacing: AIscendTheme.Spacing.small) {
                    EntryShotGuideCard(
                        title: "Front profile",
                        detail: "Center the face, keep the chin relaxed, and use even lighting that doesn't blow out the skin.",
                        alignmentSymbol: "person.crop.square.fill"
                    )
                    EntryShotGuideCard(
                        title: "Side profile",
                        detail: "Keep the camera level, maintain a neutral expression, and make sure the profile line is unobstructed.",
                        alignmentSymbol: "person.crop.square.filled.and.at.rectangle"
                    )
                }
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendBadge(
                    title: "Scan Checklist",
                    symbol: "checklist",
                    style: .accent
                )

                EntryChecklistRow(text: "Use natural or soft, even lighting.")
                EntryChecklistRow(text: "Keep hair, hats, and heavy shadows off the face when possible.")
                EntryChecklistRow(text: "Use a neutral expression and level camera angle.")
                EntryChecklistRow(text: "Capture both front and side views for stronger analysis context.")
            }
            .padding(AIscendTheme.Spacing.large)
            .aiscendPanel(.hero)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                Text("You'll secure the workspace next.")
                    .aiscendTextStyle(.sectionTitle)

                Text("Sign-in happens before the first capture so your settings, future scans, and results stay linked to you instead of floating as anonymous state.")
                    .aiscendTextStyle(.body)
            }
            .padding(AIscendTheme.Spacing.large)
            .aiscendPanel(.muted)
        }
    }

    private func pageHeader(for step: EntryOnboardingStep) -> some View {
        AIscendSectionHeader(
            eyebrow: step.eyebrow,
            title: step.title,
            subtitle: step.subtitle,
            prominence: .hero
        )
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            if currentStep == .goals && model.analysisGoals.isEmpty {
                Text("Choose at least one focus area to continue.")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.warning)
                    .padding(.horizontal, AIscendTheme.Spacing.xSmall)
            }

            HStack(spacing: AIscendTheme.Spacing.small) {
                if currentStepIndex > 0 {
                    Button {
                        withAnimation(AIscendTheme.Motion.reveal) {
                            currentStepIndex -= 1
                        }
                    } label: {
                        AIscendButtonLabel(
                            title: "Back",
                            leadingSymbol: "arrow.left"
                        )
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .ghost))
                }

                Button {
                    advance()
                } label: {
                    AIscendButtonLabel(
                        title: currentStep.ctaTitle,
                        trailingSymbol: isLastStep ? "lock.fill" : "arrow.right"
                    )
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))
                .disabled(!canAdvance)
                .opacity(canAdvance ? 1 : 0.55)
            }
        }
    }

    private func advance() {
        guard canAdvance else {
            return
        }

        withAnimation(AIscendTheme.Motion.reveal) {
            if isLastStep {
                model.completeEntryOnboarding()
            } else {
                currentStepIndex += 1
            }
        }
    }
}

private struct EntryHeroArtwork: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.secondaryBackground.opacity(0.85),
                            AIscendTheme.Colors.appBackground.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AIscendTheme.Colors.accentGlow.opacity(0.34),
                            .clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 150
                    )
                )
                .frame(width: 240, height: 240)

            Circle()
                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
                .frame(width: 220, height: 220)

            Circle()
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                .frame(width: 164, height: 164)

            Circle()
                .trim(from: 0.12, to: 0.82)
                .stroke(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.accentGlow,
                            AIscendTheme.Colors.accentPrimary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 164, height: 164)
                .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.28), radius: 18, x: 0, y: 0)

            AIscendBrandMark(size: 126, showsWordmark: false)

            VStack(spacing: AIscendTheme.Spacing.small) {
                Spacer()

                HStack(spacing: AIscendTheme.Spacing.small) {
                    EntryGlassChip(title: "Front + side")
                    EntryGlassChip(title: "Private results")
                    EntryGlassChip(title: "Clarity first")
                }
            }
            .padding(AIscendTheme.Spacing.large)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 360)
    }
}

private struct EntryMiniSignalCard: View {
    let title: String
    let detail: String
    let symbol: String
    let accent: RoutineAccent

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: symbol, accent: accent, size: 42)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(title)
                    .aiscendTextStyle(.cardTitle)

                Text(detail)
                    .aiscendTextStyle(.secondaryBody)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.mediumLarge)
        .aiscendPanel(.standard)
    }
}

private struct EntryFeatureCard: View {
    let eyebrow: String
    let title: String
    let detail: String
    let symbol: String
    let accent: RoutineAccent

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.mediumLarge) {
            AIscendIconOrb(symbol: symbol, accent: accent, size: 48)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                Text(eyebrow)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                Text(title)
                    .aiscendTextStyle(.sectionTitle)

                Text(detail)
                    .aiscendTextStyle(.body)
            }

            Spacer(minLength: 0)
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.standard)
    }
}

private struct EntryProcessStepView: View {
    let index: String
    let title: String
    let detail: String
    let symbol: String
    let accent: RoutineAccent

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            VStack(spacing: AIscendTheme.Spacing.xSmall) {
                AIscendIconOrb(symbol: symbol, accent: accent, size: 42)

                Rectangle()
                    .fill(AIscendTheme.Colors.borderSubtle)
                    .frame(width: 1)
                    .frame(height: 52)
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(index)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

                Text(title)
                    .aiscendTextStyle(.cardTitle)

                Text(detail)
                    .aiscendTextStyle(.body)
            }
            .padding(.top, AIscendTheme.Spacing.xxSmall)
        }
    }
}

private struct EntryResultsPreviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            HStack {
                AIscendBadge(
                    title: "Sample Output Layout",
                    symbol: "chart.xyaxis.line",
                    style: .accent
                )

                Spacer()
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text("A premium readout, not a cluttered dump.")
                    .aiscendTextStyle(.sectionTitle)

                Text("AIScend groups the analysis into calmer sections so score context, profile notes, and presentation signals are easier to read.")
                    .aiscendTextStyle(.body)
            }

            VStack(spacing: AIscendTheme.Spacing.small) {
                EntryPreviewMetricRow(label: "Structure", value: "Balanced")
                EntryPreviewMetricRow(label: "Profile", value: "Flagged for detail")
                EntryPreviewMetricRow(label: "Presentation", value: "High leverage")
                EntryPreviewMetricRow(label: "Tracking", value: "Baseline ready")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.hero)
    }
}

private struct EntryPreviewMetricRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .aiscendTextStyle(.body)

            Spacer()

            Text(value)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
        }
        .padding(.vertical, AIscendTheme.Spacing.small)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AIscendTheme.Colors.divider)
                .frame(height: 1)
        }
    }
}

private struct EntryTrustRow: View {
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: symbol, accent: .sky, size: 42)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(title)
                    .aiscendTextStyle(.cardTitle)

                Text(detail)
                    .aiscendTextStyle(.body)
            }
        }
    }
}

private struct EntryGoalCard: View {
    let goal: AnalysisGoal
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(alignment: .top) {
                AIscendIconOrb(symbol: goal.symbol, accent: isSelected ? .sky : .dawn, size: 44)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? AIscendTheme.Colors.accentGlow : AIscendTheme.Colors.textMuted)
            }

            Text(goal.title)
                .aiscendTextStyle(.cardTitle)

            Text(goal.subtitle)
                .aiscendTextStyle(.secondaryBody)
        }
        .frame(maxWidth: .infinity, minHeight: 204, alignment: .topLeading)
        .padding(AIscendTheme.Spacing.mediumLarge)
        .aiscendPanel(isSelected ? .hero : .standard)
    }
}

private struct EntryPermissionCard: View {
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: symbol, accent: .sky, size: 48)

            Text(title)
                .aiscendTextStyle(.sectionTitle)

            Text(detail)
                .aiscendTextStyle(.body)
        }
        .frame(maxWidth: .infinity, minHeight: 210, alignment: .topLeading)
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.elevated)
    }
}

private struct EntryShotGuideCard: View {
    let title: String
    let detail: String
    let alignmentSymbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            ZStack {
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.tertiaryBackground.opacity(0.96),
                                AIscendTheme.Colors.secondaryBackground.opacity(0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: AIscendTheme.Stroke.thin)
                    )

                VStack(spacing: AIscendTheme.Spacing.small) {
                    Image(systemName: alignmentSymbol)
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)

                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentGlow.opacity(0.85),
                                    AIscendTheme.Colors.borderSubtle
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 1, dash: [6, 6])
                        )
                        .frame(width: 112, height: 140)
                }
                .padding(AIscendTheme.Spacing.large)
            }
            .frame(height: 260)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                Text(title)
                    .aiscendTextStyle(.sectionTitle)

                Text(detail)
                    .aiscendTextStyle(.body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.standard)
    }
}

private struct EntryChecklistRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)
                .padding(.top, 1)

            Text(text)
                .aiscendTextStyle(.body)
        }
    }
}

private struct EntryGlassChip: View {
    let title: String

    var body: some View {
        Text(title)
            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
            .padding(.horizontal, AIscendTheme.Spacing.small)
            .padding(.vertical, AIscendTheme.Spacing.xSmall)
            .background(
                Capsule(style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.92))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: AIscendTheme.Stroke.thin)
            )
    }
}

#Preview {
    EntryOnboardingFlowView(model: AppModel())
        .preferredColorScheme(.dark)
}
