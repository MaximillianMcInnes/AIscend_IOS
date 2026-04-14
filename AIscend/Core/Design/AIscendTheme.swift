//
//  AIscendTheme.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import SwiftUI
import UIKit

enum AIscendTheme {
    enum Colors {
        static let appBackground = Color(hex: "0D0F14")
        static let secondaryBackground = Color(hex: "12131D")
        static let tertiaryBackground = Color(hex: "161822")
        static let surface = Color(hex: "151922").opacity(0.94)
        static let surfaceGlass = Color(hex: "1B2030").opacity(0.74)
        static let elevatedSurface = Color(hex: "1A1F2A").opacity(0.98)
        static let surfaceInteractive = Color(hex: "202536").opacity(0.92)
        static let surfaceMuted = Color(hex: "111522").opacity(0.90)
        static let surfaceHighlight = Color.white.opacity(0.075)
        static let surfaceGloss = Color.white.opacity(0.12)
        static let borderSubtle = Color.white.opacity(0.08)
        static let borderStrong = Color.white.opacity(0.18)
        static let textPrimary = Color(hex: "F7F4FF")
        static let textSecondary = Color(hex: "C3BBD8")
        static let textMuted = Color(hex: "8E88A7")
        static let accentPrimary = Color(hex: "7C3AED")
        static let accentSoft = Color(hex: "9462FF")
        static let accentDeep = Color(hex: "4D2A92")
        static let accentGlow = Color(hex: "B596FF")
        static let accentMint = Color(hex: "73E0D0")
        static let accentAmber = Color(hex: "F0B56B")
        static let accentCyan = Color(hex: "75B9FF")
        static let success = Color(hex: "58D7A1")
        static let warning = accentAmber
        static let error = Color(hex: "EF6A8A")
        static let overlayDark = Color.black.opacity(0.52)
        static let cardGradientStart = Color(hex: "1A1D2B")
        static let cardGradientEnd = Color(hex: "111320")
        static let fieldFill = Color(hex: "111623").opacity(0.98)
        static let divider = Color.white.opacity(0.08)
        static let iconSoft = Color.white.opacity(0.82)
        static let mediaScrimTop = Color.black.opacity(0.14)
        static let mediaScrimBottom = Color.black.opacity(0.62)
        static let heroAura = accentGlow.opacity(0.22)
    }

    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let mediumLarge: CGFloat = 20
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 40
        static let screenInset: CGFloat = 24
    }

    enum Radius {
        static let small: CGFloat = 14
        static let medium: CGFloat = 20
        static let large: CGFloat = 28
        static let extraLarge: CGFloat = 34
        static let pill: CGFloat = 999
    }

    enum Stroke {
        static let thin: CGFloat = 1
        static let emphasis: CGFloat = 1.25
    }

    enum Shadow {
        static let subtle = Color.black.opacity(0.24)
        static let ambient = Color.black.opacity(0.40)
        static let card = Color.black.opacity(0.46)
        static let accent = Colors.accentPrimary.opacity(0.22)
        static let focus = Colors.accentGlow.opacity(0.28)
        static let modal = Color.black.opacity(0.56)
    }

    enum Typography {
        static let heroTitle = Font.system(size: 46, weight: .bold, design: .default)
        static let screenTitle = Font.system(size: 34, weight: .bold, design: .default)
        static let sectionTitle = Font.system(size: 24, weight: .bold, design: .default)
        static let cardTitle = Font.system(size: 19, weight: .semibold, design: .default)
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let secondaryBody = Font.system(size: 14, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .medium, design: .default)
        static let metric = Font.system(size: 38, weight: .bold, design: .default)
        static let metricCompact = Font.system(size: 28, weight: .bold, design: .default)
        static let smallLabel = Font.system(size: 12, weight: .semibold, design: .default)
        static let buttonLabel = Font.system(size: 15, weight: .semibold, design: .default)
        static let input = Font.system(size: 16, weight: .medium, design: .default)
    }

    enum Motion {
        static let soft = Animation.easeInOut(duration: 0.28)
        static let reveal = Animation.spring(response: 0.48, dampingFraction: 0.88)
        static let press = Animation.easeOut(duration: 0.16)
    }

    enum Layout {
        static let floatingTabBarClearance: CGFloat = 118
    }

    static func configureSystemAppearance() {
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithTransparentBackground()
        navigationAppearance.backgroundColor = UIColor(Colors.appBackground).withAlphaComponent(0.68)
        navigationAppearance.shadowColor = .clear
        navigationAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Colors.textPrimary),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navigationAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Colors.textPrimary),
            .font: UIFont.systemFont(ofSize: 36, weight: .bold)
        ]

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().tintColor = UIColor(Colors.textPrimary)

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = UIColor.clear
        tabBarAppearance.shadowColor = .clear

        let stacked = tabBarAppearance.stackedLayoutAppearance
        stacked.normal.iconColor = UIColor(Colors.textMuted)
        stacked.normal.titleTextAttributes = [.foregroundColor: UIColor(Colors.textMuted)]
        stacked.selected.iconColor = UIColor(Colors.accentGlow)
        stacked.selected.titleTextAttributes = [.foregroundColor: UIColor(Colors.textPrimary)]

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = UIColor(Colors.accentGlow)

        UITextField.appearance().tintColor = UIColor(Colors.accentSoft)
    }
}

enum AIscendTextStyle {
    case eyebrow
    case heroTitle
    case screenTitle
    case sectionTitle
    case cardTitle
    case body
    case secondaryBody
    case caption
    case metric
    case metricCompact
    case buttonLabel

    var font: Font {
        switch self {
        case .eyebrow:
            AIscendTheme.Typography.smallLabel
        case .heroTitle:
            AIscendTheme.Typography.heroTitle
        case .screenTitle:
            AIscendTheme.Typography.screenTitle
        case .sectionTitle:
            AIscendTheme.Typography.sectionTitle
        case .cardTitle:
            AIscendTheme.Typography.cardTitle
        case .body:
            AIscendTheme.Typography.body
        case .secondaryBody:
            AIscendTheme.Typography.secondaryBody
        case .caption:
            AIscendTheme.Typography.caption
        case .metric:
            AIscendTheme.Typography.metric
        case .metricCompact:
            AIscendTheme.Typography.metricCompact
        case .buttonLabel:
            AIscendTheme.Typography.buttonLabel
        }
    }

    var tracking: CGFloat {
        switch self {
        case .eyebrow:
            1.6
        case .caption:
            0.18
        default:
            0
        }
    }

    var defaultColor: Color {
        switch self {
        case .eyebrow:
            AIscendTheme.Colors.textMuted
        case .heroTitle, .screenTitle, .sectionTitle, .cardTitle, .metric, .metricCompact, .buttonLabel:
            AIscendTheme.Colors.textPrimary
        case .body:
            AIscendTheme.Colors.textSecondary
        case .secondaryBody, .caption:
            AIscendTheme.Colors.textMuted
        }
    }

    var usesMonospacedDigits: Bool {
        switch self {
        case .metric, .metricCompact:
            true
        default:
            false
        }
    }
}

extension RoutineAccent {
    var tint: Color {
        switch self {
        case .dawn:
            AIscendTheme.Colors.accentAmber
        case .sky:
            AIscendTheme.Colors.accentPrimary
        case .mint:
            AIscendTheme.Colors.accentCyan
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .dawn:
            LinearGradient(
                colors: [AIscendTheme.Colors.accentAmber, AIscendTheme.Colors.accentSoft],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sky:
            LinearGradient(
                colors: [AIscendTheme.Colors.accentPrimary, AIscendTheme.Colors.accentDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .mint:
            LinearGradient(
                colors: [AIscendTheme.Colors.accentCyan, AIscendTheme.Colors.accentMint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var glow: Color {
        tint.opacity(0.28)
    }
}

struct AIscendBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AIscendTheme.Colors.appBackground,
                    AIscendTheme.Colors.secondaryBackground,
                    AIscendTheme.Colors.appBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentGlow.opacity(0.32),
                    AIscendTheme.Colors.accentPrimary.opacity(0.14),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 420
            )
            .offset(x: 140, y: -160)

            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentCyan.opacity(0.13),
                    .clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 260
            )
            .offset(x: -160, y: -140)

            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentMint.opacity(0.16),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 300
            )
            .offset(x: -180, y: 280)

            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentSoft.opacity(0.10),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 280
            )
            .offset(x: 160, y: 260)

            LinearGradient(
                colors: [
                    .clear,
                    AIscendTheme.Colors.overlayDark.opacity(0.25),
                    AIscendTheme.Colors.overlayDark.opacity(0.62)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.025),
                            .clear,
                            AIscendTheme.Colors.accentGlow.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.screen)

            Rectangle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.03),
                            .clear,
                            AIscendTheme.Colors.accentGlow.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .blendMode(.screen)
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}

private struct AIscendTextStyleModifier: ViewModifier {
    let style: AIscendTextStyle
    let color: Color?

    @ViewBuilder
    func body(content: Content) -> some View {
        let resolvedColor = color ?? style.defaultColor
        let base = content
            .font(style.font)
            .foregroundStyle(resolvedColor)
            .tracking(style.tracking)

        if style.usesMonospacedDigits {
            base.monospacedDigit()
        } else {
            base
        }
    }
}

private struct AIscendNavigationChromeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(AIscendTheme.Colors.appBackground.opacity(0.66), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

extension View {
    func aiscendTextStyle(_ style: AIscendTextStyle, color: Color? = nil) -> some View {
        modifier(AIscendTextStyleModifier(style: style, color: color))
    }

    func aiscendNavigationChrome() -> some View {
        modifier(AIscendNavigationChromeModifier())
    }
}

extension Color {
    init(hex: String, opacity: Double = 1) {
        let cleaned = hex
            .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red, green, blue: UInt64
        switch cleaned.count {
        case 3:
            (red, green, blue) = (
                ((value >> 8) & 0xF) * 17,
                ((value >> 4) & 0xF) * 17,
                (value & 0xF) * 17
            )
        default:
            (red, green, blue) = (
                (value >> 16) & 0xFF,
                (value >> 8) & 0xFF,
                value & 0xFF
            )
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: opacity
        )
    }
}
