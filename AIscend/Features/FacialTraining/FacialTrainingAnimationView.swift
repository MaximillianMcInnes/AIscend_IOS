//
//  FacialTrainingAnimationView.swift
//  AIscend
//
//  Created by Codex on 5/10/26.
//

import SwiftUI

struct ExerciseAnimationView: View {
    let animation: ExerciseAnimation
    let progress: Double
    var parallax: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 0.6 : 1.0 / 60.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let phase = reduceMotion ? 0.5 : (sin(time * 1.8) + 1) / 2

            ZStack(alignment: .bottomLeading) {
                Canvas { context, size in
                    drawGuide(in: &context, size: size, phase: phase)
                }
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.28),
                                    AIscendTheme.Colors.surfaceGlass.opacity(0.48),
                                    Color.black.opacity(0.16)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(animation.accent.tint.opacity(0.24), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text(animation.primaryMuscleLabel)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                    Text(animation.tempoDescription)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                }
                .padding(AIscendTheme.Spacing.medium)
            }
            .offset(x: reduceMotion ? 0 : parallax * 0.06, y: reduceMotion ? 0 : -abs(parallax) * 0.025)
        }
        .frame(height: 260)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(animation.primaryMuscleLabel) animation, \(animation.tempoDescription)")
    }

    private func drawGuide(in context: inout GraphicsContext, size: CGSize, phase: Double) {
        let width = size.width
        let height = size.height
        let centerX = width * 0.5
        let baseY = height * 0.80
        let neckTop = CGPoint(x: centerX, y: height * 0.40)
        let motion = CGFloat(phase - 0.5)
        let accent = animation.accent.tint

        drawAmbientGrid(in: &context, size: size, accent: accent)

        var spine = Path()
        spine.move(to: CGPoint(x: centerX, y: baseY))
        spine.addCurve(
            to: neckTop,
            control1: CGPoint(x: centerX - 18, y: height * 0.68),
            control2: CGPoint(x: centerX + 16, y: height * 0.54)
        )
        context.stroke(spine, with: .color(AIscendTheme.Colors.borderStrong.opacity(0.92)), lineWidth: 8)
        context.stroke(spine, with: .color(accent.opacity(0.38)), lineWidth: 2)

        drawShoulders(in: &context, size: size)

        let headOffset = headOffset(for: animation.pattern, motion: motion)
        let jawOffset = jawOffset(for: animation.pattern, motion: motion)
        let headCenter = CGPoint(x: neckTop.x + headOffset.x, y: neckTop.y - 58 + headOffset.y)
        let headRect = CGRect(x: headCenter.x - 39, y: headCenter.y - 48, width: 78, height: 96)

        drawMuscleHighlights(
            in: &context,
            size: size,
            headRect: headRect,
            neckTop: neckTop,
            motion: motion,
            accent: accent
        )

        var neck = Path()
        neck.move(to: CGPoint(x: neckTop.x - 18, y: neckTop.y + 48))
        neck.addLine(to: CGPoint(x: headCenter.x - 20, y: headCenter.y + 40))
        neck.move(to: CGPoint(x: neckTop.x + 18, y: neckTop.y + 48))
        neck.addLine(to: CGPoint(x: headCenter.x + 20, y: headCenter.y + 40))
        context.stroke(neck, with: .color(AIscendTheme.Colors.textSecondary.opacity(0.62)), lineWidth: 4)

        context.fill(
            Path(ellipseIn: headRect),
            with: .linearGradient(
                Gradient(colors: [
                    AIscendTheme.Colors.surfaceHighlight.opacity(0.92),
                    AIscendTheme.Colors.surfaceMuted.opacity(0.78)
                ]),
                startPoint: CGPoint(x: headRect.minX, y: headRect.minY),
                endPoint: CGPoint(x: headRect.maxX, y: headRect.maxY)
            )
        )
        context.stroke(Path(ellipseIn: headRect), with: .color(AIscendTheme.Colors.borderStrong.opacity(0.8)), lineWidth: 1.5)

        drawJawLine(in: &context, headRect: headRect, offset: jawOffset, accent: accent)
        drawMotionArcs(in: &context, size: size, headCenter: headCenter, phase: phase, accent: accent)
        drawProgressRail(in: &context, size: size, accent: accent)
    }

    private func drawAmbientGrid(in context: inout GraphicsContext, size: CGSize, accent: Color) {
        let step = max(size.width / 8, 38)
        for index in 0...8 {
            let x = CGFloat(index) * step
            var line = Path()
            line.move(to: CGPoint(x: x, y: 0))
            line.addLine(to: CGPoint(x: x - size.width * 0.18, y: size.height))
            context.stroke(line, with: .color(AIscendTheme.Colors.borderSubtle.opacity(0.25)), lineWidth: 0.75)
        }

        context.fill(
            Path(ellipseIn: CGRect(x: size.width * 0.14, y: size.height * 0.08, width: size.width * 0.72, height: size.height * 0.62)),
            with: .radialGradient(
                Gradient(colors: [accent.opacity(0.20), accent.opacity(0.04), .clear]),
                center: CGPoint(x: size.width * 0.56, y: size.height * 0.30),
                startRadius: 8,
                endRadius: size.width * 0.44
            )
        )
    }

    private func drawShoulders(in context: inout GraphicsContext, size: CGSize) {
        let centerX = size.width * 0.5
        let y = size.height * 0.78
        var shoulders = Path()
        shoulders.move(to: CGPoint(x: centerX - 118, y: y + 10))
        shoulders.addCurve(
            to: CGPoint(x: centerX + 118, y: y + 10),
            control1: CGPoint(x: centerX - 54, y: y - 28),
            control2: CGPoint(x: centerX + 54, y: y - 28)
        )
        context.stroke(shoulders, with: .color(AIscendTheme.Colors.textSecondary.opacity(0.42)), lineWidth: 10)
    }

    private func drawMuscleHighlights(
        in context: inout GraphicsContext,
        size: CGSize,
        headRect: CGRect,
        neckTop: CGPoint,
        motion: CGFloat,
        accent: Color
    ) {
        switch animation.pattern {
        case .neckCurl, .deepNeckFlexor, .chinTuck:
            let rect = CGRect(x: headRect.midX - 22, y: headRect.maxY - 4, width: 44, height: 76)
            context.fill(Path(roundedRect: rect, cornerRadius: 20), with: .color(accent.opacity(0.34 + Double(abs(motion)) * 0.28)))
        case .neckExtension:
            let rect = CGRect(x: headRect.midX - 12, y: headRect.maxY - 8, width: 68, height: 86)
            context.fill(Path(roundedRect: rect, cornerRadius: 18), with: .color(accent.opacity(0.32)))
        case .sideNeckRaise, .scmBrace:
            let left = CGRect(x: headRect.minX - 4, y: headRect.maxY - 2, width: 26, height: 82)
            let right = CGRect(x: headRect.maxX - 22, y: headRect.maxY - 2, width: 26, height: 82)
            context.fill(Path(roundedRect: motion >= 0 ? right : left, cornerRadius: 14), with: .color(accent.opacity(0.42)))
        case .tonguePosture, .hyoidEngagement:
            let palate = CGRect(x: headRect.midX - 24, y: headRect.midY - 7, width: 48, height: 12)
            let hyoid = CGRect(x: headRect.midX - 24, y: headRect.maxY + 8, width: 48, height: 16)
            context.fill(Path(roundedRect: palate, cornerRadius: 8), with: .color(accent.opacity(0.44)))
            context.fill(Path(roundedRect: hyoid, cornerRadius: 8), with: .color(accent.opacity(0.30 + Double(motion + 0.5) * 0.20)))
        case .jawResistance, .chewingProtocol:
            let masseter = CGRect(x: headRect.maxX - 20, y: headRect.midY + 3, width: 18, height: 35)
            context.fill(Path(roundedRect: masseter, cornerRadius: 8), with: .color(accent.opacity(0.48)))
        case .wallPosture, .thoracicExtension:
            let stack = CGRect(x: size.width * 0.5 - 4, y: size.height * 0.20, width: 8, height: size.height * 0.60)
            context.fill(Path(roundedRect: stack, cornerRadius: 4), with: .color(accent.opacity(0.34)))
        case .scapularRetraction:
            let left = CGRect(x: size.width * 0.5 - 88, y: size.height * 0.69, width: 54, height: 22)
            let right = CGRect(x: size.width * 0.5 + 34, y: size.height * 0.69, width: 54, height: 22)
            context.fill(Path(roundedRect: left, cornerRadius: 12), with: .color(accent.opacity(0.34)))
            context.fill(Path(roundedRect: right, cornerRadius: 12), with: .color(accent.opacity(0.34)))
        case .breathingReset:
            let breath = CGRect(x: size.width * 0.5 - 54 - (motion * 10), y: size.height * 0.62 - (motion * 5), width: 108 + (motion * 20), height: 48 + (motion * 10))
            context.stroke(Path(ellipseIn: breath), with: .color(accent.opacity(0.42)), lineWidth: 3)
        case .facialRelaxation:
            let face = CGRect(x: headRect.minX + 14, y: headRect.minY + 18, width: 50, height: 42)
            context.stroke(Path(ellipseIn: face), with: .color(accent.opacity(0.34)), lineWidth: 3)
        case .lymphaticMassage:
            drawSweepPath(in: &context, headRect: headRect, accent: accent, motion: motion)
        }
    }

    private func drawJawLine(in context: inout GraphicsContext, headRect: CGRect, offset: CGFloat, accent: Color) {
        var jaw = Path()
        jaw.move(to: CGPoint(x: headRect.minX + 18, y: headRect.midY + 24 + offset))
        jaw.addQuadCurve(
            to: CGPoint(x: headRect.maxX - 15, y: headRect.midY + 18 + offset),
            control: CGPoint(x: headRect.midX + 4, y: headRect.maxY + 14 + offset)
        )
        context.stroke(jaw, with: .color(AIscendTheme.Colors.textPrimary.opacity(0.72)), lineWidth: 3)
        context.stroke(jaw, with: .color(accent.opacity(0.36)), lineWidth: 1)
    }

    private func drawMotionArcs(in context: inout GraphicsContext, size: CGSize, headCenter: CGPoint, phase: Double, accent: Color) {
        let alpha = 0.18 + phase * 0.24
        var arc = Path()
        arc.addArc(
            center: headCenter,
            radius: min(size.width, size.height) * 0.23,
            startAngle: .degrees(206),
            endAngle: .degrees(324),
            clockwise: false
        )
        context.stroke(arc, with: .color(accent.opacity(alpha)), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 8]))
    }

    private func drawSweepPath(in context: inout GraphicsContext, headRect: CGRect, accent: Color, motion: CGFloat) {
        var path = Path()
        path.move(to: CGPoint(x: headRect.midX - 10, y: headRect.maxY + 8))
        path.addCurve(
            to: CGPoint(x: headRect.maxX + 22, y: headRect.midY + 22),
            control1: CGPoint(x: headRect.midX + 22, y: headRect.maxY + 18),
            control2: CGPoint(x: headRect.maxX + 8, y: headRect.midY + 34)
        )
        path.addCurve(
            to: CGPoint(x: headRect.maxX + 12, y: headRect.maxY + 76),
            control1: CGPoint(x: headRect.maxX + 34, y: headRect.midY + 54),
            control2: CGPoint(x: headRect.maxX + 22, y: headRect.maxY + 44)
        )
        context.stroke(path, with: .color(accent.opacity(0.50)), style: StrokeStyle(lineWidth: 4, lineCap: .round))

        let bead = CGPoint(x: headRect.midX + 30 + motion * 28, y: headRect.maxY + 16 + abs(motion) * 34)
        context.fill(Path(ellipseIn: CGRect(x: bead.x - 5, y: bead.y - 5, width: 10, height: 10)), with: .color(accent.opacity(0.82)))
    }

    private func drawProgressRail(in context: inout GraphicsContext, size: CGSize, accent: Color) {
        let rect = CGRect(x: 18, y: size.height - 22, width: size.width - 36, height: 4)
        context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(AIscendTheme.Colors.borderSubtle))
        let progressRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width * min(max(progress, 0), 1), height: rect.height)
        context.fill(Path(roundedRect: progressRect, cornerRadius: 2), with: .color(accent.opacity(0.82)))
    }

    private func headOffset(for pattern: FacialMovementPattern, motion: CGFloat) -> CGPoint {
        switch pattern {
        case .neckCurl:
            return CGPoint(x: 0, y: motion * 18)
        case .neckExtension:
            return CGPoint(x: 0, y: -motion * 12)
        case .sideNeckRaise:
            return CGPoint(x: motion * 24, y: abs(motion) * 4)
        case .chinTuck, .deepNeckFlexor:
            return CGPoint(x: -abs(motion) * 14, y: 0)
        case .thoracicExtension:
            return CGPoint(x: 0, y: -abs(motion) * 7)
        default:
            return .zero
        }
    }

    private func jawOffset(for pattern: FacialMovementPattern, motion: CGFloat) -> CGFloat {
        switch pattern {
        case .jawResistance, .chewingProtocol:
            return abs(motion) * 10
        default:
            return 0
        }
    }
}

struct FacialMovementAnimationView: View {
    let animation: ExerciseAnimation
    let progress: Double

    var body: some View {
        ExerciseAnimationView(animation: animation, progress: progress)
    }
}
