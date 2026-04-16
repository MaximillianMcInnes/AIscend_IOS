import SwiftUI

struct GlassTabBarItem: View {
    let tab: MainTabDestination
    let isSelected: Bool
    let usesQuickFadeSelection: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Group {
                if tab == .scan {
                    scanItem
                } else {
                    standardItem
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(tab == .scan ? "Scan" : label(for: tab))
    }

    private var standardItem: some View {
        ZStack {
            if isSelected {
                selectionHighlight
            }

            VStack(spacing: 4) {
                Image(systemName: iconName(for: tab))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        isSelected
                        ? AnyShapeStyle(MainTabBarStyle.accent)
                        : AnyShapeStyle(MainTabBarStyle.iconIdle)
                    )

                Text(label(for: tab))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(
                        isSelected
                        ? AnyShapeStyle(AIscendTheme.Colors.textPrimary)
                        : AnyShapeStyle(MainTabBarStyle.textIdle)
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var selectionHighlight: some View {
        let highlight = Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        AIscendTheme.Colors.accentPrimary.opacity(0.24),
                        AIscendTheme.Colors.accentDeep.opacity(0.24)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(
                        AIscendTheme.Colors.accentGlow.opacity(0.28),
                        lineWidth: 1
                    )
            )
            .frame(height: 56)

        if usesQuickFadeSelection {
            highlight
                .transition(.opacity)
        } else {
            highlight
                .matchedGeometryEffect(id: "tab-highlight", in: namespace)
        }
    }

    private var scanItem: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.accentGlow.opacity(isSelected ? 0.90 : 0.70),
                            AIscendTheme.Colors.accentSoft.opacity(isSelected ? 0.96 : 0.82),
                            AIscendTheme.Colors.accentPrimary.opacity(isSelected ? 1 : 0.90)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color.white.opacity(isSelected ? 0.10 : 0.06))
                .padding(1)

            Image(systemName: iconName(for: tab))
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(AIscendTheme.Colors.textPrimary)
        }
        .frame(width: 56, height: 56)
        .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(isSelected ? 0.42 : 0.26), radius: isSelected ? 24 : 18, x: 0, y: 0)
        .shadow(color: AIscendTheme.Colors.accentGlow.opacity(isSelected ? 0.24 : 0.12), radius: isSelected ? 32 : 20, x: 0, y: 10)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .contentShape(Rectangle())
        .offset(y: -1)
    }

    private func label(for tab: MainTabDestination) -> String {
        switch tab {
        case .home:
            return "Today"
        case .routine:
            return "Routine"
        case .scan:
            return "Scan"
        case .chat:
            return "Chat"
        case .more:
            return "More"
        }
    }

    private func iconName(for tab: MainTabDestination) -> String {
        switch tab {
        case .home:
            return isSelected ? "house.fill" : "house"
        case .routine:
            return isSelected ? "square.grid.2x2.fill" : "square.grid.2x2"
        case .scan:
            return "plus"
        case .chat:
            return isSelected ? "bubble.left.fill" : "bubble.left"
        case .more:
            return isSelected ? "ellipsis.circle.fill" : "ellipsis.circle"
        }
    }
}
