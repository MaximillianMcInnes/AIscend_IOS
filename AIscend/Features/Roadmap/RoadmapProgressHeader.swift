//
//  RoadmapProgressHeader.swift
//  AIscend
//

import SwiftUI

struct RoadmapProgressHeader: View {
    let roadmap: AIScendRoadmap
    let snapshot: RoadmapProgressSnapshot

    var body: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
                    progressRing

                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                        AIscendBadge(
                            title: "Phase \(snapshot.currentPhaseID.number) active",
                            symbol: "location.fill",
                            style: .accent
                        )

                        Text(roadmap.overallFocus)
                            .aiscendTextStyle(.sectionTitle)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(roadmap.sourceSummary)
                            .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        stat(title: "Current day", value: "\(snapshot.currentDay)/90", symbol: "calendar")
                        stat(title: "Weekly", value: "\(Int((snapshot.weeklyCompletion * 100).rounded()))%", symbol: "chart.bar.fill")
                        stat(title: "Streak", value: "\(snapshot.streakDays)d", symbol: "flame.fill")
                    }

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        stat(title: "Current day", value: "\(snapshot.currentDay)/90", symbol: "calendar")
                        stat(title: "Weekly", value: "\(Int((snapshot.weeklyCompletion * 100).rounded()))%", symbol: "chart.bar.fill")
                        stat(title: "Streak", value: "\(snapshot.streakDays)d", symbol: "flame.fill")
                    }
                }
            }
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 10)

            Circle()
                .trim(from: 0, to: snapshot.todayCompletion)
                .stroke(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.accentCyan,
                            AIscendTheme.Colors.accentGlow,
                            AIscendTheme.Colors.accentPrimary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(snapshot.consistencyScore)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .monospacedDigit()

                Text("ACS")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }
        }
        .frame(width: 96, height: 96)
        .accessibilityLabel("Aesthetic Consistency Score \(snapshot.consistencyScore)")
    }

    private func stat(title: String, value: String, symbol: String) -> some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            AIscendIconOrb(symbol: symbol, accent: .sky, size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                Text(value)
                    .aiscendTextStyle(.cardTitle)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(Color.white.opacity(0.055))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

