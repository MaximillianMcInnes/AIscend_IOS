//
//  GlowupRoutineFlowView.swift
//  AIscend
//

import SwiftUI
import UIKit

struct GlowupRoutineFlowView: View {
    let scanResult: PersistedScanRecord?
    let authenticatedUserID: String?
    let onOpenChat: () -> Void
    let onFinish: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("aiscend.glowupRoutineIntroCompleted") private var hasCompletedIntro = false
    @StateObject private var generationStore = GlowupRoutineGenerationStore()
    @State private var currentPageIndex = 0

    private let introSlides = GlowupIntroSlide.defaultSlides

    init(
        scanResult: PersistedScanRecord?,
        authenticatedUserID: String?,
        onOpenChat: @escaping () -> Void,
        onFinish: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.scanResult = scanResult
        self.authenticatedUserID = authenticatedUserID
        self.onOpenChat = onOpenChat
        self.onFinish = onFinish
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()
            content
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if shouldShowBottomControls {
                bottomControls
            }
        }
        .task(id: taskKey) {
            await generationStore.load(
                freshScanResult: scanResult,
                uid: authenticatedUserID
            )

            if hasCompletedIntro, currentPageIndex == 0, !generationStore.sections.isEmpty {
                currentPageIndex = introSlides.count
            }
        }
        .onChange(of: currentPageIndex) { _, _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var content: some View {
        switch generationStore.loadState {
        case .idle, .loading:
            GlowupRoutineLoadingState()
        case .empty:
            GlowupRoutineEmptyState(onDismiss: onFinish)
        case .error(let message):
            GlowupRoutineErrorState(message: message, onDismiss: onFinish)
        case .loaded:
            routinePager
        }
    }

    private var routinePager: some View {
        TabView(selection: $currentPageIndex) {
            ForEach(Array(introSlides.enumerated()), id: \.element.id) { index, slide in
                GlowupIntroSlidePage(slide: slide)
                    .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                    .tag(index)
            }

            ForEach(Array(generationStore.sections.enumerated()), id: \.element.id) { index, section in
                GlowupRoutineSectionPage(section: section)
                    .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                    .tag(introSlides.count + index)
            }

            GlowupRoutineDonePage(onOpenChat: onOpenChat)
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .tag(donePageIndex)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var bottomControls: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            GlowupDotsBar(totalPages: totalPageCount, currentPage: currentPageIndex)

            HStack(spacing: AIscendTheme.Spacing.small) {
                Button(action: goBack) {
                    AIscendButtonLabel(title: "Back", leadingSymbol: "chevron.left")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
                .disabled(currentPageIndex == 0)
                .opacity(currentPageIndex == 0 ? 0.45 : 1)

                Button(action: goForwardOrFinish) {
                    AIscendButtonLabel(
                        title: currentPageIndex == donePageIndex ? "Finish" : "Continue",
                        trailingSymbol: currentPageIndex == donePageIndex ? "checkmark" : "chevron.right"
                    )
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))
            }
        }
        .padding(.horizontal, AIscendTheme.Spacing.screenInset)
        .padding(.top, AIscendTheme.Spacing.small)
        .padding(.bottom, AIscendTheme.Spacing.small)
        .background(
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.appBackground.opacity(0),
                    AIscendTheme.Colors.appBackground.opacity(0.84),
                    AIscendTheme.Colors.appBackground.opacity(0.99)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var shouldShowBottomControls: Bool {
        generationStore.loadState == .loaded && totalPageCount > 0
    }

    private var totalPageCount: Int {
        introSlides.count + generationStore.sections.count + 1
    }

    private var donePageIndex: Int {
        max(0, totalPageCount - 1)
    }

    private var taskKey: String {
        scanResult?.meta.scanId ?? scanResult?.saveFingerprint ?? "saved-glowup-routine"
    }

    private func goBack() {
        guard currentPageIndex > 0 else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        updatePage(currentPageIndex - 1)
    }

    private func goForwardOrFinish() {
        UIImpactFeedbackGenerator(style: currentPageIndex == donePageIndex ? .medium : .soft).impactOccurred()

        guard currentPageIndex < donePageIndex else {
            hasCompletedIntro = true
            onFinish()
            return
        }

        if currentPageIndex == introSlides.count - 1 {
            hasCompletedIntro = true
        }

        updatePage(currentPageIndex + 1)
    }

    private func updatePage(_ index: Int) {
        guard index >= 0, index < totalPageCount else {
            return
        }

        if reduceMotion {
            currentPageIndex = index
        } else {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                currentPageIndex = index
            }
        }
    }
}

struct FurtherRecommendations: View {
    let section: GlowupRoutineSection

    var body: some View {
        RoutineSectionCard(section: section)
    }
}

struct EyebrowRecommendations: View {
    let section: GlowupRoutineSection

    var body: some View {
        RoutineSectionCard(section: section)
    }
}

struct JawAreaRecommendationsSimple: View {
    let section: GlowupRoutineSection

    var body: some View {
        RoutineSectionCard(section: section)
    }
}

struct LipRecommendations: View {
    let section: GlowupRoutineSection

    var body: some View {
        RoutineSectionCard(section: section)
    }
}

struct SideProfileGlowUpCard: View {
    let section: GlowupRoutineSection

    var body: some View {
        RoutineSectionCard(section: section)
    }
}

struct SkinCareRecommendations: View {
    let section: GlowupRoutineSection

    var body: some View {
        RoutineSectionCard(section: section)
    }
}

struct GeneralGlowupRecommendations: View {
    let section: GlowupRoutineSection

    var body: some View {
        RoutineSectionCard(section: section)
    }
}

struct RoutineSectionCard: View {
    let section: GlowupRoutineSection

    var body: some View {
        DashboardGlassCard(tone: section.key == .general ? .premium : .standard) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                    AIscendIconOrb(symbol: section.symbol, accent: section.accent, size: 52)

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                        Text(section.title)
                            .font(.system(size: 25, weight: .bold, design: .rounded))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(section.goal)
                            .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if !section.snapshotChips.isEmpty {
                    snapshotChips
                }

                if !section.goals.isEmpty {
                    goalsList
                } else if !section.actions.isEmpty {
                    routineList(
                        title: "Actions",
                        symbol: "checkmark.circle.fill",
                        tint: section.accent.tint,
                        items: section.actions
                    )
                }

                if section.goals.isEmpty, !section.personalisedTips.isEmpty {
                    routineList(
                        title: "Personalised tips",
                        symbol: "sparkles",
                        tint: AIscendTheme.Colors.accentGlow,
                        items: section.personalisedTips
                    )
                }

                if !section.observedSignals.isEmpty {
                    signalPanel
                }

                if !section.avoid.isEmpty {
                    routineList(
                        title: "Keep clean",
                        symbol: "exclamationmark.triangle.fill",
                        tint: AIscendTheme.Colors.accentAmber,
                        items: section.avoid
                    )
                }
            }
        }
    }

    private var goalsList: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                Image(systemName: "target")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(section.accent.tint)

                Text("Routine goals")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }

            VStack(spacing: AIscendTheme.Spacing.small) {
                ForEach(section.goals) { goal in
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        Text(goal.title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)

                        Text(goal.goal)
                            .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if !goal.actions.isEmpty {
                            compactBulletList(items: goal.actions, symbol: "checkmark.circle.fill", tint: section.accent.tint)
                        }

                        if !goal.personalisedTips.isEmpty {
                            compactBulletList(items: goal.personalisedTips, symbol: "sparkles", tint: AIscendTheme.Colors.accentGlow)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AIscendTheme.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.42))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .stroke(section.accent.tint.opacity(0.14), lineWidth: 1)
                    )
                }
            }
        }
    }

    private var snapshotChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AIscendTheme.Spacing.small) {
                ForEach(section.snapshotChips, id: \.self) { chip in
                    Text(chip)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                        .lineLimit(1)
                        .padding(.horizontal, AIscendTheme.Spacing.medium)
                        .padding(.vertical, AIscendTheme.Spacing.small)
                        .background(Capsule().fill(section.accent.tint.opacity(0.14)))
                        .overlay(Capsule().stroke(section.accent.tint.opacity(0.24), lineWidth: 1))
                }
            }
        }
    }

    private var signalPanel: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text("Scan snapshot")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            VStack(spacing: AIscendTheme.Spacing.xSmall) {
                ForEach(section.observedSignals) { signal in
                    HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                        Circle()
                            .fill(section.accent.tint)
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(signal.label): \(signal.value)")
                                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textPrimary)
                            if let detail = signal.detail {
                                Text(detail)
                                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(AIscendTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.54))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .stroke(section.accent.tint.opacity(0.16), lineWidth: 1)
            )
        }
    }

    private func routineList(title: String, symbol: String, tint: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)

                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }

            VStack(spacing: AIscendTheme.Spacing.xSmall) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AIscendTheme.Spacing.medium)
                        .background(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.42))
                        )
                }
            }
        }
    }

    private func compactBulletList(items: [String], symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                    Image(systemName: symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(tint)
                        .padding(.top, 2)

                    Text(item)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct GlowupRoutineSectionPage: View {
    let section: GlowupRoutineSection

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                topBar

                switch section.key {
                case .haircut:
                    FurtherRecommendations(section: section)
                case .eyebrow:
                    EyebrowRecommendations(section: section)
                case .jaw:
                    JawAreaRecommendationsSimple(section: section)
                case .lip:
                    LipRecommendations(section: section)
                case .side:
                    SideProfileGlowUpCard(section: section)
                case .skin:
                    SkinCareRecommendations(section: section)
                case .general:
                    GeneralGlowupRecommendations(section: section)
                }
            }
            .padding(.top, AIscendTheme.Spacing.large)
            .padding(.bottom, 150)
        }
    }

    private var topBar: some View {
        HStack {
            AIscendBadge(title: "Glow-Up", symbol: "scope", style: .accent)
            Spacer()
            AIscendBadge(title: section.key.rawValue.capitalized, symbol: section.symbol, style: .neutral)
        }
    }
}

private struct GlowupIntroSlide: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let accent: RoutineAccent

    static let defaultSlides = [
        GlowupIntroSlide(
            id: "routine",
            title: "This is your Glow-Up routine.",
            subtitle: "Your saved scan plan is organised into focused sections so the next move is clear.",
            symbol: "sparkles.rectangle.stack.fill",
            accent: .sky
        ),
        GlowupIntroSlide(
            id: "xp",
            title: "Check in each day to gain XP.",
            subtitle: "The routine is meant to be used daily, not admired once and forgotten.",
            symbol: "bolt.fill",
            accent: .dawn
        ),
        GlowupIntroSlide(
            id: "scan-updates",
            title: "Every scan updates this plan.",
            subtitle: "New scan JSON refreshes the saved sections and keeps the advice tied to real inputs.",
            symbol: "camera.aperture",
            accent: .mint
        ),
        GlowupIntroSlide(
            id: "advisor",
            title: "Ask the AI about anything here.",
            subtitle: "If a section feels unclear, the advisor can translate it into simpler next steps.",
            symbol: "message.fill",
            accent: .sky
        ),
        GlowupIntroSlide(
            id: "ready",
            title: "Your routine is ready.",
            subtitle: "Swipe through the plan, finish the flow, and return from the dashboard whenever you need it.",
            symbol: "checkmark.seal.fill",
            accent: .mint
        )
    ]
}

private struct GlowupIntroSlidePage: View {
    let slide: GlowupIntroSlide

    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.large) {
            Spacer(minLength: AIscendTheme.Spacing.xLarge)

            DashboardGlassCard(tone: .premium) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                    AIscendIconOrb(symbol: slide.symbol, accent: slide.accent, size: 82)

                    AIscendSectionHeader(
                        eyebrow: "Glow-Up routine",
                        title: slide.title,
                        subtitle: slide.subtitle,
                        prominence: .hero
                    )
                }
            }

            Spacer(minLength: 150)
        }
    }
}

private struct GlowupRoutineDonePage: View {
    let onOpenChat: () -> Void

    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.large) {
            Spacer(minLength: AIscendTheme.Spacing.large)

            DashboardGlassCard(tone: .hero) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    AIscendIconOrb(symbol: "checkmark.seal.fill", accent: .mint, size: 82)

                    AIscendSectionHeader(
                        eyebrow: "Routine ready",
                        title: "Your routine is ready.",
                        subtitle: "You can return to this Glow-Up routine from the dashboard. Each completed scan can refresh the plan with newer saved sections.",
                        prominence: .hero
                    )

                    Button(action: onOpenChat) {
                        AIscendButtonLabel(title: "Ask AI About This Routine", leadingSymbol: "message.fill")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .secondary))
                }
            }

            Spacer(minLength: 150)
        }
    }
}

private struct GlowupRoutineLoadingState: View {
    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.large) {
            Spacer()
            AIscendLoadingIndicator(size: 38, lineWidth: 3)
            Text("Loading your Glow-Up routine")
                .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
            Text("AIScend is checking your saved scan plan.")
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(AIscendTheme.Spacing.screenInset)
    }
}

private struct GlowupRoutineEmptyState: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.large) {
            Spacer()
            DashboardGlassCard(tone: .hero) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    AIscendIconOrb(symbol: "camera.aperture", accent: .sky, size: 72)
                    AIscendSectionHeader(
                        eyebrow: "No routine yet",
                        title: "Complete a scan to build your Glow-Up routine.",
                        subtitle: "Once your scan finishes, AIScend saves personalised sections here so you can return to them from the dashboard.",
                        prominence: .hero
                    )
                    Button(action: onDismiss) {
                        AIscendButtonLabel(title: "Back to Dashboard", leadingSymbol: "house.fill")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .primary))
                }
            }
            Spacer()
        }
        .padding(AIscendTheme.Spacing.screenInset)
    }
}

private struct GlowupRoutineErrorState: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.large) {
            Spacer()
            DashboardGlassCard(tone: .subtle) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    AIscendIconOrb(symbol: "exclamationmark.triangle.fill", accent: .dawn, size: 72)
                    AIscendSectionHeader(
                        eyebrow: "Routine unavailable",
                        title: "Could not load the routine",
                        subtitle: message,
                        prominence: .hero
                    )
                    Button(action: onDismiss) {
                        AIscendButtonLabel(title: "Back to Dashboard", leadingSymbol: "house.fill")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .primary))
                }
            }
            Spacer()
        }
        .padding(AIscendTheme.Spacing.screenInset)
    }
}

private struct GlowupDotsBar: View {
    let totalPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index == currentPage ? AIscendTheme.Colors.accentGlow : AIscendTheme.Colors.borderSubtle)
                    .frame(width: index == currentPage ? 22 : 7, height: 7)
                    .animation(.easeOut(duration: 0.2), value: currentPage)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Glow-Up page \(currentPage + 1) of \(totalPages)")
    }
}

#Preview {
    GlowupRoutineFlowView(
        scanResult: .previewPremium,
        authenticatedUserID: nil,
        onOpenChat: {},
        onFinish: {},
        onDismiss: {}
    )
}
