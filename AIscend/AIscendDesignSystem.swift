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
                    AIscendTheme.Colors.surface,
                    AIscendTheme.Colors.cardGradientEnd.opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .elevated:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.elevatedSurface,
                    AIscendTheme.Colors.cardGradientStart
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .hero:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.cardGradientStart,
                    AIscendTheme.Colors.cardGradientEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .muted:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.tertiaryBackground.opacity(0.96),
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
                    AIscendTheme.Colors.accentGlow.opacity(0.30),
                    AIscendTheme.Colors.borderSubtle
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
            AIscendTheme.Shadow.accent
        case .elevated:
            AIscendTheme.Colors.accentDeep.opacity(0.12)
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
            26
        case .elevated:
            20
        default:
            14
        }
    }

    var shadowYOffset: CGFloat {
        switch self {
        case .hero:
            16
        case .elevated:
            12
        default:
            8
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
                    AIscendTheme.Colors.accentSoft,
                    AIscendTheme.Colors.accentPrimary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.tertiaryBackground.opacity(0.95),
                    AIscendTheme.Colors.secondaryBackground.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .ghost:
            LinearGradient(
                colors: [.clear, .clear],
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
            AIscendTheme.Colors.accentGlow.opacity(0.44)
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
            AIscendTheme.Colors.accentPrimary.opacity(0.30)
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
            AIscendTheme.Colors.accentPrimary.opacity(0.20)
        case .neutral:
            AIscendTheme.Colors.surfaceHighlight.opacity(0.85)
        case .subtle:
            AIscendTheme.Colors.secondaryBackground.opacity(0.9)
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
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.surfaceHighlight,
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .opacity(style == .muted ? 0.45 : 0.9)

            if style == .hero {
                shape
                    .fill(
                        RadialGradient(
                            colors: [
                                AIscendTheme.Colors.accentGlow.opacity(0.18),
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
            .frame(minHeight: 54)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                    .fill(variant.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                    .stroke(variant.border, lineWidth: AIscendTheme.Stroke.thin)
            )
            .shadow(color: variant.glow, radius: 18, x: 0, y: 0)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .scaleEffect(configuration.isPressed ? 0.988 : 1)
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

            Spacer(minLength: 0)

            if let trailingSymbol {
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
                .aiscendTextStyle(prominence == .hero ? .screenTitle : .sectionTitle)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .aiscendTextStyle(.body)
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
                .textCase(.uppercase)
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, AIscendTheme.Spacing.xSmall)
        .background(
            Capsule(style: .continuous)
                .fill(style.fill)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(style.border, lineWidth: AIscendTheme.Stroke.thin)
        )
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
                .opacity(0.20)
                .background(
                    Circle()
                        .fill(accent.gradient)
                        .blur(radius: 18)
                        .opacity(0.28)
                )

            Circle()
                .stroke(accent.tint.opacity(0.42), lineWidth: AIscendTheme.Stroke.thin)

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
                    .aiscendTextStyle(.cardTitle)

                Text(detail)
                    .aiscendTextStyle(.secondaryBody)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 176, alignment: .topLeading)
        .padding(AIscendTheme.Spacing.mediumLarge)
        .aiscendPanel(highlighted ? .hero : .standard)
    }
}

struct AIscendLoadingIndicator: View {
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
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                    .fill(AIscendTheme.Colors.fieldFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
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
