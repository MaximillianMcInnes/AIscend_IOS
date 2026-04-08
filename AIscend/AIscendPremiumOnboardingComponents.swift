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
    case complete, active, pending
}

private enum PremiumMockStrategyState {
    case complete, active
}

struct PremiumSplashBackdrop: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(colors: [AIscendTheme.Colors.accentPrimary.opacity(0.34), .clear], center: .center, startRadius: 12, endRadius: 280)
            RadialGradient(colors: [AIscendTheme.Colors.accentGlow.opacity(0.16), .clear], center: .center, startRadius: 12, endRadius: 360)
        }
    }
}

struct PremiumSplashIntro: View {
    @State private var visible = false
    @State private var pulse = false

    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.large) {
            ZStack {
                Circle()
                    .fill(AIscendTheme.Colors.accentPrimary.opacity(0.18))
                    .frame(width: 200, height: 200)
                    .blur(radius: pulse ? 34 : 18)
                    .scaleEffect(pulse ? 1.08 : 0.94)

                AIscendBrandMark(size: 120)
                    .scaleEffect(visible ? 1 : 0.92)
                    .opacity(visible ? 1 : 0)
            }

            Text("PRIVATE OPTIMISATION")
                .aiscendTextStyle(.eyebrow, color: AIscendTheme.Colors.accentGlow)
                .opacity(visible ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.85)) { visible = true }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { pulse = true }
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
            AIscendSectionHeader(eyebrow: eyebrow, title: title, subtitle: subtitle, prominence: .hero)
            content
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
            .shadow(color: AIscendTheme.Shadow.card, radius: 24, x: 0, y: 16)
            .shadow(color: emphasis ? AIscendTheme.Colors.accentPrimary.opacity(0.18) : .clear, radius: 28, x: 0, y: 0)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
    }

    private var border: LinearGradient {
        LinearGradient(
            colors: [
                AIscendTheme.Colors.borderStrong,
                emphasis ? AIscendTheme.Colors.accentGlow.opacity(0.36) : AIscendTheme.Colors.borderSubtle,
                AIscendTheme.Colors.borderSubtle
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardBackground: some View {
        ZStack {
            shape.fill(AIscendTheme.Colors.secondaryBackground.opacity(0.78))
            shape.fill(.ultraThinMaterial).opacity(0.16)
            shape.fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.05), .clear, AIscendTheme.Colors.accentGlow.opacity(emphasis ? 0.08 : 0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            if emphasis {
                Circle()
                    .fill(AIscendTheme.Colors.accentGlow.opacity(0.18))
                    .frame(width: 180, height: 180)
                    .blur(radius: 24)
                    .offset(x: 60, y: -80)
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
                        Text(String(format: "%02d / %02d", position + 1, slides.count))
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                        Text(slide.title).aiscendTextStyle(.screenTitle)
                        Text(slide.copy).aiscendTextStyle(.body)
                        PremiumPhoneMockup(slide: slide).frame(maxWidth: .infinity)
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: AIscendTheme.Spacing.small) {
                                ForEach(slide.chips, id: \.self) { AIscendBadge(title: $0, style: .neutral) }
                            }
                            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                                ForEach(slide.chips, id: \.self) { AIscendBadge(title: $0, style: .neutral) }
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
                        .fill(position == index ? AnyShapeStyle(RoutineAccent.sky.gradient) : AnyShapeStyle(AIscendTheme.Colors.surfaceHighlight))
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
            Circle().fill(AIscendTheme.Colors.accentGlow.opacity(0.18)).frame(width: 280, height: 280).blur(radius: 24)
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.black.opacity(0.9))
                .overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1))
                .frame(width: 260, height: 420)
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AIscendTheme.Colors.secondaryBackground, AIscendTheme.Colors.appBackground],
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
            Text("AIScend").aiscendTextStyle(.cardTitle)
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
            Text(title).aiscendTextStyle(.caption)
            Spacer()
            Text(value).aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
        }
        .padding(.vertical, AIscendTheme.Spacing.xSmall)
        .overlay(alignment: .bottom) { Rectangle().fill(AIscendTheme.Colors.divider).frame(height: 1) }
    }

    private func trend(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
            HStack {
                Text(title).aiscendTextStyle(.caption)
                Spacer()
                Text("\(Int(value * 100))%").aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AIscendTheme.Colors.surfaceHighlight)
                    Capsule().fill(RoutineAccent.sky.gradient).frame(width: proxy.size.width * value)
                }
            }
            .frame(height: 8)
        }
    }

    private func strategy(_ title: String, _ state: PremiumMockStrategyState) -> some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: state == .complete ? "checkmark.circle.fill" : "hourglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(state == .complete ? AIscendTheme.Colors.accentGlow : AIscendTheme.Colors.textSecondary)
            Text(title).aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
        }
    }
}

struct PremiumProjectionCard: View {
    var body: some View {
        PremiumGlassCard(emphasis: true) {
            HStack(spacing: AIscendTheme.Spacing.mediumLarge) {
                legend("Bad habits", AIscendTheme.Colors.error)
                legend("Optimised habits", AIscendTheme.Colors.accentGlow)
            }
            PremiumOutcomeGraph(compact: false).frame(height: 260)
            HStack {
                Text("Now").aiscendTextStyle(.caption)
                Spacer()
                Text("Future").aiscendTextStyle(.caption)
            }
        }
    }

    private func legend(_ label: String, _ color: Color) -> some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).aiscendTextStyle(.caption)
        }
    }
}

struct PremiumOutcomeGraph: View {
    let compact: Bool
    @State private var reveal: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                PremiumGraphGrid().stroke(AIscendTheme.Colors.divider, lineWidth: 1)
                PremiumGraphCurve(variant: .decline)
                    .trim(from: 0, to: reveal)
                    .stroke(AIscendTheme.Colors.error.opacity(0.9), style: StrokeStyle(lineWidth: compact ? 3 : 4, lineCap: .round, lineJoin: .round))
                PremiumGraphCurve(variant: .optimised)
                    .trim(from: 0, to: reveal)
                    .stroke(RoutineAccent.sky.gradient, style: StrokeStyle(lineWidth: compact ? 3 : 4.5, lineCap: .round, lineJoin: .round))
                    .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.24), radius: 16, x: 0, y: 0)
                if !compact {
                    Circle().fill(AIscendTheme.Colors.accentGlow).frame(width: 10, height: 10)
                        .position(x: proxy.size.width * 0.92, y: proxy.size.height * 0.16).opacity(reveal)
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
            PremiumPlanOrb().frame(maxWidth: .infinity)
            PremiumLinearProgress(progress: progress)
            Text("\(Int(progress * 100))% calibrated")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
            VStack(spacing: AIscendTheme.Spacing.medium) {
                ForEach(Array(steps.enumerated()), id: \.offset) { offset, title in
                    row(title, status(for: offset))
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
                .foregroundStyle(status == .complete ? AIscendTheme.Colors.accentGlow : status == .active ? AIscendTheme.Colors.textSecondary : AIscendTheme.Colors.textMuted)
            Text(title).aiscendTextStyle(.body, color: status == .pending ? AIscendTheme.Colors.textMuted : AIscendTheme.Colors.textSecondary)
        }
    }
}

struct PremiumPlanOrb: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(AIscendTheme.Colors.accentGlow.opacity(0.18 - Double(ring) * 0.03), lineWidth: 1)
                    .frame(width: 150 + CGFloat(ring) * 34, height: 150 + CGFloat(ring) * 34)
                    .scaleEffect(pulse ? 1.08 + CGFloat(ring) * 0.03 : 0.92)
                    .opacity(pulse ? 0.18 : 0.42)
            }
            Circle().fill(AIscendTheme.Colors.accentGlow.opacity(0.16)).frame(width: 164, height: 164)
            Circle().fill(AIscendTheme.Colors.secondaryBackground.opacity(0.92)).frame(width: 120, height: 120)
            Image(systemName: "person.fill").font(.system(size: 34, weight: .medium)).foregroundStyle(AIscendTheme.Colors.textPrimary)
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
                Capsule().fill(AIscendTheme.Colors.surfaceHighlight)
                Capsule().fill(RoutineAccent.sky.gradient).frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 10)
    }
}

struct PremiumHaloCards: View {
    private let traits = ["Intelligent", "Kind", "Rich"]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AIscendTheme.Spacing.small) { card("Attractive read", 1, AIscendTheme.Colors.accentGlow); card("Unattractive read", 0.32, AIscendTheme.Colors.textMuted) }
            VStack(spacing: AIscendTheme.Spacing.small) { card("Attractive read", 1, AIscendTheme.Colors.accentGlow); card("Unattractive read", 0.32, AIscendTheme.Colors.textMuted) }
        }
    }

    private func card(_ title: String, _ emphasis: Double, _ tint: Color) -> some View {
        PremiumGlassCard(emphasis: emphasis > 0.6, minHeight: 260) {
            Text(title).aiscendTextStyle(.cardTitle)
            PremiumPortraitGlyph(emphasis: emphasis).frame(maxWidth: .infinity)
            HStack(spacing: AIscendTheme.Spacing.xSmall) {
                ForEach(traits, id: \.self) { trait in
                    Text(trait)
                        .aiscendTextStyle(.caption, color: tint.opacity(0.55 + emphasis * 0.35))
                        .padding(.horizontal, AIscendTheme.Spacing.small)
                        .padding(.vertical, AIscendTheme.Spacing.xSmall)
                        .background(Capsule().fill(AIscendTheme.Colors.surfaceHighlight))
                }
            }
        }
    }
}

struct PremiumPortraitGlyph: View {
    let emphasis: Double

    var body: some View {
        ZStack {
            Circle().fill(AIscendTheme.Colors.accentPrimary.opacity(0.08 + emphasis * 0.10)).frame(width: 150, height: 150)
            Circle().stroke(AIscendTheme.Colors.borderStrong.opacity(0.7), lineWidth: 1).frame(width: 150, height: 150)
            Path { path in
                path.move(to: CGPoint(x: 66, y: 24))
                path.addQuadCurve(to: CGPoint(x: 102, y: 78), control: CGPoint(x: 102, y: 38))
                path.addQuadCurve(to: CGPoint(x: 80, y: 118), control: CGPoint(x: 108, y: 104))
                path.addQuadCurve(to: CGPoint(x: 58, y: 118), control: CGPoint(x: 70, y: 130))
                path.addQuadCurve(to: CGPoint(x: 30, y: 78), control: CGPoint(x: 30, y: 104))
                path.addQuadCurve(to: CGPoint(x: 66, y: 24), control: CGPoint(x: 30, y: 38))
            }
            .stroke(AIscendTheme.Colors.textPrimary.opacity(0.58 + emphasis * 0.24), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            HStack(spacing: 22) {
                Circle().fill(AIscendTheme.Colors.textPrimary.opacity(0.46 + emphasis * 0.24)).frame(width: 6, height: 6)
                Circle().fill(AIscendTheme.Colors.textPrimary.opacity(0.46 + emphasis * 0.24)).frame(width: 6, height: 6)
            }
            .offset(y: -12)
            Capsule().fill(AIscendTheme.Colors.textPrimary.opacity(0.32 + emphasis * 0.22)).frame(width: 26, height: 3).offset(y: 26)
            Rectangle().fill(AIscendTheme.Colors.accentGlow.opacity(emphasis * 0.32)).frame(width: 1, height: 88).offset(y: 8)
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
                Text(metric.title).aiscendTextStyle(.cardTitle)
                Spacer()
                Text("\(Int(metric.value * 100))%").aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AIscendTheme.Colors.surfaceHighlight)
                    Capsule().fill(RoutineAccent.sky.gradient).frame(width: proxy.size.width * metric.value * (reveal ? 1 : 0))
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
            HStack(alignment: .top) {
                ZStack {
                    Circle().fill(AIscendTheme.Colors.accentPrimary.opacity(0.22)).frame(width: 76, height: 76)
                    Image(systemName: "bell.badge.fill").font(.system(size: 28, weight: .medium)).foregroundStyle(AIscendTheme.Colors.textPrimary)
                }
                Spacer()
                AIscendBadge(title: isBusy ? "Requesting" : state.badgeTitle, style: state.badgeStyle)
            }
            Text("Discipline compounds better with quiet prompts.")
                .aiscendTextStyle(.sectionTitle)
            Text("Routine adherence and progress tracking work best when the system stays present.")
                .aiscendTextStyle(.body)
            HStack(spacing: AIscendTheme.Spacing.small) {
                AIscendBadge(title: "Daily routine", symbol: "clock.fill", style: .neutral)
                AIscendBadge(title: "Progress tracking", symbol: "chart.line.uptrend.xyaxis", style: .neutral)
            }
        }
    }
}

struct PremiumAccuracyBlock: View {
    var body: some View {
        PremiumGlassCard(emphasis: true) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.large) { PremiumLandmarkCard(); signals }
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) { PremiumLandmarkCard(); signals }
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
            AIscendIconOrb(symbol: symbol, accent: .sky, size: 40)
            Text(title).aiscendTextStyle(.body).padding(.top, AIscendTheme.Spacing.xSmall)
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
                .fill(AIscendTheme.Colors.surfaceHighlight)
                .frame(width: 190, height: 220)
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
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
                    .stroke(AIscendTheme.Colors.accentGlow.opacity(0.7), lineWidth: 1.2)
                    Path { path in
                        path.move(to: point(points[1], proxy.size)); path.addLine(to: point(points[2], proxy.size))
                        path.move(to: point(points[3], proxy.size)); path.addLine(to: point(points[4], proxy.size))
                        path.move(to: point(points[1], proxy.size)); path.addLine(to: point(points[5], proxy.size)); path.addLine(to: point(points[8], proxy.size))
                        path.move(to: point(points[2], proxy.size)); path.addLine(to: point(points[5], proxy.size))
                    }
                    .stroke(AIscendTheme.Colors.textSecondary.opacity(0.58), lineWidth: 1)
                    ForEach(Array(points.enumerated()), id: \.offset) { _, value in
                        Circle().fill(AIscendTheme.Colors.accentGlow).frame(width: 7, height: 7).position(point(value, proxy.size))
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
                Button {
                    withAnimation(AIscendTheme.Motion.reveal) { model.toggleAnalysisGoal(goal) }
                } label: {
                    PremiumGlassCard(emphasis: model.analysisGoals.contains(goal), minHeight: 206) {
                        HStack(alignment: .top) {
                            AIscendIconOrb(symbol: goal.symbol, accent: model.analysisGoals.contains(goal) ? .sky : .dawn, size: 46)
                            Spacer()
                            Image(systemName: model.analysisGoals.contains(goal) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 21, weight: .semibold))
                                .foregroundStyle(model.analysisGoals.contains(goal) ? AIscendTheme.Colors.accentGlow : AIscendTheme.Colors.textMuted)
                        }
                        Text(goal.title).aiscendTextStyle(.cardTitle)
                        Text(goal.subtitle).aiscendTextStyle(.secondaryBody)
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
            HStack {
                AIscendBrandMark(size: 52, showsWordmark: false)
                Spacer()
                if !trimmed.isEmpty { AIscendBadge(title: "Personalised", symbol: "sparkles", style: .accent) }
            }
            TextField("", text: $name, prompt: Text("Your name").foregroundStyle(AIscendTheme.Colors.textMuted))
                .focused($isFocused)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .aiscendInputField(isFocused: isFocused)
            Text(trimmed.isEmpty ? "You can change this later." : "Your plan will be addressed to \(trimmed).")
                .aiscendTextStyle(.body)
        }
    }

    private var trimmed: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
