//
//  GlassTabBar.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import SwiftUI

struct GlassTabBar: View {
    let selectedTab: MainTabDestination
    let namespace: Namespace.ID
    let onSelect: (MainTabDestination) -> Void

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            ForEach(MainTabDestination.allCases) { tab in
                GlassTabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: namespace,
                    onTap: { onSelect(tab) }
                )
            }
        }
        .padding(10)
        .background(background)
    }

    private var background: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color(hex: "0B0E14").opacity(0.82))

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.74)

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.clear,
                            AIscendTheme.Colors.accentGlow.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(AIscendTheme.Colors.accentGlow.opacity(0.12))
                .frame(width: 180, height: 180)
                .blur(radius: 24)
                .offset(x: 64, y: -72)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.16),
                            AIscendTheme.Colors.accentGlow.opacity(0.22),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.34), radius: 28, x: 0, y: 16)
        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.18), radius: 24, x: 0, y: 0)
    }
}
