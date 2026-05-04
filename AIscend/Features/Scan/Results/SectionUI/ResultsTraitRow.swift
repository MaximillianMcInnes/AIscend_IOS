//
//  ResultsTraitRow.swift
//  AIscend
//

import SwiftUI

enum ResultsTraitStatus: String, CaseIterable, Identifiable {
    case strong
    case neutral
    case focus

    var id: String { rawValue }

    var title: String {
        switch self {
        case .strong:
            "Strong"
        case .neutral:
            "Neutral"
        case .focus:
            "Focus"
        }
    }

    var tint: Color {
        switch self {
        case .strong:
            AIscendTheme.Colors.accentGlow
        case .neutral:
            AIscendTheme.Colors.accentCyan
        case .focus:
            AIscendTheme.Colors.warning
        }
    }
}

struct ResultsTraitRow<ExpandedContent: View>: View {
    let label: String
    let value: String
    let explanation: String?
    let status: ResultsTraitStatus
    private let hasExpandedContent: Bool
    private let expandedContent: ExpandedContent

    @State private var isExpanded = false

    init(
        label: String,
        value: String,
        explanation: String? = nil,
        status: ResultsTraitStatus = .neutral,
        @ViewBuilder expandedContent: () -> ExpandedContent
    ) {
        self.label = label
        self.value = value
        self.explanation = explanation
        self.status = status
        self.hasExpandedContent = true
        self.expandedContent = expandedContent()
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.86)) {
                isExpanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                HStack(alignment: .center, spacing: AIscendTheme.Spacing.medium) {
                    glowBar

                    VStack(alignment: .leading, spacing: 4) {
                        Text(label)
                            .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)

                        Text(value)
                            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }

                    Spacer(minLength: AIscendTheme.Spacing.small)

                    ResultsTraitStatusChip(status: status)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AIscendTheme.Colors.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }

                if isExpanded {
                    expandedBody
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(AIscendTheme.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackground)
            .clipShape(rowShape)
            .overlay(rowShape.stroke(borderGradient, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var expandedBody: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            if let explanation = trimmed(explanation) {
                Text(explanation)
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if hasExpandedContent {
                expandedContent
            }
        }
        .padding(.leading, 18)
        .padding(.top, AIscendTheme.Spacing.xSmall)
    }

    private var glowBar: some View {
        RoundedRectangle(cornerRadius: 999, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        status.tint,
                        status.tint.opacity(0.20)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 4, height: 46)
            .shadow(color: status.tint.opacity(0.44), radius: 9, x: 0, y: 0)
    }

    private var rowShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
    }

    private var rowBackground: some View {
        ZStack {
            rowShape
                .fill(Color.white.opacity(0.045))
                .background(.ultraThinMaterial, in: rowShape)

            rowShape
                .fill(
                    LinearGradient(
                        colors: [
                            status.tint.opacity(0.08),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.12),
                status.tint.opacity(0.20),
                Color.white.opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func trimmed(_ value: String?) -> String? {
        let text = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return text?.isEmpty == false ? text : nil
    }
}

extension ResultsTraitRow where ExpandedContent == EmptyView {
    init(
        label: String,
        value: String,
        explanation: String? = nil,
        status: ResultsTraitStatus = .neutral
    ) {
        self.label = label
        self.value = value
        self.explanation = explanation
        self.status = status
        self.hasExpandedContent = false
        self.expandedContent = EmptyView()
    }
}

private struct ResultsTraitStatusChip: View {
    let status: ResultsTraitStatus

    var body: some View {
        Text(status.title)
            .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, AIscendTheme.Spacing.small)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(status.tint.opacity(0.16))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(status.tint.opacity(0.28), lineWidth: 1)
            )
    }
}
