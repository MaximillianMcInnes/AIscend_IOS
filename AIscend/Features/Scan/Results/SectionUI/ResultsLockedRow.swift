//
//  ResultsLockedRow.swift
//  AIscend
//

import SwiftUI

struct ResultsLockedRow: View {
    let label: String
    var value: String = "Premium insight"
    var detail: String = "Unlock the full analytical read."
    var pillTitle: String = "Unlock"
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            ZStack(alignment: .trailing) {
                HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(AIscendTheme.Colors.accentGlow.opacity(0.55))
                        .frame(width: 4, height: 44)
                        .blur(radius: 1)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(label)
                            .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary.opacity(0.70))

                        Text(value)
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    }

                    Spacer(minLength: AIscendTheme.Spacing.medium)
                }
                .blur(radius: 2.5)
                .opacity(0.58)

                HStack(spacing: AIscendTheme.Spacing.xSmall) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .bold))

                    Text(pillTitle)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                }
                .padding(.horizontal, AIscendTheme.Spacing.small)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(AIscendTheme.Colors.accentGlow.opacity(0.18))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(AIscendTheme.Colors.accentGlow.opacity(0.34), lineWidth: 1)
                )
            }
            .overlay(alignment: .bottomLeading) {
                Text(detail)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                    .padding(.leading, AIscendTheme.Spacing.medium)
                    .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AIscendTheme.Spacing.medium)
            .padding(.bottom, AIscendTheme.Spacing.medium)
            .background(rowBackground)
            .clipShape(rowShape)
            .overlay(rowShape.stroke(borderGradient, lineWidth: 1))
            .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.08), radius: 18, x: 0, y: 0)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }

    private var rowShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
    }

    private var rowBackground: some View {
        ZStack {
            rowShape
                .fill(Color.white.opacity(0.04))
                .background(.ultraThinMaterial, in: rowShape)

            LinearGradient(
                colors: [
                    AIscendTheme.Colors.accentGlow.opacity(0.10),
                    Color(hex: "E858FF").opacity(0.05),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(rowShape)
        }
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.12),
                AIscendTheme.Colors.accentGlow.opacity(0.22),
                Color.white.opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
