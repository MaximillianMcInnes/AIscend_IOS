//
//  AIscendScanStudioView.swift
//  AIscend
//

import SwiftUI

private enum ScanStudioTab: String, CaseIterable, Hashable, Identifiable {
    case newScan
    case previousScans

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newScan:
            "New Scan"
        case .previousScans:
            "Previous Scans"
        }
    }

    var symbol: String {
        switch self {
        case .newScan:
            "camera.aperture"
        case .previousScans:
            "clock.arrow.trianglehead.counterclockwise.rotate.90"
        }
    }
}

private struct ArchivedScanPresentation: Identifiable {
    let id: String
    let record: PersistedScanRecord
}

struct AIscendScanStudioView: View {
    let model: AppModel
    let session: AuthSessionStore
    let badgeManager: BadgeManager
    let dailyCheckInStore: DailyCheckInStore
    let notificationManager: NotificationManager
    var onOpenChat: () -> Void = {}
    var onOpenRoutine: () -> Void = {}

    @State private var selectedTab: ScanStudioTab = .newScan
    @State private var showScanFlow = false
    @State private var selectedArchivedScan: ArchivedScanPresentation?

    private var snapshot: DashboardSnapshot {
        .live(from: model)
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()
            selectedPage
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showScanFlow) {
            ScanFlowCoordinatorView(
                session: session,
                badgeManager: badgeManager,
                dailyCheckInStore: dailyCheckInStore,
                notificationManager: notificationManager,
                onOpenRoutine: onOpenRoutine,
                onOpenChat: onOpenChat,
                onReturnHome: {
                    showScanFlow = false
                },
                onDismiss: {
                    showScanFlow = false
                }
            )
        }
        .fullScreenCover(item: $selectedArchivedScan) { selectedScan in
            ScanResultsFlowView(
                session: session,
                initialResult: selectedScan.record,
                badgeManager: badgeManager,
                dailyCheckInStore: dailyCheckInStore,
                notificationManager: notificationManager,
                allowsPostResultActions: false,
                onOpenScan: {
                    selectedArchivedScan = nil
                },
                onReturnHome: {
                    selectedArchivedScan = nil
                },
                onDismiss: {
                    selectedArchivedScan = nil
                }
            )
        }
    }

    @ViewBuilder
    private var selectedPage: some View {
        switch selectedTab {
        case .newScan:
            AIscendNewScanStudioPage(
                selection: $selectedTab,
                snapshot: snapshot,
                onStartNewScan: {
                    showScanFlow = true
                }
            )
        case .previousScans:
            AIscendPreviousScansStudioPage(
                selection: $selectedTab,
                snapshot: snapshot,
                session: session,
                onOpenScanRecord: { record in
                    let resolvedID = record.meta.scanId?.trimmingCharacters(in: .whitespacesAndNewlines)
                    selectedArchivedScan = ArchivedScanPresentation(
                        id: resolvedID?.isEmpty == false ? resolvedID! : UUID().uuidString,
                        record: record
                    )
                }
            )
        }
    }
}

private struct ScanStudioHeader: View {
    let snapshot: DashboardSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
            HStack(spacing: AIscendTheme.Spacing.small) {
                ScanStudioBadge(title: "Scan Studio", symbol: "viewfinder.circle.fill")
                ScanStudioBadge(title: "\(snapshot.scans.count) saved", symbol: "clock.fill")
            }

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                Text("Scan")
                    .aiscendTextStyle(.heroTitle, color: AIscendTheme.Colors.textPrimary)

                Text("Capture a new scan or revisit your archive with a cleaner, more focused workspace.")
                    .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
            }

            HStack(spacing: AIscendTheme.Spacing.small) {
                studioMetric(title: "Latest", value: "\(snapshot.score)")
                studioMetric(title: "Scans", value: "\(snapshot.scans.count)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func studioMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            Text(value)
                .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AIscendTheme.Spacing.medium)
        .padding(.vertical, AIscendTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.10),
                            AIscendTheme.Colors.surfaceHighlight.opacity(0.76)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct ScanStudioBadge: View {
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))

            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AIscendTheme.Spacing.small)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.72))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private struct ScanStudioModeToggle: View {
    @Binding var selection: ScanStudioTab

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text("Scan mode")
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            HStack(spacing: 6) {
                ForEach(ScanStudioTab.allCases) { tab in
                    Button {
                        guard selection != tab else {
                            return
                        }

                        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                            selection = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.symbol)
                                .font(.system(size: 11, weight: .semibold))

                            Text(tab.title)
                                .aiscendTextStyle(
                                    .caption,
                                    color: selection == tab ? Color.black : AIscendTheme.Colors.textSecondary
                                )
                        }
                        .foregroundStyle(selection == tab ? Color.black : AIscendTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, AIscendTheme.Spacing.small)
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    selection == tab
                                    ? AnyShapeStyle(
                                        LinearGradient(
                                            colors: [
                                                Color.white,
                                                Color.white.opacity(0.92)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    : AnyShapeStyle(Color.clear)
                                )
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(
                                    selection == tab ? AIscendTheme.Colors.accentGlow.opacity(0.24) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: selection == tab ? Color.black.opacity(0.16) : .clear,
                            radius: 10,
                            x: 0,
                            y: 6
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("scan-studio-tab-\(tab.id)")
                    .accessibilityLabel(tab.title)
                    .accessibilityValue(selection == tab ? "Selected" : "Not selected")
                }
            }
            .padding(6)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                AIscendTheme.Colors.surfaceHighlight.opacity(0.78)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
            )
        }
        .zIndex(1)
    }
}

private struct AIscendNewScanStudioPage: View {
    @Binding var selection: ScanStudioTab
    let snapshot: DashboardSnapshot
    let onStartNewScan: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                ScanStudioHeader(snapshot: snapshot)
                ScanStudioModeToggle(selection: $selection)
                AIscendNewScanTabView(
                    snapshot: snapshot,
                    onStartNewScan: onStartNewScan
                )
            }
            .padding(.horizontal, AIscendTheme.Spacing.screenInset)
            .padding(.top, AIscendTheme.Spacing.large)
            .padding(.bottom, AIscendTheme.Layout.floatingTabBarClearance)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("scan-studio-new-scan-page")
    }
}

private struct AIscendPreviousScansStudioPage: View {
    @Binding var selection: ScanStudioTab
    let snapshot: DashboardSnapshot
    let session: AuthSessionStore
    let onOpenScanRecord: (PersistedScanRecord) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                ScanStudioHeader(snapshot: snapshot)
                ScanStudioModeToggle(selection: $selection)
                AIscendPreviousScansTabView(
                    session: session,
                    embedded: true,
                    onOpenScanRecord: onOpenScanRecord
                )
            }
            .padding(.horizontal, AIscendTheme.Spacing.screenInset)
            .padding(.top, AIscendTheme.Spacing.large)
            .padding(.bottom, AIscendTheme.Layout.floatingTabBarClearance)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("scan-studio-previous-scans-page")
    }
}

private struct AIscendNewScanTabView: View {
    let snapshot: DashboardSnapshot
    let onStartNewScan: () -> Void

    var body: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    ScanStudioBadge(title: "Capture Flow", symbol: "camera.metering.center.weighted")

                    Text("New Scan")
                        .aiscendTextStyle(.sectionTitle)

                    Text("Take or choose a front photo, then a side photo, then send both to the scan engine.")
                        .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                }

                HStack(spacing: AIscendTheme.Spacing.small) {
                    scanInfoPill(
                        title: "Scans",
                        value: "\(snapshot.scans.count)"
                    )

                    scanInfoPill(
                        title: "Current",
                        value: "\(snapshot.score)"
                    )
                }

                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                    scanChecklistRow(title: "Front photo", detail: "Neutral expression, camera straight on.")
                    scanChecklistRow(title: "Side photo", detail: "Clear profile with clean jaw and neck line.")
                    scanChecklistRow(title: "Send to engine", detail: "AIScend packages both shots into a fresh result.")
                }

                Button(action: onStartNewScan) {
                    AIscendButtonLabel(
                        title: "Start New Scan",
                        leadingSymbol: "camera.aperture"
                    )
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("scan-studio-new-scan-root")
    }

    private func scanInfoPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
            Text(title)
                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

            Text(value)
                .aiscendTextStyle(.cardTitle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.62))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.medium, style: .continuous)
                .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private func scanChecklistRow(title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)

                Text(detail)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)
            }
        }
    }
}

private struct AIscendPreviousScansTabView: View {
    let session: AuthSessionStore
    var embedded: Bool = false
    let onOpenScanRecord: (PersistedScanRecord) -> Void

    var body: some View {
        AIscendPreviousScansView(
            session: session,
            embedded: embedded,
            onOpenScanRecord: onOpenScanRecord
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("scan-studio-previous-scans-root")
    }
}

#Preview {
    NavigationStack {
        AIscendScanStudioView(
            model: AppModel(),
            session: AuthSessionStore(),
            badgeManager: BadgeManager(),
            dailyCheckInStore: DailyCheckInStore(),
            notificationManager: NotificationManager()
        )
            .toolbar(.hidden, for: .navigationBar)
    }
}
