import SwiftUI

struct GlassTabBarItem: View {
    let tab: MainTabDestination
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {

                Image(systemName: iconName(for: tab))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        isSelected
                        ? MainTabBarStyle.accent
                        : MainTabBarStyle.iconIdle
                    )

                Text(label(for: tab))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(
                        isSelected
                        ? MainTabBarStyle.accent
                        : MainTabBarStyle.textIdle
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func label(for tab: MainTabDestination) -> String {
        switch tab {
        case .home: return "Today"
        case .routine: return "Routine"
        case .scan: return "Scan"
        case .chat: return "Chat"
        case .profile: return "Me"
        }
    }

    private func iconName(for tab: MainTabDestination) -> String {
        switch tab {
        case .home:
            return isSelected ? "house.fill" : "house"
        case .routine:
            return isSelected ? "square.grid.2x2.fill" : "square.grid.2x2"
        case .scan:
            return isSelected ? "plus.circle.fill" : "plus.circle"
        case .chat:
            return isSelected ? "bubble.left.fill" : "bubble.left"
        case .profile:
            return isSelected ? "person.fill" : "person"
        }
    }
}
