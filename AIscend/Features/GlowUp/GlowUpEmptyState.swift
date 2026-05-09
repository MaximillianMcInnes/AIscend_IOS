//
//  GlowUpEmptyState.swift
//  AIscend
//

import SwiftUI

struct GlowUpEmptyState: View {
    let scanCount: Int

    var body: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                ZStack {
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.extraLarge, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AIscendTheme.Colors.accentPrimary.opacity(0.22),
                                    AIscendTheme.Colors.surfaceHighlight.opacity(0.36)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 180)

                    VStack(spacing: AIscendTheme.Spacing.small) {
                        AIscendIconOrb(symbol: "chart.xyaxis.line", accent: .sky, size: 72)

                        Text("\(scanCount)/2 scans")
                            .aiscendTextStyle(.metricCompact)
                            .monospacedDigit()
                    }
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    AIscendBadge(
                        title: "Progress tracking locked",
                        symbol: "lock.fill",
                        style: .accent
                    )

                    Text("Progress unlocks after multiple scans")
                        .aiscendTextStyle(.sectionTitle)

                    Text("Take another scan after a stretch of consistent grooming, recovery, hydration, posture, and lighting conditions. AIScend can then compare the archive and show what may have changed.")
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AIscendTheme.Colors.accentGlow)
                        .padding(.top, 2)

                    Text("No transformation is guaranteed. The tracker reads visible scan signals and should be interpreted as directional feedback.")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

