//
//  ScanResultsSectionUI.swift
//  AIscend
//

import SwiftUI

struct ResultsSectionShell<Content: View>: View {
    let pageIndex: Int
    let totalPages: Int
    let title: String
    let subtitle: String
    let badge: String?
    let shareActionTitle: String?
    let onShare: (() -> Void)?
    let content: Content

    init(
        pageIndex: Int,
        totalPages: Int,
        title: String,
        subtitle: String,
        badge: String? = nil,
        shareActionTitle: String? = nil,
        onShare: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.pageIndex = pageIndex
        self.totalPages = totalPages
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.shareActionTitle = shareActionTitle
        self.onShare = onShare
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                    topChrome
                    content
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.top, geometry.safeAreaInsets.top + AIscendTheme.Spacing.medium)
                .padding(.bottom, 180)
            }
        }
    }

    private var topChrome: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack {
                AIscendBadge(
                    title: badge ?? "Results",
                    symbol: badge == "Premium" ? "sparkles.rectangle.stack.fill" : "lock.shield.fill",
                    style: badge == "Premium" ? .accent : .neutral
                )

                Spacer()

                VStack(alignment: .trailing, spacing: AIscendTheme.Spacing.xSmall) {
                    if let onShare {
                        AIScendShareEntryButton(title: shareActionTitle ?? "Share", action: onShare)
                    }

                    Text("\(pageIndex + 1) / \(totalPages)")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
                        .padding(.horizontal, AIscendTheme.Spacing.small)
                        .padding(.vertical, AIscendTheme.Spacing.xSmall)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.84))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                }
            }

            AIscendSectionHeader(
                title: title,
                subtitle: subtitle,
                prominence: .hero
            )
        }
    }
}

struct ResultsDotsBar: View {
    let totalPages: Int
    let currentPage: Int
    let onTap: (Int) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<totalPages, id: \.self) { index in
                Button {
                    onTap(index)
                } label: {
                    Capsule(style: .continuous)
                        .fill(
                            index == currentPage
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        AIscendTheme.Colors.accentGlow,
                                        AIscendTheme.Colors.accentPrimary
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyShapeStyle(AIscendTheme.Colors.surfaceHighlight.opacity(0.84))
                        )
                        .frame(width: index == currentPage ? 26 : 8, height: 8)
                        .shadow(
                            color: index == currentPage
                            ? AIscendTheme.Colors.accentPrimary.opacity(0.30)
                            : .clear,
                            radius: 10,
                            x: 0,
                            y: 0
                        )
                        .animation(.spring(response: 0.32, dampingFraction: 0.84), value: currentPage)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AIscendTheme.Spacing.large)
        .padding(.vertical, AIscendTheme.Spacing.medium)
        .background(
            Capsule(style: .continuous)
                .fill(Color(hex: "0C1017").opacity(0.82))
                .overlay(Capsule(style: .continuous).fill(.ultraThinMaterial).opacity(0.62))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.34), radius: 18, x: 0, y: 12)
    }
}

struct ResultsSyncCapsule: View {
    let text: String
    let state: ScanAutoSaveState

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.xSmall) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))

            Text(text)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            Capsule(style: .continuous)
                .fill(Color(hex: "11151C").opacity(0.92))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var symbol: String {
        switch state {
        case .syncing:
            "arrow.triangle.2.circlepath"
        case .saved:
            "checkmark.circle.fill"
        case .localOnly:
            "iphone"
        case .failed:
            "exclamationmark.triangle.fill"
        case .idle, .skipped:
            "lock.fill"
        }
    }

    private var borderColor: Color {
        switch state {
        case .failed:
            AIscendTheme.Colors.warning.opacity(0.38)
        case .saved:
            AIscendTheme.Colors.accentGlow.opacity(0.36)
        case .localOnly:
            AIscendTheme.Colors.borderStrong
        case .syncing, .idle, .skipped:
            AIscendTheme.Colors.borderSubtle
        }
    }
}

struct ResultsPhotoStrip: View {
    let frontURL: URL?
    let sideURL: URL?

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            ResultsPhotoCard(
                title: "Front",
                url: frontURL,
                prominence: .primary
            )

            ResultsPhotoCard(
                title: "Profile",
                url: sideURL,
                prominence: .secondary
            )
        }
    }
}

struct ResultsPhotoCard: View {
    enum Prominence {
        case primary
        case secondary
    }

    let title: String
    let url: URL?
    let prominence: Prominence

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "12161D"))

            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        ResultsPhotoPlaceholder()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                ResultsPhotoPlaceholder()
            }

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.74)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                .padding(AIscendTheme.Spacing.medium)
        }
        .frame(maxWidth: .infinity)
        .frame(height: prominence == .primary ? 250 : 210)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
        )
    }
}

struct ResultsPhotoPlaceholder: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "171C24"),
                Color(hex: "0F131A")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Circle()
                .fill(AIscendTheme.Colors.accentGlow.opacity(0.18))
                .frame(width: 120, height: 120)
                .blur(radius: 18)
        )
    }
}

struct ResultsScoreOrb: View {
    let score: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 12)

            Circle()
                .trim(from: 0.08, to: CGFloat(0.08 + (min(max(score / 100, 0), 1) * 0.84)))
                .stroke(
                    LinearGradient(
                        colors: [
                            AIscendTheme.Colors.accentGlow,
                            AIscendTheme.Colors.accentPrimary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: AIscendTheme.Colors.accentPrimary.opacity(0.30), radius: 20, x: 0, y: 0)

            VStack(spacing: 2) {
                Text(ScanJSONValue.formatted(number: score.rounded()))
                    .aiscendTextStyle(.metric)

                Text("AIScend")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
            }
        }
        .frame(width: 150, height: 150)
    }
}

struct ResultsMetricPanel: View {
    let card: ResultsMetricCardModel

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: card.symbol, accent: card.accent, size: 42)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(card.value)
                    .aiscendTextStyle(.metricCompact)

                Text(card.title)
                    .aiscendTextStyle(.cardTitle)

                Text(card.detail)
                    .aiscendTextStyle(.secondaryBody)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.mediumLarge)
        .aiscendPanel(.standard)
    }
}

struct ResultsPercentileRing: View {
    let percentile: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.03))

            Circle()
                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)

            VStack(spacing: 4) {
                Text("#\(percentile)")
                    .aiscendTextStyle(.metricCompact)

                Text("Percentile")
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }
        }
        .frame(width: 124, height: 124)
        .background(
            Circle()
                .fill(AIscendTheme.Colors.accentGlow.opacity(0.14))
                .blur(radius: 22)
        )
    }
}

struct PlacementBadge: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
            Text(title)
                .aiscendTextStyle(.cardTitle)

            Text(detail)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
        }
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

struct HarmonyHighlightRow: View {
    let trait: ScanTraitRowModel

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: "sparkles", accent: .sky, size: 42)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                HStack {
                    Text(trait.label)
                        .aiscendTextStyle(.cardTitle)

                    Spacer()

                    Text(trait.value)
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                }

                Text(trait.explanation)
                    .aiscendTextStyle(.body)
            }
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

struct ExpandableTraitRow: View {
    let trait: ScanTraitRowModel
    let onUpgrade: () -> Void

    @State private var isExpanded = false

    var body: some View {
        Button {
            if trait.locked {
                onUpgrade()
            } else {
                withAnimation(.easeInOut(duration: 0.22)) {
                    isExpanded.toggle()
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trait.label)
                            .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary.opacity(trait.locked ? 0.78 : 1))

                        Text(trait.value)
                            .aiscendTextStyle(.caption, color: trait.locked ? AIscendTheme.Colors.textMuted : AIscendTheme.Colors.accentGlow)
                    }

                    Spacer()

                    Image(systemName: trait.locked ? "lock.fill" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(trait.locked ? AIscendTheme.Colors.textMuted : AIscendTheme.Colors.textSecondary)
                        .rotationEffect(.degrees(trait.locked ? 0 : (isExpanded ? 180 : 0)))
                }

                if isExpanded || trait.locked {
                    Text(trait.explanation)
                        .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(AIscendTheme.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
            .fill(
                trait.locked
                ? Color(hex: "17131D").opacity(0.92)
                : AIscendTheme.Colors.surfaceHighlight.opacity(0.72)
            )
    }

    private var borderColor: Color {
        trait.locked
        ? AIscendTheme.Colors.accentGlow.opacity(0.24)
        : AIscendTheme.Colors.borderSubtle
    }
}

struct PremiumBenefitRow: View {
    let text: String

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)

            Text(text)
                .aiscendTextStyle(.body)
        }
    }
}

struct ResultsCompletionCard: View {
    let card: ResultsCompletionCardModel

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.medium) {
            AIscendIconOrb(symbol: card.symbol, accent: card.accent, size: 42)

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(card.title)
                    .aiscendTextStyle(.cardTitle)

                Text(card.detail)
                    .aiscendTextStyle(.body)
            }
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

struct ResultsPrimaryButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AIscendButtonLabel(title: title, leadingSymbol: symbol)
        }
        .buttonStyle(AIscendButtonStyle(variant: .primary))
    }
}