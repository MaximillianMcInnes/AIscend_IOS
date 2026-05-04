//
//  PreviousScansView.swift
//  AIscend
//

import SwiftUI

struct PreviousScansView: View {
    let embedded: Bool
    let items: [ScanArchiveItem]
    let visibleItems: [ScanArchiveItem]
    let isLoading: Bool
    let errorMessage: String?
    @Binding var sortMode: ScanArchiveSortMode
    let bestScanID: String?
    let latestScanID: String?
    let bestScore: Int
    let latestScore: Int
    let onOpenScanRecord: (PersistedScanRecord) -> Void
    let onLoadMore: (ScanArchiveItem) -> Void

    private let maxContentWidth: CGFloat = 520

    var body: some View {
        Group {
            if embedded {
                content
            } else {
                ScrollView(showsIndicators: false) {
                    content
                        .padding(.horizontal, AIscendTheme.Spacing.medium)
                        .padding(.top, AIscendTheme.Spacing.large)
                        .padding(.bottom, AIscendTheme.Layout.floatingTabBarClearance)
                }
                .background(PreviousScansAmbientBackdrop())
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            PreviousScansHeader()

            PreviousScansStatsStrip(
                savedScansCount: items.count,
                bestScore: items.isEmpty ? nil : bestScore,
                latestScore: items.isEmpty ? nil : latestScore
            )

            if let errorMessage {
                PreviousScansErrorBanner(message: errorMessage)
            }

            PreviousScansSortBar(
                selection: $sortMode,
                visibleCount: visibleItems.count,
                totalCount: items.count
            )

            archiveContent
        }
        .frame(maxWidth: maxContentWidth, alignment: .top)
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var archiveContent: some View {
        if isLoading && items.isEmpty {
            PreviousScanLoadingState()
        } else if !isLoading && items.isEmpty {
            PreviousScansEmptyState()
        } else {
            LazyVStack(spacing: AIscendTheme.Spacing.mediumLarge) {
                ForEach(visibleItems) { item in
                    PreviousScanCard(
                        record: item.record,
                        isBest: item.id == bestScanID,
                        isLatest: item.id == latestScanID,
                        onTap: {
                            onOpenScanRecord(item.record)
                        }
                    )
                    .onAppear {
                        onLoadMore(item)
                    }
                }
            }
        }
    }
}

private struct PreviousScansErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.warning)
                .padding(.top, 2)

            Text(message)
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.18)

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AIscendTheme.Colors.warning.opacity(0.28), lineWidth: 1)
        )
    }
}

private struct PreviousScansAmbientBackdrop: View {
    var body: some View {
        ZStack {
            AIscendTheme.Colors.appBackground.ignoresSafeArea()

            RadialGradient(
                colors: [
                    AIscendTheme.Colors.accentPrimary.opacity(0.26),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 380
            )
            .offset(x: 150, y: -150)

            RadialGradient(
                colors: [
                    Color(hex: "E858FF").opacity(0.13),
                    .clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 320
            )
            .offset(x: -170, y: -70)
        }
        .ignoresSafeArea()
    }
}
