//
//  AIscendPremiumOnboardingComponents.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Combine
import Foundation
import SwiftUI

private enum PremiumPlanStepStatus {
    case complete
    case active
    case pending
}

private enum PremiumMockStrategyState {
    case complete
    case active
}

enum PremiumOnboardingPalette {
    static let background = Color(hex: "0C0A09")
    static let backgroundSecondary = Color(hex: "16110F")
    static let surface = Color(hex: "1B1613").opacity(0.86)
    static let surfaceStrong = Color(hex: "211A16").opacity(0.96)
    static let border = Color.white.opacity(0.08)
    static let borderStrong = Color(hex: "E4C98A").opacity(0.26)
    static let gold = Color(hex: "CA8A04")
    static let goldSoft = Color(hex: "E4C98A")
    static let goldDeep = Color(hex: "7A5200")
    static let amberGlow = Color(hex: "F5D37A").opacity(0.28)
    static let red = Color(hex: "A34B45")
    static let textPrimary = Color(hex: "F8F4ED")
    static let textSecondary = Color(hex: "CBBCA6")
    static let textMuted = Color(hex: "8B7C69")

    static let ctaGradient = LinearGradient(
        colors: [Color(hex: "F0D089"), Color(hex: "CA8A04")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [Color(hex: "F8E3B0"), Color(hex: "D4A84B"), Color(hex: "8A5B0D")],
        startPoint: .leading,
        endPoint: .trailing
    )
}

struct PremiumOnboardingAtmosphere: View {
    let stage: PremiumOnboardingStage

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    PremiumOnboardingPalette.background,
                    PremiumOnboardingPalette.backgroundSecondary,
                    PremiumOnboardingPalette.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [PremiumOnboardingPalette.amberGlow, .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 340
            )
            .offset(x: 120, y: -140)

            RadialGradient(
                colors: [Color.white.opacity(0.06), .clear],
                center: .topLeading,
                startRadius: 8,
                endRadius: 220
            )
            .offset(x: -120, y: -180)

            RadialGradient(
                colors: [
                    (stage.chapter == .configure ? PremiumOnboardingPalette.gold : PremiumOnboardingPalette.goldSoft)
                        .opacity(stage == .splash ? 0.18 : 0.10),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 320
            )
            .offset(x: -140, y: 260)
        }
        .ignoresSafeArea()
    }
}

struct PremiumSplashBackdrop: View {
    var body: some View {
        PremiumOnboardingAtmosphere(stage: .splash)
    }
}

struct PremiumSplashIntro: View {
    @State private var visible = false
    @State private var pulse = false

    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.large) {
            ZStack {
                Circle()
                    .fill(PremiumOnboardingPalette.gold.opacity(0.18))
                    .frame(width: 220, height: 220)
                    .blur(radius: pulse ? 42 : 20)
                    .scaleEffect(pulse ? 1.08 : 0.94)

                Circle()
                    .stroke(PremiumOnboardingPalette.borderStrong, lineWidth: 1)
                    .frame(width: 176, height: 176)

                AIscendBrandMark(size: 120)
                    .scaleEffect(visible ? 1 : 0.92)
                    .opacity(visible ? 1 : 0)
            }

            VStack(spacing: AIscendTheme.Spacing.small) {
                Text("PRIVATE OPTIMISATION")
                    .aiscendTextStyle(.eyebrow, color: PremiumOnboardingPalette.goldSoft)
                    .opacity(visible ? 1 : 0)

                Text("Clarity before the first scan")
                    .aiscendTextStyle(.sectionTitle, color: PremiumOnboardingPalette.textPrimary)
                    .opacity(visible ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.85)) {
                visible = true
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct PremiumStageSection<Content: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String?
    private let content: Content

    init(eyebrow: String, title: String, subtitle: String?, @ViewBuilder content: () -> Content) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    Text(eyebrow.uppercased())
                        .aiscendTextStyle(.eyebrow, color: PremiumOnboardingPalette.goldSoft)
                        .padding(.horizontal, AIscendTheme.Spacing.small)
                        .padding(.vertical, AIscendTheme.Spacing.xSmall)
                        .background(
                            Capsule(style: .continuous)
                                .fill(PremiumOnboardingPalette.surfaceStrong)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(PremiumOnboardingPalette.borderStrong, lineWidth: 1)
                        )

                    Spacer(minLength: 0)
                }

                Text(title)
                    .aiscendTextStyle(.screenTitle, color: PremiumOnboardingPalette.textPrimary)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .aiscendTextStyle(.body, color: PremiumOnboardingPalette.textSecondary)
                }
            }

            content
        }
    }
}

struct PremiumOnboardingHeaderCard: View {
    let chapter: PremiumOnboardingChapter
    let stage: PremiumOnboardingStage
    let visibleIndex: Int
    let visibleCount: Int

    var body: some View {
        PremiumGlassCard(emphasis: true) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                        Text(chapter.title.uppercased())
                            .aiscendTextStyle(.eyebrow, color: PremiumOnboardingPalette.goldSoft)
                        Text(stage.label)
                            .aiscendTextStyle(.cardTitle, color: PremiumOnboardingPalette.textPrimary)
                    }

                    Spacer()

                    Text("\(visibleIndex) / \(visibleCount)")
                        .aiscendTextStyle(.caption, color: PremiumOnboardingPalette.textSecondary)
                        .padding(.horizontal, AIscendTheme.Spacing.small)
                        .padding(.vertical, AIscendTheme.Spacing.xSmall)
                        .background(
                            Capsule(style: .continuous)
                                .fill(PremiumOnboardingPalette.surfaceStrong)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(PremiumOnboardingPalette.border, lineWidth: 1)
                        )
                }

                Text(chapter.detail)
                    .aiscendTextStyle(.caption, color: PremiumOnboardingPalette.textSecondary)

                HStack(spacing: AIscendTheme.Spacing.xSmall) {
                    ForEach(PremiumOnboardingChapter.allCases, id: \.rawValue) { item in
                        Capsule(style: .continuous)
                            .fill(
                                item.rawValue < chapter.rawValue
                                ? AnyShapeStyle(PremiumOnboardingPalette.accentGradient)
                                : item == chapter
                                    ? AnyShapeStyle(PremiumOnboardingPalette.gold.opacity(0.78))
                                    : AnyShapeStyle(PremiumOnboardingPalette.surfaceStrong)
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: item == chapter ? 8 : 6)
                    }
                }
            }
        }
    }
}

struct PremiumOnboardingActionDock: View {
    let title: String
    let detail: String
    let buttonTitle: String
    let buttonSymbol: String
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        PremiumGlassCard(emphasis: true) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text(title)
                        .aiscendTextStyle(.cardTitle, color: PremiumOnboardingPalette.textPrimary)
                    Text(detail)
                        .aiscendTextStyle(.caption, color: disabled ? PremiumOnboardingPalette.goldSoft : PremiumOnboardingPalette.textSecondary)
                }

                Button(action: action) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        Text(buttonTitle)
                            .aiscendTextStyle(.buttonLabel, color: Color.black.opacity(0.92))
                        Spacer(minLength: 0)
                        Image(systemName: buttonSymbol)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.92))
                    }
                    .padding(.horizontal, AIscendTheme.Spacing.mediumLarge)
                    .padding(.vertical, AIscendTheme.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                            .fill(PremiumOnboardingPalette.ctaGradient)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                            .stroke(PremiumOnboardingPalette.goldSoft.opacity(0.44), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(disabled)
                .opacity(disabled ? 0.56 : 1)
            }
        }
    }
}

struct PremiumOnboardingNoteCard: View {
    let title: String
    let detail: String

    var body: some View {
        PremiumGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                Text(title)
                    .aiscendTextStyle(.cardTitle, color: PremiumOnboardingPalette.textPrimary)
                Text(detail)
                    .aiscendTextStyle(.body, color: PremiumOnboardingPalette.textSecondary)
            }
        }
    }
}

struct PremiumOnboardingSelectionSummary: View {
    let summary: String
    let hasSelection: Bool

    var body: some View {
        PremiumGlassCard(emphasis: hasSelection) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                Text(hasSelection ? "Selected priorities" : "Select at least one priority")
                    .aiscendTextStyle(.cardTitle, color: PremiumOnboardingPalette.textPrimary)
                Text(hasSelection ? summary : "Your selections shape the tone of the first strategy.")
                    .aiscendTextStyle(.body, color: PremiumOnboardingPalette.textSecondary)
            }
        }
    }
}

struct PremiumGlassCard<Content: View>: View {
    let emphasis: Bool
    let minHeight: CGFloat?
    private let content: Content

    init(emphasis: Bool = false, minHeight: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.emphasis = emphasis
        self.minHeight = minHeight
        self.content = content()
    }

    var body: some View {
        Group {
            if let minHeight {
                base.frame(minHeight: minHeight, alignment: .topLeading)
            } else {
                base
            }
        }
    }

    private var base: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AIscendTheme.Spacing.xLarge)
            .background(cardBackground)
            .clipShape(shape)
            .overlay(shape.stroke(border, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.34), radius: 26, x: 0, y: 18)
            .shadow(color: emphasis ? PremiumOnboardingPalette.amberGlow : .clear, radius: 32, x: 0, y: 0)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
    }

    private var border: LinearGradient {
        LinearGradient(
            colors: [
                PremiumOnboardingPalette.borderStrong,
                emphasis ? PremiumOnboardingPalette.goldSoft.opacity(0.32) : PremiumOnboardingPalette.border,
                PremiumOnboardingPalette.border
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardBackground: some View {
        ZStack {
            shape.fill(PremiumOnboardingPalette.surface)
            shape.fill(.ultraThinMaterial).opacity(0.12)
            shape.fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
                        .clear,
                        PremiumOnboardingPalette.gold.opacity(emphasis ? 0.10 : 0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            if emphasis {
                Circle()
                    .fill(PremiumOnboardingPalette.gold.opacity(0.18))
                    .frame(width: 200, height: 200)
                    .blur(radius: 28)
                    .offset(x: 72, y: -84)
            }
        }
    }
}

struct PremiumCarouselDeck: View {
    let slides: [OnboardingSlide]
    @State private var index = 0
    private let timer = Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            TabView(selection: $index) {
                ForEach(Array(slides.enumerated()), id: \.element.id) { position, slide in
                    PremiumGlassCard(emphasis: true, minHeight: 560) {
                        HStack {
                            Text(String(format: "%02d / %02d", position + 1, slides.count))
                                .aiscendTextStyle(.caption, color: PremiumOnboardingPalette.goldSoft)
                            Spacer()
                            Text(slide.eyebrow.uppercased())
                                .aiscendTextStyle(.caption, color: PremiumOnboardingPalette.textSecondary)
                        }
                        Text(slide.title)
                            .aiscendTextStyle(.screenTitle, color: PremiumOnboardingPalette.textPrimary)
                        Text(slide.copy)
                            .aiscendTextStyle(.body, color: PremiumOnboardingPalette.textSecondary)
                        PremiumPhoneMockup(slide: slide).frame(maxWidth: .infinity)
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: AIscendTheme.Spacing.small) {
                                ForEach(slide.chips, id: \.self) { chip in
                                    PremiumStoryChip(title: chip)
                                }
                            }
                            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                                ForEach(slide.chips, id: \.self) { chip in
                                    PremiumStoryChip(title: chip)
                                }
                            }
                        }
                    }
                    .tag(position)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 580)

            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                ForEach(0..<slides.count, id: \.self) { position in
                    Capsule(style: .continuous)
                        .fill(
                            position == index
                            ? AnyShapeStyle(PremiumOnboardingPalette.accentGradient)
                            : AnyShapeStyle(PremiumOnboardingPalette.surfaceStrong)
                        )
                        .frame(height: 5)
                }
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.45)) { index = (index + 1) % slides.count }
        }
    }
}

struct PremiumPhoneMockup: View {
    let slide: OnboardingSlide
    @State private var float = false

    var body: some View {
        ZStack {
            Circle()
                .fill(PremiumOnboardingPalette.gold.opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 24)
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(PremiumOnboardingPalette.background.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .stroke(PremiumOnboardingPalette.borderStrong, lineWidth: 1)
                )
                .frame(width: 260, height: 420)
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [PremiumOnboardingPalette.surfaceStrong, PremiumOnboardingPalette.background],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 238, height: 396)
                .overlay(mock.padding(.horizontal, AIscendTheme.Spacing.medium).padding(.vertical, AIscendTheme.Spacing.large))
        }
        .offset(y: float ? -10 : 8)
        .rotationEffect(.degrees(float ? -1.2 : 1.2))
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) { float = true }
        }
    }

    @ViewBuilder
    private var mock: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            Text("AIScend")
                .aiscendTextStyle(.cardTitle, color: PremiumOnboardingPalette.textPrimary)
            switch slide.kind {
            case .analysis:
                PremiumPortraitGlyph(emphasis: 1).frame(maxWidth: .infinity)
                metric("Structure", "Strong")
                metric("Symmetry", "Tracked")
                metric("Profile", "Mapped")
            case .metrics:
                trend("Jaw definition", 0.82)
                trend("Eye support", 0.66)
                trend("Skin clarity", 0.58)
                PremiumOutcomeGraph(compact: true).frame(height: 110)
            case .strategy:
                strategy("1. Improve jaw support", .complete)
                strategy("2. Tighten skin routine", .complete)
                strategy("3. Upgrade framing", .active)
                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).aiscendTextStyle(.caption, color: PremiumOnboardingPalette.textSecondary)
            Spacer()
            Text(value).aiscendTextStyle(.caption, color: PremiumOnboardingPalette.textPrimary)
        }
        .padding(.vertical, AIscendTheme.Spacing.xSmall)
        .overlay(alignment: .bottom) { Rectangle().fill(PremiumOnboardingPalette.border).frame(height: 1) }
    }

    private func trend(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            HStack {
                Text(title).aiscendTextStyle(.caption, color: PremiumOnboardingPalette.textSecondary)
                Spacer()
                Text("\(Int(value * 100))%").aiscendTextStyle(.caption, color: PremiumOnboardingPalette.textPrimary)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(PremiumOnboardingPalette.surfaceStrong)
                    Capsule().fill(PremiumOnboardingPalette.accentGradient).frame(width: proxy.size.width * value)
                }
            }
            .frame(height: 8)
        }
    }

    private func strategy(_ title: String, _ state: PremiumMockStrategyState) -> some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: state == .complete ? "checkmark.circle.fill" : "hourglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(state == .complete ? PremiumOnboardingPalette.goldSoft : PremiumOnboardingPalette.textSecondary)
            Text(title).aiscendTextStyle(.caption, color: PremiumOnboardingPalette.textSecondary)
        }
    }
}

struct PremiumStoryChip: View {
    let title: String

    var body: some View {
        Text(title)
            .aiscendTextStyle(.caption, color: PremiumOnboardingPalette.textPrimary)
            .padding(.horizontal, AIscendTheme.Spacing.small)
            .padding(.vertical, AIscendTheme.Spacing.xSmall)
            .background(
                Capsule(style: .continuous)
                    .fill(PremiumOnboardingPalette.surfaceStrong)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(PremiumOnboardingPalette.border, lineWidth: 1)
            )
    }
}

struct PremiumMetaPill: View {
    let title: String
    var symbol: String? = nil
    var highlighted: Bool = false
    var tone: Color = PremiumOnboardingPalette.goldSoft

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .semibold))
            }

            Text(title)
                .aiscendTextStyle(
                    .caption,
                    color: highlighted ? PremiumOnboardingPalette.textPrimary : PremiumOnboardingPalette.textSecondary
                )
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, AIscendTheme.Spacing.xSmall)
        .background(
            Capsule(style: .continuous)
                .fill(highlighted ? tone.opacity(0.16) : PremiumOnboardingPalette.surfaceStrong)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(highlighted ? tone.opacity(0.42) : PremiumOnboardingPalette.border, lineWidth: 1)
        )
    }
}

struct PremiumSymbolOrb: View {
    let symbol: String
    var highlighted: Bool = false
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            Circle()
                .fill((highlighted ? PremiumOnboardingPalette.gold : Color.white).opacity(highlighted ? 0.18 : 0.06))
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill((highlighted ? PremiumOnboardingPalette.goldSoft : Color.white).opacity(highlighted ? 0.16 : 0.04))
                        .blur(radius: 18)
                )

            Circle()
                .stroke(
                    highlighted ? PremiumOnboardingPalette.borderStrong : PremiumOnboardingPalette.border,
                    lineWidth: 1
                )
                .frame(width: size, height: size)

            Image(systemName: symbol)
                .font(.system(size: size * 0.34, weight: .semibold))
                .foregroundStyle(highlighted ? PremiumOnboardingPalette.goldSoft : PremiumOnboardingPalette.textPrimary)
        }
        .frame(width: size, height: size)
    }
}

struct PremiumProjectionCard: View {
    var body: some View {
        PremiumGlassCard(emphasis: true) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    Text("Projected direction")
                        .aiscendTextStyle(.cardTitle, color: PremiumOnboardingPalette.textPrimary)
                    Text("Good capture discipline and consistent follow-through create a meaningfully stronger curve.")
                        .aiscendTextStyle(.body, color: PremiumOnboardingPalette.textSecondary)
                }

                HStack(spacing: AIscendTheme.Spacing.small) {
                    legend("Stalled habits", PremiumOnboardingPalette.red)
                    legend("Optimised path", PremiumOnboardingPalette.goldSoft)
                }

                PremiumOutcomeGraph(compact: false)
                    .frame(height: 260)

                HStack {
                    Text("Starting point")
                        .aiscendTextStyle(.caption, color: PremiumOnboardingPalette.textMuted)
                    Spacer()
                    Text("Compounded outcome")
                        .aiscendTextStyle(.caption, color: PremiumOnboardingPalette.textSecondary)
                }
            }
        }
    }

    private func legend(_ label: String, _ color: Color) -> some View {
        PremiumMetaPill(title: label, symbol: "circle.fill", highlighted: true, tone: color)
    }
}

struct PremiumOutcomeGraph: View {
    let compact: Bool
    @State private var reveal: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                PremiumGraphGrid()
                    .stroke(PremiumOnboardingPalette.border.opacity(0.65), lineWidth: 1)
                PremiumGraphCurve(variant: .decline)
                    .trim(from: 0, to: reveal)
                    .stroke(
                        PremiumOnboardingPalette.red.opacity(0.92),
                        style: StrokeStyle(lineWidth: compact ? 3 : 4, lineCap: .round, lineJoin: .round)
                    )
                PremiumGraphCurve(variant: .optimised)
                    .trim(from: 0, to: reveal)
                    .stroke(
                        PremiumOnboardingPalette.accentGradient,
                        style: StrokeStyle(lineWidth: compact ? 3 : 4.5, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: PremiumOnboardingPalette.gold.opacity(0.24), radius: 16, x: 0, y: 0)
                if !compact {
                    Circle()
                        .fill(PremiumOnboardingPalette.goldSoft)
                        .frame(width: 10, height: 10)
                        .shadow(color: PremiumOnboardingPalette.gold.opacity(0.4), radius: 12, x: 0, y: 0)
                        .position(x: proxy.size.width * 0.92, y: proxy.size.height * 0.16)
                        .opacity(reveal)
                }
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 1.25)) { reveal = 1 } }
    }
}

struct PremiumGraphGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for column in 0...4 {
            let x = rect.width * CGFloat(column) / 4
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        for row in 0...4 {
            let y = rect.height * CGFloat(row) / 4
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return path
    }
}

struct PremiumGraphCurve: Shape {
    enum Variant { case decline, optimised }
    let variant: Variant

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.height * 0.78))
        switch variant {
        case .decline:
            path.addCurve(to: CGPoint(x: rect.width * 0.32, y: rect.height * 0.72), control1: CGPoint(x: rect.width * 0.08, y: rect.height * 0.76), control2: CGPoint(x: rect.width * 0.18, y: rect.height * 0.68))
            path.addCurve(to: CGPoint(x: rect.width * 0.66, y: rect.height * 0.76), control1: CGPoint(x: rect.width * 0.42, y: rect.height * 0.76), control2: CGPoint(x: rect.width * 0.56, y: rect.height * 0.81))
            path.addCurve(to: CGPoint(x: rect.width, y: rect.height * 0.88), control1: CGPoint(x: rect.width * 0.78, y: rect.height * 0.72), control2: CGPoint(x: rect.width * 0.9, y: rect.height * 0.86))
        case .optimised:
            path.addCurve(to: CGPoint(x: rect.width * 0.26, y: rect.height * 0.68), control1: CGPoint(x: rect.width * 0.06, y: rect.height * 0.77), control2: CGPoint(x: rect.width * 0.14, y: rect.height * 0.7))
            path.addCurve(to: CGPoint(x: rect.width * 0.58, y: rect.height * 0.46), control1: CGPoint(x: rect.width * 0.36, y: rect.height * 0.66), control2: CGPoint(x: rect.width * 0.44, y: rect.height * 0.5))
            path.addCurve(to: CGPoint(x: rect.width, y: rect.height * 0.16), control1: CGPoint(x: rect.width * 0.74, y: rect.height * 0.36), control2: CGPoint(x: rect.width * 0.86, y: rect.height * 0.22))
        }
        return path
    }
}

struct PremiumPlanCard: View {
    let progress: Double
    let steps: [String]
    let marker: Int

    var body: some View {
        PremiumGlassCard(emphasis: true) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                        Text("First routine calibration")
                            .aiscendTextStyle(.cardTitle, color: PremiumOnboardingPalette.textPrimary)
                        Text("We translate your goals into a calmer starting sequence instead of dropping you into a generic dashboard.")
                            .aiscendTextStyle(.body, color: PremiumOnboardingPalette.textSecondary)
                    }

                    Spacer(minLength: 0)
                    PremiumMetaPill(title: "Live", symbol: "waveform.path.ecg", highlighted: true)
                }

                PremiumPlanOrb()
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    PremiumLinearProgress(progress: progress)
                    Text("\(Int(progress * 100))% calibrated")
                        .aiscendTextStyle(.caption, color: PremiumOnboardingPalette.goldSoft)
                }

                VStack(spacing: AIscendTheme.Spacing.medium) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { offset, title in
                        row(title, status(for: offset))
                    }
                }
            }
        }
    }

    private func status(for index: Int) -> PremiumPlanStepStatus {
        if index < marker { return .complete }
        if index == marker { return .active }
        return .pending
    }

    private func row(_ title: String, _ status: PremiumPlanStepStatus) -> some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: status == .complete ? "checkmark.circle.fill" : status == .active ? "hourglass" : "circle.dashed")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(
                    status == .complete
                    ? PremiumOnboardingPalette.goldSoft
                    : status == .active
                        ? PremiumOnboardingPalette.textSecondary
                        : PremiumOnboardingPalette.textMuted
                )
            Text(title)
                .aiscendTextStyle(
                    .body,
                    color: status == .pending ? PremiumOnboardingPalette.textMuted : PremiumOnboardingPalette.textSecondary
                )
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(status == .active ? PremiumOnboardingPalette.gold.opacity(0.10) : PremiumOnboardingPalette.surfaceStrong)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(
                    status == .active ? PremiumOnboardingPalette.borderStrong : PremiumOnboardingPalette.border,
                    lineWidth: 1
                )
        )
    }
}

struct PremiumPlanOrb: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(PremiumOnboardingPalette.goldSoft.opacity(0.18 - Double(ring) * 0.03), lineWidth: 1)
                    .frame(width: 150 + CGFloat(ring) * 34, height: 150 + CGFloat(ring) * 34)
                    .scaleEffect(pulse ? 1.08 + CGFloat(ring) * 0.03 : 0.92)
                    .opacity(pulse ? 0.18 : 0.42)
            }
            Circle()
                .fill(PremiumOnboardingPalette.gold.opacity(0.14))
                .frame(width: 164, height: 164)
            Circle()
                .fill(PremiumOnboardingPalette.surfaceStrong)
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .stroke(PremiumOnboardingPalette.borderStrong, lineWidth: 1)
                )
            Image(systemName: "sparkles")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(PremiumOnboardingPalette.goldSoft)
        }
        .frame(height: 220)
        .onAppear { withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { pulse = true } }
    }
}

struct PremiumLinearProgress: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(PremiumOnboardingPalette.surfaceStrong)
                Capsule()
                    .fill(PremiumOnboardingPalette.accentGradient)
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 10)
    }
}

struct PremiumHaloCards: View {
    private let traits = ["Intelligent", "Kind", "Rich"]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AIscendTheme.Spacing.small) {
                card("Intentional presentation", "Sharper inputs create a stronger first read.", 1, PremiumOnboardingPalette.goldSoft)
                card("Low-effort presentation", "Noise weakens what people assume at a glance.", 0.32, PremiumOnboardingPalette.textMuted)
            }
            VStack(spacing: AIscendTheme.Spacing.small) {
                card("Intentional presentation", "Sharper inputs create a stronger first read.", 1, PremiumOnboardingPalette.goldSoft)
                card("Low-effort presentation", "Noise weakens what people assume at a glance.", 0.32, PremiumOnboardingPalette.textMuted)
            }
        }
    }

    private func card(_ title: String, _ subtitle: String, _ emphasis: Double, _ tint: Color) -> some View {
        PremiumGlassCard(emphasis: emphasis > 0.6, minHeight: 260) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                Text(title)
                    .aiscendTextStyle(.cardTitle, color: PremiumOnboardingPalette.textPrimary)
                Text(subtitle)
                    .aiscendTextStyle(.caption, color: PremiumOnboardingPalette.textSecondary)
                PremiumPortraitGlyph(emphasis: emphasis)
                    .frame(maxWidth: .infinity)
                HStack(spacing: AIscendTheme.Spacing.xSmall) {
                    ForEach(traits, id: \.self) { trait in
                        Text(trait)
                            .aiscendTextStyle(.caption, color: tint.opacity(0.55 + emphasis * 0.35))
                            .padding(.horizontal, AIscendTheme.Spacing.small)
                            .padding(.vertical, AIscendTheme.Spacing.xSmall)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(PremiumOnboardingPalette.surfaceStrong)
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(PremiumOnboardingPalette.border, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
}

struct PremiumPortraitGlyph: View {
    let emphasis: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(PremiumOnboardingPalette.gold.opacity(0.08 + emphasis * 0.10))
                .frame(width: 150, height: 150)
            Circle()
                .stroke(PremiumOnboardingPalette.borderStrong.opacity(0.7), lineWidth: 1)
                .frame(width: 150, height: 150)
            Path { path in
                path.move(to: CGPoint(x: 66, y: 24))
                path.addQuadCurve(to: CGPoint(x: 102, y: 78), control: CGPoint(x: 102, y: 38))
                path.addQuadCurve(to: CGPoint(x: 80, y: 118), control: CGPoint(x: 108, y: 104))
                path.addQuadCurve(to: CGPoint(x: 58, y: 118), control: CGPoint(x: 70, y: 130))
                path.addQuadCurve(to: CGPoint(x: 30, y: 78), control: CGPoint(x: 30, y: 104))
                path.addQuadCurve(to: CGPoint(x: 66, y: 24), control: CGPoint(x: 30, y: 38))
            }
            .stroke(
                PremiumOnboardingPalette.textPrimary.opacity(0.58 + emphasis * 0.24),
                style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
            )
            HStack(spacing: 22) {
                Circle()
                    .fill(PremiumOnboardingPalette.textPrimary.opacity(0.46 + emphasis * 0.24))
                    .frame(width: 6, height: 6)
                Circle()
                    .fill(PremiumOnboardingPalette.textPrimary.opacity(0.46 + emphasis * 0.24))
                    .frame(width: 6, height: 6)
            }
            .offset(y: -12)
            Capsule()
                .fill(PremiumOnboardingPalette.textPrimary.opacity(0.32 + emphasis * 0.22))
                .frame(width: 26, height: 3)
                .offset(y: 26)
            Rectangle()
                .fill(PremiumOnboardingPalette.goldSoft.opacity(emphasis * 0.32))
                .frame(width: 1, height: 88)
                .offset(y: 8)
        }
        .frame(width: 150, height: 150)
    }
}

struct PremiumImpactBars: View {
    let metrics: [OnboardingImpactMetric]

    var body: some View {
        PremiumGlassCard(emphasis: true) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                ForEach(Array(metrics.enumerated()), id: \.element.id) { offset, metric in
                    PremiumImpactBarRow(metric: metric, delay: Double(offset) * 0.08)
                }
            }
        }
    }
}

struct PremiumImpactBarRow: View {
    let metric: OnboardingImpactMetric
    let delay: Double
    @State private var reveal = false

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            HStack {
                Text(metric.title)
                    .aiscendTextStyle(.cardTitle, color: PremiumOnboardingPalette.textPrimary)
                Spacer()
                Text("\(Int(metric.value * 100))%")
                    .aiscendTextStyle(.caption, color: PremiumOnboardingPalette.goldSoft)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(PremiumOnboardingPalette.surfaceStrong)
                    Capsule()
                        .fill(PremiumOnboardingPalette.accentGradient)
                        .frame(width: proxy.size.width * metric.value * (reveal ? 1 : 0))
                }
            }
            .frame(height: 12)
        }
        .onAppear { withAnimation(.easeInOut(duration: 0.65).delay(delay)) { reveal = true } }
    }
}

struct PremiumNotificationCard: View {
    let state: PremiumNotificationState
    let isBusy: Bool

    var body: some View {
        PremiumGlassCard(emphasis: true) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(PremiumOnboardingPalette.gold.opacity(0.18))
                            .frame(width: 76, height: 76)
                        Circle()
                            .stroke(PremiumOnboardingPalette.borderStrong, lineWidth: 1)
                            .frame(width: 76, height: 76)
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(PremiumOnboardingPalette.goldSoft)
                    }

                    Spacer()
                    PremiumMetaPill(
                        title: isBusy ? "Requesting" : state.badgeTitle,
                        symbol: isBusy ? "hourglass" : "bell",
                        highlighted: true
                    )
                }

                Text("Quiet reminders keep the improvement loop alive.")
                    .aiscendTextStyle(.sectionTitle, color: PremiumOnboardingPalette.textPrimary)

                Text("The goal is presence, not pressure. A premium onboarding flow offers lightweight prompts that help habits stick.")
                    .aiscendTextStyle(.body, color: PremiumOnboardingPalette.textSecondary)

                HStack(spacing: AIscendTheme.Spacing.small) {
                    PremiumMetaPill(title: "Daily routine", symbol: "clock.fill")
                    PremiumMetaPill(title: "Progress tracking", symbol: "chart.line.uptrend.xyaxis")
                }
            }
        }
    }
}

struct PremiumAccuracyBlock: View {
    var body: some View {
        PremiumGlassCard(emphasis: true) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                Text("Signals that make the read trustworthy")
                    .aiscendTextStyle(.cardTitle, color: PremiumOnboardingPalette.textPrimary)
                Text("We explain the underlying signal sources so the user understands why better inputs lead to better outputs.")
                    .aiscendTextStyle(.body, color: PremiumOnboardingPalette.textSecondary)

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: AIscendTheme.Spacing.large) { PremiumLandmarkCard(); signals }
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) { PremiumLandmarkCard(); signals }
                }
            }
        }
    }

    private var signals: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            row("point.3.connected.trianglepath.dotted", "Uses facial landmark analysis")
            row("square.stack.3d.up.fill", "Trained on large datasets")
            row("arrow.triangle.2.circlepath", "Continuously improving")
        }
    }

    private func row(_ symbol: String, _ title: String) -> some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
            PremiumSymbolOrb(symbol: symbol, highlighted: true, size: 40)
            Text(title)
                .aiscendTextStyle(.body, color: PremiumOnboardingPalette.textSecondary)
                .padding(.top, AIscendTheme.Spacing.xSmall)
        }
    }
}

struct PremiumLandmarkCard: View {
    private let points: [CGPoint] = [
        CGPoint(x: 0.50, y: 0.12), CGPoint(x: 0.33, y: 0.24), CGPoint(x: 0.67, y: 0.24),
        CGPoint(x: 0.29, y: 0.42), CGPoint(x: 0.71, y: 0.42), CGPoint(x: 0.50, y: 0.46),
        CGPoint(x: 0.39, y: 0.63), CGPoint(x: 0.61, y: 0.63), CGPoint(x: 0.50, y: 0.78)
    ]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .fill(PremiumOnboardingPalette.surfaceStrong)
                .frame(width: 190, height: 220)
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .stroke(PremiumOnboardingPalette.borderStrong, lineWidth: 1)
                .frame(width: 190, height: 220)
            GeometryReader { proxy in
                ZStack {
                    Path { path in
                        path.move(to: point(points[0], proxy.size))
                        path.addLine(to: point(points[1], proxy.size))
                        path.addLine(to: point(points[3], proxy.size))
                        path.addLine(to: point(points[6], proxy.size))
                        path.addLine(to: point(points[8], proxy.size))
                        path.addLine(to: point(points[7], proxy.size))
                        path.addLine(to: point(points[4], proxy.size))
                        path.addLine(to: point(points[2], proxy.size))
                        path.closeSubpath()
                    }
                    .stroke(PremiumOnboardingPalette.goldSoft.opacity(0.7), lineWidth: 1.2)
                    Path { path in
                        path.move(to: point(points[1], proxy.size)); path.addLine(to: point(points[2], proxy.size))
                        path.move(to: point(points[3], proxy.size)); path.addLine(to: point(points[4], proxy.size))
                        path.move(to: point(points[1], proxy.size)); path.addLine(to: point(points[5], proxy.size)); path.addLine(to: point(points[8], proxy.size))
                        path.move(to: point(points[2], proxy.size)); path.addLine(to: point(points[5], proxy.size))
                    }
                    .stroke(PremiumOnboardingPalette.textSecondary.opacity(0.58), lineWidth: 1)
                    ForEach(Array(points.enumerated()), id: \.offset) { _, value in
                        Circle()
                            .fill(PremiumOnboardingPalette.goldSoft)
                            .frame(width: 7, height: 7)
                            .position(point(value, proxy.size))
                    }
                }
            }
            .frame(width: 190, height: 220)
        }
        .frame(width: 190, height: 220)
    }

    private func point(_ point: CGPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }
}

struct PremiumGoalsGrid: View {
    @Bindable var model: AppModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: AIscendTheme.Spacing.small), GridItem(.flexible(), spacing: AIscendTheme.Spacing.small)], spacing: AIscendTheme.Spacing.small) {
            ForEach(AnalysisGoal.allCases) { goal in
                let isSelected = model.analysisGoals.contains(goal)
                Button {
                    withAnimation(AIscendTheme.Motion.reveal) { model.toggleAnalysisGoal(goal) }
                } label: {
                    PremiumGlassCard(emphasis: isSelected, minHeight: 206) {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                            HStack(alignment: .top) {
                                PremiumSymbolOrb(symbol: goal.symbol, highlighted: isSelected)
                                Spacer()
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 21, weight: .semibold))
                                    .foregroundStyle(
                                        isSelected
                                        ? PremiumOnboardingPalette.goldSoft
                                        : PremiumOnboardingPalette.textMuted
                                    )
                            }

                            Text(goal.title)
                                .aiscendTextStyle(.cardTitle, color: PremiumOnboardingPalette.textPrimary)

                            Text(goal.subtitle)
                                .aiscendTextStyle(.secondaryBody, color: PremiumOnboardingPalette.textSecondary)

                            if isSelected {
                                PremiumMetaPill(title: "Priority selected", symbol: "sparkles", highlighted: true)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct PremiumNameCard: View {
    @Binding var name: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        PremiumGlassCard(emphasis: true) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack {
                    AIscendBrandMark(size: 52, showsWordmark: false)
                    Spacer()
                    if !trimmed.isEmpty {
                        PremiumMetaPill(title: "Personalised", symbol: "sparkles", highlighted: true)
                    }
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    Text("Who should we build this for?")
                        .aiscendTextStyle(.cardTitle, color: PremiumOnboardingPalette.textPrimary)
                    Text("Using your name makes the first plan feel like a workspace instead of a cold setup screen.")
                        .aiscendTextStyle(.body, color: PremiumOnboardingPalette.textSecondary)
                }

                TextField("", text: $name, prompt: Text("Your name").foregroundStyle(PremiumOnboardingPalette.textMuted))
                    .focused($isFocused)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .font(AIscendTheme.Typography.input)
                    .foregroundStyle(PremiumOnboardingPalette.textPrimary)
                    .padding(.horizontal, AIscendTheme.Spacing.medium)
                    .padding(.vertical, AIscendTheme.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                            .fill(PremiumOnboardingPalette.surfaceStrong)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                            .stroke(
                                isFocused ? PremiumOnboardingPalette.borderStrong : PremiumOnboardingPalette.border,
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isFocused ? PremiumOnboardingPalette.amberGlow : .clear,
                        radius: isFocused ? 18 : 0,
                        x: 0,
                        y: 0
                    )
                    .tint(PremiumOnboardingPalette.goldSoft)

                Text(trimmed.isEmpty ? "You can change this later." : "Your plan will be addressed to \(trimmed).")
                    .aiscendTextStyle(.body, color: PremiumOnboardingPalette.textSecondary)
            }
        }
    }

    private var trimmed: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
