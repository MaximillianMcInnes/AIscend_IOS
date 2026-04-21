//
//  AIscendDashboardComponents.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation
import SwiftUI

enum DashboardCardTone {
    case hero
    case standard
    case subtle
    case premium
}

struct DashboardAmbientLayer: View {
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentPrimary.opacity(0.22),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 360
            )
            .offset(x: 130, y: -150)

            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentCyan.opacity(0.08),
                    .clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 280
            )
            .offset(x: -140, y: -180)

            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentMint.opacity(0.10),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 320
            )
            .offset(x: -180, y: 260)
        }
        .ignoresSafeArea()
    }
}

struct DashboardSectionHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        AIscendSectionHeader(
            eyebrow: eyebrow,
            title: title,
            subtitle: subtitle
        )
    }
}

struct DashboardGlassCard<Content: View>: View {
    let tone: DashboardCardTone
    private let content: Content

    init(tone: DashboardCardTone = .standard, @ViewBuilder content: () -> Content) {
        self.tone = tone
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AIscendTheme.Spacing.xLarge)
            .background(background)
            .clipShape(shape)
            .overlay(shape.stroke(borderGradient, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.38), radius: shadowRadius, x: 0, y: 16)
            .shadow(color: glowColor, radius: 26, x: 0, y: 0)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
    }

    private var shadowRadius: CGFloat {
        switch tone {
        case .hero, .premium:
            28
        case .standard:
            20
        case .subtle:
            16
        }
    }

    private var glowColor: Color {
        switch tone {
        case .hero:
            AIscendTheme.Colors.accentPrimary.opacity(0.18)
        case .premium:
            AIscendTheme.Colors.accentGlow.opacity(0.16)
        case .standard:
            AIscendTheme.Colors.accentPrimary.opacity(0.08)
        case .subtle:
            .clear
        }
    }

    private var fillGradient: LinearGradient {
        switch tone {
        case .hero:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.cardGradientStart.opacity(0.98),
                    AIscendTheme.Colors.accentDeep.opacity(0.42),
                    AIscendTheme.Colors.cardGradientEnd.opacity(1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .premium:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.cardGradientStart.opacity(0.98),
                    AIscendTheme.Colors.surfaceInteractive.opacity(0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .subtle:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.surfaceMuted.opacity(0.94),
                    AIscendTheme.Colors.appBackground.opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .standard:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.surfaceGlass.opacity(0.96),
                    AIscendTheme.Colors.cardGradientEnd.opacity(0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                AIscendTheme.Colors.borderStrong,
                tone == .premium || tone == .hero ? AIscendTheme.Colors.accentGlow.opacity(0.38) : AIscendTheme.Colors.borderSubtle,
                AIscendTheme.Colors.borderSubtle
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var background: some View {
        ZStack {
            shape.fill(fillGradient)
            shape.fill(.ultraThinMaterial).opacity(0.14)
            shape.fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        .clear,
                        AIscendTheme.Colors.accentGlow.opacity(tone == .hero || tone == .premium ? 0.10 : 0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            if tone == .hero || tone == .premium {
                Circle()
                    .fill(AIscendTheme.Colors.accentGlow.opacity(tone == .hero ? 0.18 : 0.12))
                    .frame(width: 240, height: 240)
                    .blur(radius: 34)
                    .offset(x: 110, y: -130)
            }

            if tone == .hero {
                Circle()
                    .fill(AIscendTheme.Colors.accentCyan.opacity(0.08))
                    .frame(width: 180, height: 180)
                    .blur(radius: 26)
                    .offset(x: -120, y: 80)
            }
        }
    }
}

struct DashboardHeader: View {
    let greeting: String
    let subtitle: String
    let streakDays: Int
    let checkedInToday: Bool
    let initials: String
    let onOpenStreaks: () -> Void
    let onOpenAccount: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.mediumLarge) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                AIscendBadge(
                    title: "Private Command",
                    symbol: "lock.shield.fill",
                    style: .accent
                )

                Text(greeting)
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .lineLimit(2)

                Text(subtitle)
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AIscendTheme.Spacing.small)

            VStack(alignment: .trailing, spacing: AIscendTheme.Spacing.small) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    Button(action: onOpenStreaks) {
                        HStack(spacing: AIscendTheme.Spacing.xSmall) {
                            Image(systemName: checkedInToday ? "checkmark.seal.fill" : "flame.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AIscendTheme.Colors.accentGlow)

                            Text("\(streakDays)d")
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                        }
                        .padding(.horizontal, AIscendTheme.Spacing.small)
                        .padding(.vertical, AIscendTheme.Spacing.xSmall)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.88))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: onOpenAccount) {
                        Text(initials)
                            .font(.system(size: 13, weight: .bold, design: .default))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)
                            .frame(width: 42, height: 42)
                            .background(
                                Circle()
                                    .fill(RoutineAccent.sky.gradient.opacity(0.25))
                            )
                            .overlay(
                                Circle()
                                    .stroke(AIscendTheme.Colors.accentGlow.opacity(0.34), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open account")
                }
            }
        }
    }
}

struct DashboardHeroCard: View {
    let snapshot: DashboardSnapshot
    let scanCountLabel: String
    let onPrimary: () -> Void
    let onSecondary: () -> Void

    var body: some View {
        DashboardGlassCard(tone: .hero) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: AIscendTheme.Spacing.xLarge) {
                    heroCopy
                    Spacer(minLength: 0)
                    DashboardHeroOrb(score: snapshot.score, percentile: snapshot.percentile)
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                    heroCopy
                    HStack {
                        Spacer(minLength: 0)
                        DashboardHeroOrb(score: snapshot.score, percentile: snapshot.percentile)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var heroCopy: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendBadge(
                title: "Current Position",
                symbol: "scope",
                style: .neutral
            )

            HStack(alignment: .firstTextBaseline, spacing: AIscendTheme.Spacing.xSmall) {
                Text("\(snapshot.score)")
                    .font(.system(size: 64, weight: .bold, design: .default))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)

                Text("/100")
                    .font(.system(size: 22, weight: .semibold, design: .default))
                    .foregroundStyle(AIscendTheme.Colors.textMuted)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    heroPill(text: snapshot.tier, symbol: "crown.fill")
                    heroPill(text: "Top \(snapshot.percentile)%", symbol: "sparkles")
                    heroPill(text: scanCountLabel, symbol: "camera.aperture")
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    heroPill(text: snapshot.tier, symbol: "crown.fill")
                    heroPill(text: "Top \(snapshot.percentile)%", symbol: "sparkles")
                    heroPill(text: scanCountLabel, symbol: "camera.aperture")
                }
            }

            Text("\(signedMetric(snapshot.delta)) since last scan")
                .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.accentGlow)

            Text(snapshot.heroStatement)
                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)

            HStack(spacing: AIscendTheme.Spacing.small) {
                Button(action: onPrimary) {
                    AIscendButtonLabel(title: "Continue Analysis", leadingSymbol: "waveform.path.ecg")
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))

                Button(action: onSecondary) {
                    AIscendButtonLabel(title: "Open Routine", leadingSymbol: "square.grid.2x2.fill")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
            }
        }
    }

    private func heroPill(text: String, symbol: String) -> some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))

            Text(text)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, AIscendTheme.Spacing.xSmall)
        .background(
            Capsule(style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.86))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

struct DashboardHeroOrb: View {
    let score: Int
    let percentile: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AIscendTheme.Colors.accentGlow.opacity(0.18),
                            AIscendTheme.Colors.accentPrimary.opacity(0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 12,
                        endRadius: 110
                    )
                )
                .frame(width: 190, height: 190)

            Circle()
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 16)
                .frame(width: 166, height: 166)

            Circle()
                .trim(from: 0.08, to: 0.92)
                .stroke(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.accentGlow.opacity(0.24),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-110))
                .frame(width: 166, height: 166)

            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    RoutineAccent.sky.gradient,
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 166, height: 166)
                .shadow(color: RoutineAccent.sky.glow, radius: 18, x: 0, y: 0)

            VStack(spacing: AIscendTheme.Spacing.xxSmall) {
                Text("Top \(percentile)%")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .minimumScaleFactor(0.8)

                Text("placement")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }
        }
        .frame(width: 190, height: 190)
    }
}

struct DashboardQuickActionGrid: View {
    let onSelect: (DashboardQuickAction) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AIscendTheme.Spacing.small), count: 2)

    var body: some View {
        LazyVGrid(columns: columns, spacing: AIscendTheme.Spacing.small) {
            ForEach(DashboardQuickAction.allCases) { action in
                Button {
                    onSelect(action)
                } label: {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        AIscendIconOrb(symbol: action.symbol, accent: action.accent, size: 44)

                        Text(action.title)
                            .aiscendTextStyle(.cardTitle)
                            .lineLimit(1)

                        Text(action.detail)
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
                }
                .buttonStyle(DashboardQuickActionButtonStyle())
            }
        }
    }
}

struct DashboardProgressCard: View {
    let snapshot: DashboardSnapshot

    var body: some View {
        DashboardGlassCard {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text("Measured movement")
                        .aiscendTextStyle(.sectionTitle)

                    Text("Last six calibration points")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                }

                Spacer()

                Text(signedMetric(snapshot.delta))
                    .aiscendTextStyle(.metricCompact, color: AIscendTheme.Colors.accentGlow)
            }

            DashboardTrendChart(points: snapshot.trendPoints)
                .frame(height: 188)
                .padding(.top, AIscendTheme.Spacing.medium)

            HStack {
                ForEach(snapshot.trendPoints) { point in
                    Text(point.label)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, AIscendTheme.Spacing.xSmall)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: AIscendTheme.Spacing.small),
                    GridItem(.flexible(), spacing: AIscendTheme.Spacing.small)
                ],
                spacing: AIscendTheme.Spacing.small
            ) {
                ForEach(snapshot.metrics) { metric in
                    DashboardMetricTile(metric: metric)
                }
            }
            .padding(.top, AIscendTheme.Spacing.large)
        }
    }
}

struct DashboardMetricTile: View {
    let metric: DashboardMetricModel

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack {
                AIscendIconOrb(symbol: metric.symbol, accent: metric.accent, size: 38)
                Spacer()
            }

            Text(metric.value)
                .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)

            Text(metric.title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)

            Text(metric.detail)
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 158, alignment: .topLeading)
        .padding(AIscendTheme.Spacing.mediumLarge)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

struct DashboardInsightsDeck: View {
    let insights: [DashboardInsightModel]

    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            ForEach(Array(insights.enumerated()), id: \.element.id) { index, insight in
                DashboardInsightCard(
                    insight: insight,
                    highlighted: index == 0
                )
            }
        }
    }
}

struct DashboardInsightCard: View {
    let insight: DashboardInsightModel
    let highlighted: Bool

    var body: some View {
        DashboardGlassCard(tone: highlighted ? .hero : .subtle) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                AIscendIconOrb(symbol: insight.symbol, accent: insight.accent, size: 42)

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    AIscendBadge(
                        title: highlighted ? "Priority signal" : "AI signal",
                        symbol: "sparkles",
                        style: highlighted ? .accent : .subtle
                    )

                    Text(insight.title)
                        .aiscendTextStyle(.cardTitle)

                    Text(insight.detail)
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

struct DashboardRoutineCard: View {
    let progress: Double
    let streakDays: Int
    let checkedInToday: Bool
    let steps: [RoutineStep]
    let onToggle: (RoutineStep) -> Void
    let onShare: () -> Void
    let onOpenCheckIn: () -> Void
    let onOpenConsistency: () -> Void
    let onOpenRoutine: () -> Void

    var body: some View {
        DashboardGlassCard(tone: .standard) {
            HStack(alignment: .center, spacing: AIscendTheme.Spacing.large) {
                DashboardRoutineDial(progress: progress, streakDays: streakDays)

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    AIscendBadge(
                        title: checkedInToday ? "\(streakDays)-day protected streak" : "\(streakDays)-day live streak",
                        symbol: checkedInToday ? "checkmark.seal.fill" : "flame.fill",
                        style: .neutral
                    )

                    Text("Your routine is the quiet system behind the visible result.")
                        .aiscendTextStyle(.sectionTitle)

                    Text("Keep the next three moves clean and deliberate, then reopen the full routine whenever you want the longer sequence.")
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                }
            }

            HStack {
                Spacer(minLength: 0)

                AIScendShareEntryButton(title: "Share progress", action: onShare)
            }
            .padding(.top, AIscendTheme.Spacing.medium)

            DashboardConsistencyStrip(
                checkedInToday: checkedInToday,
                streakDays: streakDays,
                onOpenCheckIn: onOpenCheckIn,
                onOpenConsistency: onOpenConsistency
            )
            .padding(.top, AIscendTheme.Spacing.mediumLarge)

            VStack(spacing: AIscendTheme.Spacing.small) {
                ForEach(steps) { step in
                    Button {
                        onToggle(step)
                    } label: {
                        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                            AIscendIconOrb(symbol: step.symbol, accent: step.accent, size: 38)

                            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                                Text(step.title)
                                    .aiscendTextStyle(.cardTitle)
                                    .multilineTextAlignment(.leading)

                                Text(step.detail)
                                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: step.isComplete ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(step.isComplete ? step.accent.tint : AIscendTheme.Colors.textMuted)
                        }
                        .padding(AIscendTheme.Spacing.medium)
                        .background(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(step.isComplete ? 0.84 : 0.62))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                                .stroke(
                                    step.isComplete ? step.accent.tint.opacity(0.34) : AIscendTheme.Colors.borderSubtle,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, AIscendTheme.Spacing.large)

            Button(action: onOpenRoutine) {
                AIscendButtonLabel(title: "Open Full Routine", leadingSymbol: "square.grid.2x2.fill")
            }
            .buttonStyle(AIscendButtonStyle(variant: .secondary))
            .padding(.top, AIscendTheme.Spacing.large)
        }
    }
}

private struct DashboardConsistencyStrip: View {
    let checkedInToday: Bool
    let streakDays: Int
    let onOpenCheckIn: () -> Void
    let onOpenConsistency: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack(alignment: .center, spacing: AIscendTheme.Spacing.small) {
                Image(systemName: checkedInToday ? "checkmark.seal.fill" : "flame.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(checkedInToday ? AIscendTheme.Colors.success : AIscendTheme.Colors.accentGlow)

                Text("\(streakDays)-day daily streak")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                    .padding(.horizontal, AIscendTheme.Spacing.small)
                    .padding(.vertical, AIscendTheme.Spacing.xSmall)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.78))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                    )

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(checkedInToday ? "Today's signal is protected" : "Today's check-in is still open")
                    .aiscendTextStyle(.cardTitle)

                Text(checkedInToday ? "The chain is clean. Reopen it only if you want to refine the reflection." : "Close the day with a fast check-in before attention drifts.")
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
            }

            HStack(spacing: AIscendTheme.Spacing.mediumLarge) {
                DashboardInlineActionLink(
                    title: checkedInToday ? "Review check-in" : "Complete check-in",
                    symbol: "calendar.badge.checkmark",
                    action: onOpenCheckIn
                )

                DashboardInlineActionLink(
                    title: "Open streaks",
                    symbol: "flame.fill",
                    action: onOpenConsistency
                )
            }
        }
    }
}

private struct DashboardInlineActionLink: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))

                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.textMuted)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(AIscendTheme.Colors.accentGlow)
    }
}

struct DashboardRoutineDial: View {
    let progress: Double
    let streakDays: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 12)

            Circle()
                .trim(from: 0, to: CGFloat(max(progress, 0.06)))
                .stroke(
                    RoutineAccent.sky.gradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: RoutineAccent.sky.glow, radius: 16, x: 0, y: 0)

            VStack(spacing: AIscendTheme.Spacing.xxSmall) {
                Text("\(Int(progress * 100))%")
                    .aiscendTextStyle(.metricCompact)

                Text("\(streakDays)d")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
            }
        }
        .frame(width: 112, height: 112)
    }
}

struct DashboardScanArchiveCard: View {
    let scans: [DashboardScanPreviewModel]

    var body: some View {
        DashboardGlassCard {
            VStack(spacing: AIscendTheme.Spacing.small) {
                ForEach(scans) { scan in
                    DashboardRecentScanRow(scan: scan)
                }
            }
        }
    }
}

struct DashboardRecentScanRow: View {
    let scan: DashboardScanPreviewModel

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.accentPrimary.opacity(0.24),
                                AIscendTheme.Colors.surfaceHighlight.opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)

                Image(systemName: scan.symbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(scan.title)
                    .aiscendTextStyle(.cardTitle)

                Text("\(scan.dateLabel) / \(scan.captureLabel)")
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(scan.scoreLabel)
                    .aiscendTextStyle(.sectionTitle)

                Text(scan.deltaLabel)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
            }
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
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

struct DashboardPremiumCard: View {
    let onUnlock: () -> Void

    var body: some View {
        DashboardGlassCard(tone: .premium) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.mediumLarge) {
                ZStack {
                    Circle()
                        .fill(AIscendTheme.Colors.accentPrimary.opacity(0.22))
                        .frame(width: 54, height: 54)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    AIscendBadge(
                        title: "Premium Layer",
                        symbol: "crown.fill",
                        style: .accent
                    )

                    Text("Unlock deeper reports and richer placement reads")
                        .aiscendTextStyle(.sectionTitle)

                    Text("Side-profile breakdowns, more visual progress reports, and deeper advisor access sit behind the premium layer.")
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                        premiumPoint("Detailed facial ratio placement")
                        premiumPoint("Long-range comparative progress reports")
                        premiumPoint("Priority advisor access with unlimited depth")
                    }
                    .padding(.top, AIscendTheme.Spacing.xSmall)

                    Button(action: onUnlock) {
                        AIscendButtonLabel(title: "Unlock Advanced Reports", leadingSymbol: "arrow.up.forward")
                    }
                    .buttonStyle(AIscendButtonStyle(variant: .primary))
                    .padding(.top, AIscendTheme.Spacing.small)
                }
            }
        }
    }

    private func premiumPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)
                .padding(.top, 2)

            Text(text)
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
        }
    }
}

struct DashboardPremiumUpsellSheet: View {
    let premiumURL: URL?
    let onDismiss: () -> Void

    var body: some View {
        AIscendUpgradeView(
            premiumURL: premiumURL,
            onDismiss: onDismiss
        )
    }
}

struct DashboardTrendChart: View {
    let points: [DashboardTrendPoint]
    @State private var reveal: CGFloat = 0

    private var minimumValue: Double {
        (points.map(\.score).min() ?? 0) - 4
    }

    private var maximumValue: Double {
        (points.map(\.score).max() ?? 100) + 4
    }

    var body: some View {
        GeometryReader { proxy in
            let coordinates = chartPoints(in: proxy.size)

            ZStack {
                grid(in: proxy.size)
                    .stroke(AIscendTheme.Colors.divider, lineWidth: 1)

                areaPath(points: coordinates, in: proxy.size)
                    .trim(from: 0, to: reveal)
                    .fill(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.accentGlow.opacity(0.22),
                                AIscendTheme.Colors.accentPrimary.opacity(0.04),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                linePath(points: coordinates)
                    .trim(from: 0, to: reveal)
                    .stroke(
                        RoutineAccent.sky.gradient,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: RoutineAccent.sky.glow, radius: 12, x: 0, y: 0)

                ForEach(Array(points.indices), id: \.self) { index in
                    let point = coordinates[index]

                    Circle()
                        .fill(index == points.indices.last ? AIscendTheme.Colors.textPrimary : AIscendTheme.Colors.accentGlow)
                        .frame(width: index == points.indices.last ? 10 : 7, height: index == points.indices.last ? 10 : 7)
                        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.34), radius: 10, x: 0, y: 0)
                        .position(point)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) {
                reveal = 1
            }
        }
    }

    private func chartPoints(in size: CGSize) -> [CGPoint] {
        guard points.count > 1 else {
            return [CGPoint(x: size.width / 2, y: size.height / 2)]
        }

        let span = max(maximumValue - minimumValue, 1)

        return points.enumerated().map { index, point in
            let x = size.width * CGFloat(index) / CGFloat(points.count - 1)
            let normalized = (point.score - minimumValue) / span
            let y = size.height - (CGFloat(normalized) * (size.height - 12)) - 6
            return CGPoint(x: x, y: y)
        }
    }

    private func linePath(points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else {
            return path
        }

        path.move(to: first)

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midpoint = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            path.addQuadCurve(to: midpoint, control: CGPoint(x: midpoint.x, y: previous.y))
            path.addQuadCurve(to: current, control: CGPoint(x: midpoint.x, y: current.y))
        }

        return path
    }

    private func areaPath(points: [CGPoint], in size: CGSize) -> Path {
        var path = linePath(points: points)
        guard let last = points.last, let first = points.first else {
            return path
        }

        path.addLine(to: CGPoint(x: last.x, y: size.height))
        path.addLine(to: CGPoint(x: first.x, y: size.height))
        path.closeSubpath()
        return path
    }

    private func grid(in size: CGSize) -> Path {
        var path = Path()

        for row in 0...3 {
            let y = size.height * CGFloat(row) / 3
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }

        return path
    }
}

private struct DashboardQuickActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(AIscendTheme.Spacing.mediumLarge)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.68))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 10)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(AIscendTheme.Motion.press, value: configuration.isPressed)
    }
}

private func signedMetric(_ value: Double) -> String {
    let sign = value >= 0 ? "+" : ""
    return "\(sign)\(String(format: "%.1f", value))"
}
