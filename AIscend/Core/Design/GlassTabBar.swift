import SwiftUI

enum MainTabBarStyle {
    static let accent = Color(hex: "8C5CFF")

    static let bgTop = Color(hex: "12101C").opacity(0.94)
    static let bgBottom = Color(hex: "0D0F14")

    static let iconIdle = Color.white.opacity(0.5)
    static let textIdle = Color.white.opacity(0.5)
}

struct GlassTabBar: View {
    let selectedTab: MainTabDestination
    let namespace: Namespace.ID
    let bottomInset: CGFloat
    let onSelect: (MainTabDestination) -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabItem(.home)
            tabItem(.routine)
            tabItem(.scan)   // now just a normal tab
            tabItem(.chat)
            tabItem(.profile)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
        .padding(.bottom, max(bottomInset, 10))
        .background(
            LinearGradient(
                colors: [
                    MainTabBarStyle.bgTop,
                    MainTabBarStyle.bgBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func tabItem(_ tab: MainTabDestination) -> some View {
        GlassTabBarItem(
            tab: tab,
            isSelected: selectedTab == tab,
            namespace: namespace,
            onTap: { onSelect(tab) }
        )
    }
}
