//
//  RoadmapPhaseCard.swift
//  AIscend
//

import SwiftUI

struct RoadmapPhaseCard: View {
    let phase: RoadmapPhase
    let progress: Double
    let isCurrent: Bool

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            phaseNode

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                        AIscendBadge(
                            title: phase.id.dayLabel,
                            symbol: isCurrent ? "location.fill" : "calendar",
                            style: isCurrent ? .accent : .neutral
                        )

                        Text("Phase \(phase.id.number): \(phase.id.title)")
                            .aiscendTextStyle(.cardTitle)
                    }

                    Spacer(minLength: 0)

                    Text("\(Int((progress * 100).rounded()))%")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                        .monospacedDigit()
                }

                Text(phase.focusArea)
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                    ForEach(phase.keyActions, id: \.self) { action in
                        HStack(alignment: .top, spacing: AIscendTheme.Spacing.xSmall) {
                            Image(systemName: "smallcircle.filled.circle")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(AIscendTheme.Colors.accentGlow)
                                .padding(.top, 5)

                            Text(action)
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Text(phase.expectedOutcome)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.075))

                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AIscendTheme.Colors.accentCyan,
                                        AIscendTheme.Colors.accentGlow,
                                        AIscendTheme.Colors.accentPrimary
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 7)
            }
            .padding(AIscendTheme.Spacing.mediumLarge)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(isCurrent ? AIscendTheme.Colors.surfaceGlass.opacity(0.92) : AIscendTheme.Colors.surfaceHighlight.opacity(0.46))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .stroke(isCurrent ? AIscendTheme.Colors.accentGlow.opacity(0.32) : AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
        }
    }

    private var phaseNode: some View {
        VStack(spacing: AIscendTheme.Spacing.xSmall) {
            ZStack {
                Circle()
                    .fill(isCurrent ? RoutineAccent.sky.gradient : RoutineAccent.mint.gradient)
                    .opacity(isCurrent ? 0.92 : 0.42)
                    .frame(width: 42, height: 42)

                Text("\(phase.id.number)")
                    .aiscendTextStyle(.buttonLabel, color: AIscendTheme.Colors.textPrimary)
            }
            .shadow(color: isCurrent ? AIscendTheme.Colors.accentGlow.opacity(0.30) : .clear, radius: 18, x: 0, y: 0)

            Rectangle()
                .fill(AIscendTheme.Colors.borderSubtle)
                .frame(width: 2, height: 96)
        }
    }
}

