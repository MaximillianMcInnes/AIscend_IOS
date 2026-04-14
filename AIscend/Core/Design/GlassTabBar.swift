import SwiftUI

enum MainTabBarStyle {
    static let accent = AIscendTheme.Colors.accentGlow
    static let bgTop = AIscendTheme.Colors.surfaceGlass
    static let bgBottom = AIscendTheme.Colors.surfaceMuted.opacity(0.96)
    static let iconIdle = AIscendTheme.Colors.textMuted
    static let textIdle = AIscendTheme.Colors.textMuted
    static let cornerRadius: CGFloat = 28
}

struct GlassTabBar: View {
    let selectedTab: MainTabDestination
    let usesQuickFadeSelection: Bool
    let namespace: Namespace.ID
    let bottomInset: CGFloat
    let onSelect: (MainTabDestination) -> Void

    var body: some View {
        HStack(spacing: 8) {
            tabItem(.home)
            tabItem(.routine)
            tabItem(.scan)
            tabItem(.chat)
            tabItem(.more)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(tabBarBackground)
        .shadow(color: Color.black.opacity(0.48), radius: 24, x: 0, y: 12)
        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.08), radius: 20, x: 0, y: 0)
        .padding(.horizontal, AIscendTheme.Spacing.screenInset)
        .padding(.top, 6)
        .padding(.bottom, max(bottomInset, 0))
    }

    private var tabBarBackground: some View {
        RoundedRectangle(cornerRadius: MainTabBarStyle.cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        MainTabBarStyle.bgTop,
                        MainTabBarStyle.bgBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: MainTabBarStyle.cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.18)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MainTabBarStyle.cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AIscendTheme.Colors.borderStrong,
                                AIscendTheme.Colors.accentGlow.opacity(0.22),
                                AIscendTheme.Colors.borderSubtle
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: AIscendTheme.Stroke.thin
                    )
            )
    }

    private func tabItem(_ tab: MainTabDestination) -> some View {
        GlassTabBarItem(
            tab: tab,
            isSelected: selectedTab == tab,
            usesQuickFadeSelection: usesQuickFadeSelection,
            namespace: namespace,
            onTap: { onSelect(tab) }
        )
    }
}
