//
//  GlassTabBarItem.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import SwiftUI

struct GlassTabBarItem: View {
    let tab: MainTabDestination
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isSelected {
                    activePlate
                        .matchedGeometryEffect(id: "active-tab-plate", in: namespace)
                }

                VStack(spacing: 6) {
                    Image(systemName: tab.symbol)
                        .font(.system(size: 17, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(
                            isSelected
                            ? AIscendTheme.Colors.textPrimary
                            : AIscendTheme.Colors.textMuted
                        )

                    Text(tab.title)
                        .font(.system(size: 11, weight: .semibold, design: .default))
                        .foregroundStyle(
                            isSelected
                            ? AIscendTheme.Colors.textPrimary
                            : AIscendTheme.Colors.textMuted
                        )
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .offset(y: isSelected ? -2 : 0)
                .scaleEffect(isSelected ? 1.02 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(GlassTabBarPressStyle())
    }

    private var activePlate: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.accentSoft.opacity(0.28),
                            Color(hex: "181D27").opacity(0.94)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.accentGlow.opacity(0.42),
                            Color.white.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            Circle()
                .fill(AIscendTheme.Colors.accentGlow.opacity(0.20))
                .frame(width: 56, height: 56)
                .blur(radius: 18)
                .offset(y: 4)
        }
        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.28), radius: 16, x: 0, y: 0)
    }
}

private struct GlassTabBarPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}
