//
//  AIScendRoadmapView.swift
//  AIscend
//

import SwiftUI

struct AIScendRoadmapView: View {
    let onDismiss: (() -> Void)?
    let onOpenScan: (() -> Void)?

    @StateObject private var store = RoadmapStore()
    @State private var showingBuilder = false

    init(
        onDismiss: (() -> Void)? = nil,
        onOpenScan: (() -> Void)? = nil
    ) {
        self.onDismiss = onDismiss
        self.onOpenScan = onOpenScan
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    header

                    if store.isLoading && store.roadmap == nil {
                        loadingState
                    } else if let roadmap = store.roadmap {
                        roadmapContent(roadmap)
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Layout.floatingTabBarClearance)
                .frame(maxWidth: 780, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .task {
            await store.load()
        }
        .sheet(isPresented: $showingBuilder) {
            RoadmapBuilderView(scanSignal: store.scanSignal) { profile in
                store.buildRoadmap(profile: profile)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                AIscendBadge(
                    title: "Private 30/60/90 system",
                    symbol: "lock.shield.fill",
                    style: .accent
                )

                Text("AI Roadmap")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)

                Text("A personalised optimisation path for grooming, recovery, posture, style, skin consistency, and presentation signals.")
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AIscendTheme.Spacing.small)

            if let onDismiss {
                AIscendTopBarButton(symbol: "xmark", action: onDismiss)
            }
        }
    }

    private func roadmapContent(_ roadmap: AIScendRoadmap) -> some View {
        let snapshot = store.progressSnapshot()

        return VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            RoadmapProgressHeader(roadmap: roadmap, snapshot: snapshot)

            dailyActionsSection(roadmap.dailyActions, snapshot: snapshot)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                DashboardSectionHeading(
                    eyebrow: "Top priorities",
                    title: "High-leverage focus",
                    subtitle: "Impact, difficulty, and time-to-visible-change estimates are directional, not guaranteed."
                )

                LazyVStack(spacing: AIscendTheme.Spacing.medium) {
                    ForEach(roadmap.priorities.prefix(5)) { priority in
                        RoadmapPriorityCard(priority: priority)
                    }
                }
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                DashboardSectionHeading(
                    eyebrow: "30 / 60 / 90",
                    title: "Roadmap path",
                    subtitle: "A guided sequence: foundation first, refinement second, optimisation last."
                )

                LazyVStack(spacing: AIscendTheme.Spacing.medium) {
                    ForEach(roadmap.phases) { phase in
                        RoadmapPhaseCard(
                            phase: phase,
                            progress: store.phaseProgress(for: phase),
                            isCurrent: phase.id == snapshot.currentPhaseID
                        )
                    }
                }
            }

            weeklyActionsSection(roadmap.weeklyActions)
            disclaimer
        }
    }

    private func dailyActionsSection(
        _ actions: [RoadmapAction],
        snapshot: RoadmapProgressSnapshot
    ) -> some View {
        DashboardGlassCard(tone: .premium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                        AIscendBadge(title: "Daily execution", symbol: "checkmark.seal.fill", style: .accent)

                        Text("Today's action stack")
                            .aiscendTextStyle(.sectionTitle)

                        Text("\(Int((snapshot.todayCompletion * 100).rounded()))% complete today")
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Button(action: { showingBuilder = true }) {
                        AIscendBadge(title: "Rebuild", symbol: "slider.horizontal.3", style: .neutral)
                    }
                    .buttonStyle(.plain)
                }

                LazyVStack(spacing: AIscendTheme.Spacing.small) {
                    ForEach(actions) { action in
                        RoadmapActionRow(
                            action: action,
                            isComplete: store.isActionCompleteToday(action.id),
                            onToggle: { store.toggleAction(action.id) }
                        )
                    }
                }
            }
        }
    }

    private func weeklyActionsSection(_ actions: [RoadmapAction]) -> some View {
        DashboardGlassCard(tone: .standard) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendSectionHeader(
                    eyebrow: "Weekly optimisation",
                    title: "Review loop",
                    subtitle: "Small reviews keep the plan strategic without overreacting to one day."
                )

                LazyVStack(spacing: AIscendTheme.Spacing.small) {
                    ForEach(actions) { action in
                        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                            AIscendIconOrb(symbol: action.category.symbol, accent: action.category.accent, size: 34)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(action.title)
                                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)

                                Text(action.reason)
                                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(AIscendTheme.Spacing.medium)
                        .background(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                                .fill(Color.white.opacity(0.045))
                        )
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                ZStack {
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentPrimary.opacity(0.28),
                                    AIscendTheme.Colors.surfaceHighlight.opacity(0.34),
                                    AIscendTheme.Colors.cardGradientEnd
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 180)

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        AIscendIconOrb(symbol: "map.fill", accent: .sky, size: 72)

                        Text("Roadmap pending")
                            .aiscendTextStyle(.sectionTitle)
                    }
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    Text("Complete a scan for the sharpest roadmap")
                        .aiscendTextStyle(.sectionTitle)

                    Text("AIScend can build a better 30/60/90 plan when it has scan signals. You can also build a template roadmap now and refine it after your next scan.")
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: AIscendTheme.Spacing.small) {
                    if let onOpenScan {
                        Button {
                            onDismiss?()
                            onOpenScan()
                        } label: {
                            AIscendButtonLabel(title: "Complete Scan", leadingSymbol: "camera.aperture")
                        }
                        .buttonStyle(AIscendButtonStyle(variant: .primary))
                    }

                    Button(action: { showingBuilder = true }) {
                        AIscendButtonLabel(title: "Build Without Scan", leadingSymbol: "sparkles")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: onOpenScan == nil ? .primary : .secondary))
                }
            }
        }
    }

    private var loadingState: some View {
        DashboardGlassCard(tone: .standard) {
            HStack(spacing: AIscendTheme.Spacing.medium) {
                AIscendLoadingIndicator()

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text("Loading roadmap")
                        .aiscendTextStyle(.cardTitle)

                    Text("Checking saved roadmap and scan signals.")
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                }
            }
        }
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)
                .padding(.top, 3)

            Text("AIScend roadmaps are directional optimisation plans. They do not guarantee attractiveness changes, medical outcomes, structural changes, or personal worth. Keep routines comfortable, stop posture or jaw-related actions if pain appears, and use professional care for medical skin, sleep, or pain concerns.")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(Color.white.opacity(0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct RoadmapActionRow: View {
    let action: RoadmapAction
    let isComplete: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(isComplete ? AIscendTheme.Colors.success.opacity(0.22) : Color.white.opacity(0.07))
                        .frame(width: 36, height: 36)

                    Image(systemName: isComplete ? "checkmark" : "circle")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isComplete ? AIscendTheme.Colors.success : AIscendTheme.Colors.textMuted)
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    Text(action.title)
                        .aiscendTextStyle(.cardTitle, color: isComplete ? AIscendTheme.Colors.textSecondary : AIscendTheme.Colors.textPrimary)
                        .strikethrough(isComplete, color: AIscendTheme.Colors.textMuted)

                    Text(action.reason)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AIscendTheme.Spacing.small)

                Text("\(action.estimatedMinutes)m")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                    .monospacedDigit()
            }
            .padding(AIscendTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(isComplete ? AIscendTheme.Colors.success.opacity(0.07) : Color.white.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .stroke(isComplete ? AIscendTheme.Colors.success.opacity(0.26) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AIScendRoadmapView()
}

