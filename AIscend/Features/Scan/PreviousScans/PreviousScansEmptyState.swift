//
//  PreviousScansEmptyState.swift
//  AIscend
//

import SwiftUI

struct PreviousScansEmptyState: View {
    var body: some View {
        VStack(spacing: AIscendTheme.Spacing.large) {
            ZStack {
                Circle()
                    .fill(AIscendTheme.Colors.accentGlow.opacity(0.16))
                    .frame(width: 104, height: 104)
                    .blur(radius: 20)

                Image(systemName: "rectangle.stack.badge.person.crop.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.textPrimary,
                                AIscendTheme.Colors.accentGlow
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 76, height: 76)
                    .background {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .opacity(0.18)

                            Circle()
                                .fill(Color.white.opacity(0.08))
                        }
                    }
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }

            VStack(spacing: AIscendTheme.Spacing.xSmall) {
                Text("No scans yet")
                    .aiscendTextStyle(.sectionTitle)
                    .multilineTextAlignment(.center)

                Text("Run your first scan to build your archive")
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AIscendTheme.Spacing.xLarge)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.16)

                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.white.opacity(0.075))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.24), radius: 22, x: 0, y: 14)
    }
}
