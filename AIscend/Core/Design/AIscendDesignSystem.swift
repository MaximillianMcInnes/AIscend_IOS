//
//  AIscendDesignSystem.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import SwiftUI

enum AIscendPanelStyle {
    case standard
    case elevated
    case hero
    case muted

    var fill: LinearGradient {
        switch self {
        case .standard:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.surfaceGlass,
                    AIscendTheme.Colors.cardGradientEnd.opacity(0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .elevated:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.elevatedSurface,
                    AIscendTheme.Colors.surfaceInteractive
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .hero:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.cardGradientStart,
                    AIscendTheme.Colors.accentDeep.opacity(0.52),
                    AIscendTheme.Colors.cardGradientEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .muted:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.surfaceMuted.opacity(0.96),
                    AIscendTheme.Colors.secondaryBackground.opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var border: LinearGradient {
        switch self {
        case .hero:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.borderStrong,
                    AIscendTheme.Colors.accentGlow.opacity(0.34),
                    AIscendTheme.Colors.borderSubtle.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.borderStrong,
                    AIscendTheme.Colors.borderSubtle
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var glow: Color {
        switch self {
        case .hero:
            AIscendTheme.Colors.heroAura
        case .elevated:
            AIscendTheme.Colors.accentPrimary.opacity(0.10)
        default:
            .clear
        }
    }

    var shadowColor: Color {
        switch self {
        case .hero:
            AIscendTheme.Shadow.card
        case .elevated:
            AIscendTheme.Shadow.ambient
        default:
            AIscendTheme.Shadow.subtle
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .hero:
            30
        case .elevated:
            22
        default:
            16
        }
    }

    var shadowYOffset: CGFloat {
        switch self {
        case .hero:
            18
        case .elevated:
            14
        default:
            10
        }
    }
}

enum AIscendButtonVariant {
    case primary
    case secondary
    case ghost
    case destructive

    var foreground: Color {
        switch self {
        case .primary:
            AIscendTheme.Colors.textPrimary
        case .secondary, .ghost:
            AIscendTheme.Colors.textPrimary
        case .destructive:
            AIscendTheme.Colors.textPrimary
        }
    }

    var background: LinearGradient {
        switch self {
        case .primary:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.accentGlow,
                    AIscendTheme.Colors.accentSoft,
                    AIscendTheme.Colors.accentPrimary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.surfaceInteractive.opacity(0.95),
                    AIscendTheme.Colors.surfaceMuted.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .ghost:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.surfaceHighlight.opacity(0.22),
                    AIscendTheme.Colors.surfaceHighlight.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .destructive:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.error.opacity(0.95),
                    Color(hex: "C63C61")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var border: Color {
        switch self {
        case .primary:
            AIscendTheme.Colors.accentGlow.opacity(0.52)
        case .secondary:
            AIscendTheme.Colors.borderStrong
        case .ghost:
            AIscendTheme.Colors.borderSubtle
        case .destructive:
            AIscendTheme.Colors.error.opacity(0.52)
        }
    }

    var glow: Color {
        switch self {
        case .primary:
            AIscendTheme.Colors.accentPrimary.opacity(0.24)
        case .destructive:
            AIscendTheme.Colors.error.opacity(0.22)
        default:
            .clear
        }
    }
}

enum AIscendBadgeStyle {
    case accent
    case neutral
    case subtle
    case success
    case locked

    var fill: Color {
        switch self {
        case .accent:
            AIscendTheme.Colors.accentPrimary.opacity(0.18)
        case .neutral:
            AIscendTheme.Colors.surfaceHighlight.opacity(0.88)
        case .subtle:
            AIscendTheme.Colors.surfaceMuted.opacity(0.92)
        case .success:
            AIscendTheme.Colors.success.opacity(0.18)
        case .locked:
            AIscendTheme.Colors.accentDeep.opacity(0.28)
        }
    }

    var border: Color {
        switch self {
        case .accent:
            AIscendTheme.Colors.accentGlow.opacity(0.42)
        case .neutral, .subtle:
            AIscendTheme.Colors.borderSubtle
        case .success:
            AIscendTheme.Colors.success.opacity(0.42)
        case .locked:
            AIscendTheme.Colors.accentSoft.opacity(0.36)
        }
    }

    var foreground: Color {
        switch self {
        case .accent, .neutral, .subtle, .locked:
            AIscendTheme.Colors.textPrimary
        case .success:
            AIscendTheme.Colors.success
        }
    }
}

private struct AIscendPanelModifier: ViewModifier {
    let style: AIscendPanelStyle

    func body(content: Content) -> some View {
        content
            .background(panelBackground)
            .clipShape(shape)
            .overlay(panelBorder)
            .shadow(color: style.shadowColor, radius: style.shadowRadius, x: 0, y: style.shadowYOffset)
            .shadow(color: style.glow, radius: style == .hero ? 34 : 20, x: 0, y: 0)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
    }

    private var panelBackground: some View {
        ZStack {
            shape
                .fill(style.fill)

            shape
                .fill(.ultraThinMaterial)
                .opacity(style == .muted ? 0.08 : 0.14)

            shape
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.surfaceGloss,
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .opacity(style == .muted ? 0.38 : 0.86)

            if style == .hero {
                shape
                    .fill(
                        RadialGradient(
                            colors: [
                                AIscendTheme.Colors.accentGlow.opacity(0.18),
                                AIscendTheme.Colors.accentPrimary.opacity(0.08),
                                .clear
                            ],
                            center: .topTrailing,
                            startRadius: 10,
                            endRadius: 260
                        )
                    )
            }
        }
    }

    private var panelBorder: some View {
        shape
            .stroke(style.border, lineWidth: AIscendTheme.Stroke.thin)
    }
}

struct AIscendButtonStyle: ButtonStyle {
    let variant: AIscendButtonVariant

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .aiscendTextStyle(.buttonLabel, color: variant.foreground)
            .padding(.horizontal, AIscendTheme.Spacing.mediumLarge)
            .padding(.vertical, AIscendTheme.Spacing.medium)
            .frame(minHeight: 56)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(variant.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.10),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .stroke(variant.border, lineWidth: AIscendTheme.Stroke.thin)
            )
            .shadow(color: variant.glow, radius: 20, x: 0, y: 12)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(AIscendTheme.Motion.press, value: configuration.isPressed)
    }
}

struct AIscendButtonLabel: View {
    let title: String
    let leadingSymbol: String?
    let trailingSymbol: String?

    init(title: String, leadingSymbol: String? = nil, trailingSymbol: String? = nil) {
        self.title = title
        self.leadingSymbol = leadingSymbol
        self.trailingSymbol = trailingSymbol
    }

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            if let leadingSymbol {
                Image(systemName: leadingSymbol)
                    .font(.system(size: 15, weight: .semibold))
            }

            Text(title)
                .lineLimit(1)

            if let trailingSymbol {
                Spacer(minLength: 0)

                Image(systemName: trailingSymbol)
                    .font(.system(size: 14, weight: .semibold))
            }
        }
    }
}

struct AIscendSectionHeader: View {
    enum Prominence {
        case hero
        case standard
    }

    let eyebrow: String?
    let title: String
    let subtitle: String?
    let prominence: Prominence

    init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        prominence: Prominence = .standard
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.prominence = prominence
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            if let eyebrow, !eyebrow.isEmpty {
                Text(eyebrow.uppercased())
                    .aiscendTextStyle(.eyebrow, color: AIscendTheme.Colors.accentGlow)
            }

            Text(title)
                .aiscendTextStyle(prominence == .hero ? .heroTitle : .sectionTitle)
                .lineSpacing(prominence == .hero ? 2 : 0)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .aiscendTextStyle(prominence == .hero ? .body : .secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct AIscendBadge: View {
    let title: String
    let symbol: String?
    let style: AIscendBadgeStyle

    init(title: String, symbol: String? = nil, style: AIscendBadgeStyle = .neutral) {
        self.title = title
        self.symbol = symbol
        self.style = style
    }

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .semibold))
            }

            Text(title)
                .aiscendTextStyle(.caption, color: style.foreground)
                .lineLimit(1)
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, AIscendTheme.Spacing.xSmall)
        .background(
            Capsule(style: .continuous)
                .fill(style.fill)
                .overlay(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.03))
                )
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(style.border, lineWidth: AIscendTheme.Stroke.thin)
        )
    }
}

struct AIscendBrandMark: View {
    var size: CGFloat = 64
    var showsWordmark: Bool = true
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        let emblemSize = size
        let wordmarkSpacing = max(AIscendTheme.Spacing.xSmall, size * 0.14)

        Group {
            if showsWordmark {
                HStack(spacing: wordmarkSpacing) {
                    emblem(size: emblemSize)

                    VStack(alignment: alignment, spacing: AIscendTheme.Spacing.xxSmall) {
                        Text("AIScend")
                            .font(.system(size: max(18, size * 0.34), weight: .bold, design: .default))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)

                        Text("PRIVATE ANALYSIS")
                            .font(.system(size: max(10, size * 0.15), weight: .semibold, design: .default))
                            .tracking(1.2)
                            .foregroundStyle(AIscendTheme.Colors.accentGlow)
                    }
                }
            } else {
                emblem(size: emblemSize)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("AIScend")
    }

    private func emblem(size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.surfaceGlass,
                            AIscendTheme.Colors.cardGradientEnd.opacity(0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.borderStrong,
                                    AIscendTheme.Colors.accentGlow.opacity(0.34)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: AIscendTheme.Stroke.thin
                        )
                )

            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(AIscendTheme.Colors.accentPrimary.opacity(0.18))
                .blur(radius: size * 0.22)
                .padding(size * 0.18)

            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .padding(size * 0.18)
        }
        .frame(width: size, height: size)
        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.24), radius: size * 0.22, x: 0, y: size * 0.08)
    }
}

struct AIscendIconOrb: View {
    let symbol: String
    let accent: RoutineAccent
    let size: CGFloat

    init(symbol: String, accent: RoutineAccent = .sky, size: CGFloat = 44) {
        self.symbol = symbol
        self.accent = accent
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.gradient)
                .opacity(0.18)
                .background(
                    Circle()
                        .fill(accent.gradient)
                        .blur(radius: 22)
                        .opacity(0.28)
                )

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.surfaceHighlight.opacity(0.8),
                            AIscendTheme.Colors.surfaceGlass.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(1)

            Circle()
                .stroke(accent.tint.opacity(0.36), lineWidth: AIscendTheme.Stroke.thin)

            Image(systemName: symbol)
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
        }
        .frame(width: size, height: size)
    }
}

struct AIscendMetricCard: View {
    let title: String
    let value: String
    let detail: String
    let symbol: String
    let accent: RoutineAccent
    var highlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(alignment: .top) {
                AIscendIconOrb(symbol: symbol, accent: accent, size: 42)

                Spacer()

                AIscendBadge(
                    title: accent.rawValue,
                    style: highlighted ? .accent : .subtle
                )
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                Text(value)
                    .aiscendTextStyle(.metricCompact)

                Text(title)
                    .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)

                Text(detail)
                    .aiscendTextStyle(.secondaryBody)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 164, alignment: .topLeading)
        .padding(AIscendTheme.Spacing.mediumLarge)
        .aiscendPanel(highlighted ? .hero : .standard)
    }
}

struct AIscendLoadingIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 10)

            Circle()
                .trim(from: 0.08, to: 0.72)
                .stroke(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.accentGlow,
                            AIscendTheme.Colors.accentPrimary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(isAnimating ? 360 : 0))

            Circle()
                .fill(AIscendTheme.Colors.accentGlow)
                .frame(width: 10, height: 10)
                .offset(y: -31)
                .blur(radius: 0.3)
                .opacity(0.92)
        }
        .frame(width: 76, height: 76)
        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.24), radius: 22, x: 0, y: 0)
        .onAppear {
            guard !reduceMotion else {
                return
            }

            withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

private struct AIscendInputModifier: ViewModifier {
    let isFocused: Bool

    func body(content: Content) -> some View {
        content
            .font(AIscendTheme.Typography.input)
            .foregroundStyle(AIscendTheme.Colors.textPrimary)
            .padding(.horizontal, AIscendTheme.Spacing.medium)
            .padding(.vertical, AIscendTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(AIscendTheme.Colors.fieldFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .fill(Color.white.opacity(0.02))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .stroke(
                        isFocused ? AIscendTheme.Colors.accentGlow : AIscendTheme.Colors.borderSubtle,
                        lineWidth: AIscendTheme.Stroke.thin
                    )
            )
            .shadow(
                color: isFocused ? AIscendTheme.Shadow.focus : .clear,
                radius: isFocused ? 22 : 0,
                x: 0,
                y: 0
            )
            .tint(AIscendTheme.Colors.accentSoft)
    }
}

struct AIscendCapsule: View {
    let title: String
    let symbol: String
    let isActive: Bool

    var body: some View {
        AIscendBadge(
            title: title,
            symbol: symbol,
            style: isActive ? .accent : .neutral
        )
    }
}

struct AIscendTopBarButton: View {
    let symbol: String
    var highlighted: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: highlighted
                                ? [
                                    AIscendTheme.Colors.accentPrimary.opacity(0.30),
                                    AIscendTheme.Colors.accentDeep.opacity(0.34)
                                ]
                                : [
                                    AIscendTheme.Colors.surfaceHighlight.opacity(0.92),
                                    AIscendTheme.Colors.surfaceMuted.opacity(0.92)
                                ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(highlighted ? AIscendTheme.Colors.accentGlow : AIscendTheme.Colors.textPrimary)
            }
            .frame(width: 44, height: 44)
            .overlay(
                Circle()
                    .stroke(
                        highlighted ? AIscendTheme.Colors.accentGlow.opacity(0.42) : AIscendTheme.Colors.borderSubtle,
                        lineWidth: AIscendTheme.Stroke.thin
                    )
            )
            .shadow(color: highlighted ? AIscendTheme.Colors.accentPrimary.opacity(0.18) : .clear, radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct AIscendStatChip: View {
    let title: String
    let value: String
    var symbol: String? = nil
    var accent: RoutineAccent = .sky

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            if let symbol {
                AIscendIconOrb(symbol: symbol, accent: accent, size: 34)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                Text(value)
                    .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            Capsule(style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.82))
                .overlay(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.025))
                )
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(accent.tint.opacity(0.24), lineWidth: AIscendTheme.Stroke.thin)
        )
    }
}

struct AIscendEditorialHeroCard<Content: View>: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?
    var accent: RoutineAccent = .sky
    private let content: Content

    init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        accent: RoutineAccent = .sky,
        @ViewBuilder content: () -> Content
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.cardGradientStart,
                            accent.tint.opacity(0.22),
                            AIscendTheme.Colors.cardGradientEnd
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(accent.gradient)
                .frame(width: 220, height: 220)
                .blur(radius: 34)
                .opacity(0.34)
                .offset(x: 140, y: -90)

            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.mediaScrimTop,
                            .clear,
                            AIscendTheme.Colors.mediaScrimBottom
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                AIscendSectionHeader(
                    eyebrow: eyebrow,
                    title: title,
                    subtitle: subtitle,
                    prominence: .hero
                )

                content
            }
            .padding(AIscendTheme.Spacing.xLarge)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.borderStrong,
                            accent.tint.opacity(0.26),
                            AIscendTheme.Colors.borderSubtle
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: AIscendTheme.Stroke.thin
                )
        )
        .shadow(color: Color.black.opacity(0.42), radius: 26, x: 0, y: 18)
        .shadow(color: accent.glow.opacity(0.52), radius: 30, x: 0, y: 0)
    }
}

struct AIscendPreferenceCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let symbol: String
    var accent: RoutineAccent = .sky
    private let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        symbol: String,
        accent: RoutineAccent = .sky,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
                AIscendIconOrb(symbol: symbol, accent: accent, size: 42)

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text(title)
                        .aiscendTextStyle(.cardTitle)

                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    }
                }
            }

            content
        }
        .padding(AIscendTheme.Spacing.large)
        .aiscendPanel(.muted)
    }
}

extension View {
    func aiscendPanel(_ style: AIscendPanelStyle = .standard) -> some View {
        modifier(AIscendPanelModifier(style: style))
    }

    func aiscendCard(highlighted: Bool = false) -> some View {
        aiscendPanel(highlighted ? .hero : .standard)
    }

    func aiscendInputField(isFocused: Bool = false) -> some View {
        modifier(AIscendInputModifier(isFocused: isFocused))
    }
}
