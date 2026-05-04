//
//  PreviousScansSortBar.swift
//  AIscend
//

import SwiftUI

struct PreviousScansSortBar: View {
    @Binding var selection: ScanArchiveSortMode
    let visibleCount: Int
    let totalCount: Int

    @Namespace private var selectionNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text("Sort")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                Spacer(minLength: 0)

                if totalCount > 0 {
                    Text("\(visibleCount) / \(totalCount)")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        .monospacedDigit()
                }
            }

            HStack(spacing: 4) {
                ForEach(ScanArchiveSortMode.allCases) { mode in
                    Button {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                            selection = mode
                        }
                    } label: {
                        Text(mode.title)
                            .aiscendTextStyle(
                                .caption,
                                color: selection == mode ? AIscendTheme.Colors.textPrimary : AIscendTheme.Colors.textMuted
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background {
                                if selection == mode {
                                    Capsule(style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    AIscendTheme.Colors.accentPrimary.opacity(0.92),
                                                    Color(hex: "E858FF").opacity(0.70)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .matchedGeometryEffect(id: "sort-selection", in: selectionNamespace)
                                        .shadow(color: AIscendTheme.Colors.accentGlow.opacity(0.28), radius: 16, x: 0, y: 0)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(5)
            .background {
                ZStack {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.16)

                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.07))
                }
            }
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
        }
    }
}
