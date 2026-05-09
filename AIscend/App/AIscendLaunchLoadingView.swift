//
//  AIscendLaunchLoadingView.swift
//  AIscend
//
//  Created by Codex on 5/8/26.
//

import SwiftUI

struct AIscendLaunchLoadingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAppear = false
    @State private var isBreathing = false
    @State private var progress: CGFloat = 0.18
    @State private var shimmerOffset: CGFloat = -0.45

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let shortSide = min(size.width, size.height)
            let contentWidth = min(size.width - AIscendTheme.Spacing.screenInset * 2, 360)
            let stageSize = min(max(shortSide * 0.36, 148), 214)
            let topSpacer = max(size.height * 0.13, AIscendTheme.Spacing.xxLarge)

            ZStack {
                AIscendBackdrop()
                DashboardAmbientLayer()
                launchVignette

                VStack(spacing: 0) {
                    Spacer(minLength: topSpacer)

                    VStack(spacing: AIscendTheme.Spacing.large) {
                        AIscendLaunchBrandStage(
                            stageSize: stageSize,
                            didAppear: didAppear,
                            isBreathing: isBreathing,
                            reduceMotion: reduceMotion
                        )

                        VStack(spacing: AIscendTheme.Spacing.xSmall) {
                            Text("AIScend")
                                .font(.system(size: min(max(shortSide * 0.09, 32), 42), weight: .bold, design: .default))
                                .foregroundStyle(AIscendTheme.Colors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.86)

                            Text("Private analysis workspace")
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                                .textCase(.uppercase)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .opacity(didAppear ? 1 : 0)
                        .offset(y: didAppear ? 0 : 10)

                        AIscendLaunchProgressStrip(
                            progress: progress,
                            shimmerOffset: shimmerOffset,
                            reduceMotion: reduceMotion
                        )
                        .frame(width: contentWidth)
                        .opacity(didAppear ? 1 : 0)
                        .offset(y: didAppear ? 0 : 12)
                    }

                    Spacer(minLength: AIscendTheme.Spacing.xxLarge)

                    AIscendLaunchStatusRow()
                        .frame(width: contentWidth)
                        .opacity(didAppear ? 0.88 : 0)
                        .offset(y: didAppear ? 0 : 8)
                        .padding(.bottom, max(proxy.safeAreaInsets.bottom + AIscendTheme.Spacing.large, AIscendTheme.Spacing.xLarge))
                }
                .frame(width: size.width, height: size.height)
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
            }
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("AIScend is restoring your private analysis workspace")
        .onAppear(perform: startAnimation)
    }

    private var launchVignette: some View {
        ZStack {
            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentGlow.opacity(0.16),
                    AIscendTheme.Colors.accentPrimary.opacity(0.08),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 320
            )

            LinearGradient(
                colors: [
                    Color.black.opacity(0.18),
                    .clear,
                    Color.black.opacity(0.36)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private func startAnimation() {
        guard !didAppear else {
            return
        }

        if reduceMotion {
            didAppear = true
            progress = 0.86
            shimmerOffset = 0.8
            return
        }

        withAnimation(.spring(response: 0.72, dampingFraction: 0.86)) {
            didAppear = true
        }

        // Performance: keep launch motion finite. Repeat-forever glow/shimmer work can overlap the auth handoff transition.
        withAnimation(.easeInOut(duration: 0.9)) {
            isBreathing = true
        }

        withAnimation(.easeOut(duration: 1.35).delay(0.18)) {
            progress = 0.88
        }

        withAnimation(.easeOut(duration: 1.15).delay(0.12)) {
            shimmerOffset = 0.95
        }
    }
}

private struct AIscendLaunchBrandStage: View {
    let stageSize: CGFloat
    let didAppear: Bool
    let isBreathing: Bool
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(AIscendTheme.Colors.accentPrimary.opacity(isBreathing ? 0.22 : 0.13))
                .frame(width: stageSize * 1.32, height: stageSize * 1.32)
                .blur(radius: stageSize * 0.3)
                .scaleEffect(isBreathing ? 1.04 : 0.96)

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            AIscendTheme.Colors.accentGlow.opacity(0.0),
                            AIscendTheme.Colors.accentGlow.opacity(0.42),
                            AIscendTheme.Colors.accentCyan.opacity(0.20),
                            AIscendTheme.Colors.accentGlow.opacity(0.0)
                        ],
                        center: .center
                    ),
                    lineWidth: AIscendTheme.Stroke.thin
                )
                .frame(width: stageSize * 1.08, height: stageSize * 1.08)
                .rotationEffect(.degrees(reduceMotion ? 0 : (isBreathing ? 10 : -10)))

            Circle()
                .stroke(AIscendTheme.Colors.borderSubtle.opacity(0.68), lineWidth: AIscendTheme.Stroke.thin)
                .frame(width: stageSize * 0.86, height: stageSize * 0.86)

            RoundedRectangle(cornerRadius: stageSize * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.surfaceGlass.opacity(0.95),
                            AIscendTheme.Colors.cardGradientEnd.opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: stageSize * 0.62, height: stageSize * 0.62)
                .overlay(
                    RoundedRectangle(cornerRadius: stageSize * 0.28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.22),
                                    AIscendTheme.Colors.accentGlow.opacity(0.32),
                                    Color.white.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: AIscendTheme.Stroke.thin
                        )
                )
                .shadow(color: AIscendTheme.Colors.accentGlow.opacity(isBreathing ? 0.24 : 0.16), radius: stageSize * 0.18, y: stageSize * 0.07)

            AIscendBrandMark(size: stageSize * 0.48, showsWordmark: false)
                .scaleEffect(isBreathing ? 1.02 : 0.98)

            LinearGradient(
                colors: [
                    .clear,
                    Color.white.opacity(0.22),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: stageSize * 0.72, height: stageSize * 0.2)
            .rotationEffect(.degrees(-24))
            .offset(x: reduceMotion ? -stageSize * 0.46 : (isBreathing ? stageSize * 0.34 : -stageSize * 0.46), y: -stageSize * 0.12)
            .mask(
                RoundedRectangle(cornerRadius: stageSize * 0.28, style: .continuous)
                    .frame(width: stageSize * 0.62, height: stageSize * 0.62)
            )
            .opacity(reduceMotion ? 0.14 : 0.62)
        }
        .frame(width: stageSize * 1.4, height: stageSize * 1.4)
        .scaleEffect(didAppear ? 1 : 0.92)
        .opacity(didAppear ? 1 : 0)
    }
}

private struct AIscendLaunchProgressStrip: View {
    let progress: CGFloat
    let shimmerOffset: CGFloat
    let reduceMotion: Bool

    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            GeometryReader { proxy in
                let width = proxy.size.width

                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(AIscendTheme.Colors.surfaceInteractive.opacity(0.58))

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentCyan.opacity(0.9),
                                    AIscendTheme.Colors.accentGlow,
                                    AIscendTheme.Colors.accentPrimary
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(14, width * progress))
                        .overlay(alignment: .leading) {
                            if !reduceMotion {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                .clear,
                                                Color.white.opacity(0.45),
                                                .clear
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: width * 0.28)
                                    .offset(x: width * shimmerOffset)
                                    .blendMode(.screen)
                            }
                        }
                        .clipShape(Capsule(style: .continuous))
                        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.28), radius: 14, y: 0)
                }
            }
            .frame(height: 4)

            HStack {
                Text("Restoring secure session")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: AIscendTheme.Spacing.medium)

                Text("\(Int(progress * 100))%")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    .monospacedDigit()
            }
        }
    }
}

private struct AIscendLaunchStatusRow: View {
    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Circle()
                .fill(AIscendTheme.Colors.accentMint)
                .frame(width: 6, height: 6)
                .shadow(color: AIscendTheme.Colors.accentMint.opacity(0.42), radius: 8)

            Text("Local state ready")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Spacer(minLength: AIscendTheme.Spacing.small)

            Text("session handoff ready")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted.opacity(0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            Capsule(style: .continuous)
                .fill(AIscendTheme.Colors.surfaceGlass.opacity(0.62))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: AIscendTheme.Stroke.thin)
        )
    }
}

#Preview {
    AIscendLaunchLoadingView()
}
