//
//  ResultsFullscreenShell.swift
//  AIscend
//

import SwiftUI

struct ResultsFullscreenShell<TopRight: View, BottomCTA: View, Content: View>: View {
    let title: String
    let subtitle: String
    let step: Int
    let total: Int
    let maxContentWidth: CGFloat
    let showsBottomCTA: Bool
    private let topRight: TopRight
    private let bottomCTA: BottomCTA
    private let content: Content

    init(
        title: String,
        subtitle: String,
        step: Int,
        total: Int,
        maxContentWidth: CGFloat = 520,
        showsBottomCTA: Bool = true,
        @ViewBuilder topRight: () -> TopRight,
        @ViewBuilder bottomCTA: () -> BottomCTA,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.step = step
        self.total = max(total, 1)
        self.maxContentWidth = maxContentWidth
        self.showsBottomCTA = showsBottomCTA
        self.topRight = topRight()
        self.bottomCTA = bottomCTA()
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ResultsFullscreenBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                        header
                        content
                    }
                    .frame(maxWidth: maxContentWidth, alignment: .topLeading)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, AIscendTheme.Spacing.medium)
                    .padding(.top, geometry.safeAreaInsets.top + AIscendTheme.Spacing.large)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + (showsBottomCTA ? 132 : 180))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsBottomCTA {
                bottomBar
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
                ResultsStepPill(step: step, total: total)

                Spacer(minLength: AIscendTheme.Spacing.small)

                topRight
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                Text(title)
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(subtitle)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            AIscendTheme.Colors.appBackground.opacity(0.78)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 20)

            bottomCTA
                .frame(maxWidth: maxContentWidth)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, AIscendTheme.Spacing.medium)
                .padding(.top, AIscendTheme.Spacing.small)
                .padding(.bottom, AIscendTheme.Spacing.small)
                .background(AIscendTheme.Colors.appBackground.opacity(0.82))
        }
    }
}

private struct ResultsFullscreenBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "070A11"),
                    AIscendTheme.Colors.appBackground,
                    Color(hex: "10111B")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentGlow.opacity(0.28),
                    AIscendTheme.Colors.accentPrimary.opacity(0.12),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 390
            )
            .offset(x: 150, y: -170)

            RadialGradient(
                colors: [
                    Color(hex: "E858FF").opacity(0.13),
                    .clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 320
            )
            .offset(x: -170, y: -110)

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.48)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

private struct ResultsStepPill: View {
    let step: Int
    let total: Int

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Circle()
                .fill(AIscendTheme.Colors.accentGlow)
                .frame(width: 7, height: 7)
                .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.9), radius: 8, x: 0, y: 0)

            Text("\(max(step, 1)) / \(max(total, 1))")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.07))
                .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}
