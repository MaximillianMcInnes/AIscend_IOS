//
//  AIscendScanStudioView.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import SwiftUI

struct AIscendScanStudioView: View {
    @Bindable var model: AppModel
    var onOpenLatestResult: () -> Void = {}
    var onBeginCapture: () -> Void = {}
    var onOpenChat: () -> Void = {}
    var onOpenRoutine: () -> Void = {}

    @State private var hasAppeared = false

    private var snapshot: DashboardSnapshot {
        .live(from: model)
    }

    private var scoreLabel: String {
        "\(snapshot.score)"
    }

    private var scanCountLabel: String {
        let count = snapshot.scans.count
        return count == 1 ? "1 baseline stored" : "\(count) baselines stored"
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                    heroCard(
                        onBeginCapture: onBeginCapture,
                        onOpenLatestResult: {
                            onOpenLatestResult()
                        }
                    )
                    .scanStudioReveal(isVisible: hasAppeared, delay: 0.02)

                    statusStrip
                        .scanStudioReveal(isVisible: hasAppeared, delay: 0.08)

                    captureProtocol
                        .id("capture-protocol")
                        .scanStudioReveal(isVisible: hasAppeared, delay: 0.14)

                    archiveSection
                        .scanStudioReveal(isVisible: hasAppeared, delay: 0.20)

                    supportSection
                        .scanStudioReveal(isVisible: hasAppeared, delay: 0.26)
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, AIscendTheme.Spacing.large)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            hasAppeared = true
        }
    }

    private func heroCard(
        onBeginCapture: @escaping () -> Void,
        onOpenLatestResult: @escaping () -> Void
    ) -> some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack {
                    AIscendBadge(
                        title: "Scan studio",
                        symbol: "viewfinder.circle.fill",
                        style: .accent
                    )

                    Spacer()

                    AIscendBadge(
                        title: scanCountLabel,
                        symbol: "camera.aperture",
                        style: .neutral
                    )
                }

                AIscendSectionHeader(
                    title: "Capture the next clean baseline",
                    subtitle: "AIScend works best when the scan cadence stays disciplined. Keep lighting stable, hit both angles, and treat each capture like calibrated input."
                )

                HStack(spacing: AIscendTheme.Spacing.small) {
                    scanHeroMetric(
                        title: "Current read",
                        value: scoreLabel,
                        detail: snapshot.tier,
                        symbol: "waveform.path.ecg"
                    )
                    scanHeroMetric(
                        title: "Focus",
                        value: model.analysisGoalSummary,
                        detail: "Priority variable",
                        symbol: "scope"
                    )
                }

                HStack(spacing: AIscendTheme.Spacing.small) {
                    Button(action: onOpenLatestResult) {
                        AIscendButtonLabel(title: "Open Latest Result", leadingSymbol: "sparkles.rectangle.stack.fill")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .primary))

                    Button(action: onBeginCapture) {
                        AIscendButtonLabel(title: "Start Guided Scan", leadingSymbol: "camera.aperture")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .secondary))
                }

                Text("Fresh scan results open automatically after capture, and the latest reveal can still be revisited here anytime.")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
            }
        }
    }

    private var statusStrip: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            scanStatTile(
                title: "Tier",
                value: snapshot.tier,
                detail: "Current account read",
                symbol: "crown.fill",
                accent: .sky
            )

            scanStatTile(
                title: "Streak",
                value: "\(snapshot.streakDays)d",
                detail: "Calibrated consistency",
                symbol: "flame.fill",
                accent: .dawn
            )

            scanStatTile(
                title: "Cadence",
                value: "4 / mo",
                detail: "Recommended baseline tempo",
                symbol: "calendar.badge.clock",
                accent: .mint
            )
        }
    }

    private var captureProtocol: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                DashboardSectionHeading(
                    eyebrow: "Protocol",
                    title: "What a strong capture session looks like",
                    subtitle: "Treat the next baseline like controlled data collection. Small improvements in lighting, posture, and framing make the archive read much sharper."
                )

                VStack(spacing: AIscendTheme.Spacing.medium) {
                    scanProtocolRow(
                        symbol: "sun.max.fill",
                        accent: .dawn,
                        title: "Controlled lighting",
                        detail: "Use stable front lighting and keep harsh overhead contrast out of the frame."
                    )
                    scanProtocolRow(
                        symbol: "person.crop.square",
                        accent: .sky,
                        title: "Front + profile capture",
                        detail: "Log a neutral front shot and a clean side profile so structure reads accurately."
                    )
                    scanProtocolRow(
                        symbol: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left",
                        accent: .mint,
                        title: "Composed posture",
                        detail: "Keep the neck tall, jaw relaxed, and camera level so the read stays consistent across time."
                    )
                }
            }
        }
    }

    private var archiveSection: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            DashboardSectionHeading(
                eyebrow: "Archive",
                title: "Recent baselines",
                subtitle: "Your recent captures stay visible here so the progression feels measured instead of abstract."
            )

            DashboardScanArchiveCard(scans: snapshot.scans)
        }
    }

    private var supportSection: some View {
        DashboardGlassCard(tone: .premium) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack {
                    AIscendBadge(
                        title: "Scan strategy",
                        symbol: "sparkles.rectangle.stack.fill",
                        style: .accent
                    )

                    Spacer()
                }

                AIscendSectionHeader(
                    title: "Want sharper scan discipline?",
                    subtitle: "Open the advisor for capture strategy, or tighten the routine so the next baseline reflects cleaner daily execution."
                )

                HStack(spacing: AIscendTheme.Spacing.small) {
                    Button(action: onOpenChat) {
                        AIscendButtonLabel(title: "Ask Advisor", leadingSymbol: "message.fill")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .primary))

                    Button(action: onOpenRoutine) {
                        AIscendButtonLabel(title: "Tighten Routine", leadingSymbol: "scope")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .secondary))
                }
            }
        }
    }

    private func scanHeroMetric(
        title: String,
        value: String,
        detail: String,
        symbol: String
    ) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            AIscendIconOrb(symbol: symbol, accent: .sky, size: 42)

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            Text(value)
                .aiscendTextStyle(.cardTitle)
                .lineLimit(2)

            Text(detail)
                .aiscendTextStyle(.secondaryBody)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.mediumLarge)
        .aiscendPanel(.muted)
    }

    private func scanStatTile(
        title: String,
        value: String,
        detail: String,
        symbol: String,
        accent: RoutineAccent
    ) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: symbol, accent: accent, size: 42)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(value)
                    .aiscendTextStyle(.metricCompact)

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

    private func scanProtocolRow(
        symbol: String,
        accent: RoutineAccent,
        title: String,
        detail: String
    ) -> some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: symbol, accent: accent, size: 44)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(title)
                    .aiscendTextStyle(.cardTitle)

                Text(detail)
                    .aiscendTextStyle(.body)
            }

            Spacer(minLength: 0)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct ScanStudioRevealModifier: ViewModifier {
    let isVisible: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 18)
            .animation(.easeOut(duration: 0.44).delay(delay), value: isVisible)
    }
}

private extension View {
    func scanStudioReveal(isVisible: Bool, delay: Double) -> some View {
        modifier(ScanStudioRevealModifier(isVisible: isVisible, delay: delay))
    }
}

#Preview {
    NavigationStack {
        AIscendScanStudioView(model: AppModel())
            .toolbar(.hidden, for: .navigationBar)
    }
}
