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
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(scanCircleFill)

                Circle()
                    .stroke(
                        isSelected
                        ? AIscendTheme.Colors.accentGlow.opacity(0.42)
                        : AIscendTheme.Colors.borderStrong,
                        lineWidth: 1
                    )

                Image(systemName: iconName(for: tab))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        isSelected
                        ? AnyShapeStyle(AIscendTheme.Colors.textPrimary)
                        : AnyShapeStyle(MainTabBarStyle.iconIdle)
                    )
            }
            .frame(width: 52, height: 52)
            .shadow(
                color: isSelected ? AIscendTheme.Colors.accentPrimary.opacity(0.28) : .clear,
                radius: 18,
                x: 0,
                y: 10
            )

            Text(label(for: tab))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(
                    isSelected
                    ? AnyShapeStyle(AIscendTheme.Colors.textPrimary)
                    : AnyShapeStyle(MainTabBarStyle.textIdle)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .contentShape(Rectangle())
    }

    private var scanCircleFill: LinearGradient {
        LinearGradient(
            colors: isSelected
                ? [
                    AIscendTheme.Colors.accentGlow,
                    AIscendTheme.Colors.accentSoft,
                    AIscendTheme.Colors.accentPrimary
                ]
                : [
                    AIscendTheme.Colors.surfaceInteractive,
                    AIscendTheme.Colors.surfaceMuted
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
            return isSelected ? "camera.macro.circle.fill" : "camera.macro.circle"
        case .chat:
            return isSelected ? "bubble.left.fill" : "bubble.left"
        case .more:
            return isSelected ? "ellipsis.circle.fill" : "ellipsis.circle"
        }
    }
}
