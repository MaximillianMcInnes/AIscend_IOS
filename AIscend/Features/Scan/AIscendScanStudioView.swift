//
//  AIscendScanStudioView.swift
//  AIscend
//

import SwiftUI

struct AIscendScanStudioView: View {
    @Bindable var model: AppModel
    var onOpenLatestResult: () -> Void = {}
    var onBeginCapture: () -> Void = {}
    var onOpenChat: () -> Void = {}
    var onOpenRoutine: () -> Void = {}

    @State private var selectedTab: StudioTab = .newScan
    @State private var showScanFlow = false

    private var snapshot: DashboardSnapshot {
        .live(from: model)
    }

    var body: some View {
        ZStack {
            AIscendBackdrop()
            DashboardAmbientLayer()

            VStack(spacing: AIscendTheme.Spacing.large) {
                header

                Picker("Studio Tab", selection: $selectedTab) {
                    Text("New Scan").tag(StudioTab.newScan)
                    Text("Previous Scans").tag(StudioTab.previousScans)
                }
                .pickerStyle(.segmented)

                Group {
                    switch selectedTab {
                    case .newScan:
                        newScanTab
                    case .previousScans:
                        previousScansTab
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AIscendTheme.Spacing.screenInset)
            .padding(.top, AIscendTheme.Spacing.large)
            .padding(.bottom, AIscendTheme.Layout.floatingTabBarClearance)
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showScanFlow) {
            ScanFlowCoordinatorView(
                session: model.authSessionStore,
                badgeManager: model.badgeManager,
                dailyCheckInStore: model.dailyCheckInStore,
                notificationManager: model.notificationManager,
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
            Text("Scan")
                .aiscendTextStyle(.heroTitle, color: AIscendTheme.Colors.textPrimary)

            Text("Keep it simple. Start a new scan or review your scan archive.")
                .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var newScanTab: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                    Text("New Scan")
                        .aiscendTextStyle(.sectionTitle)

                    Text("Upload a front photo, then a side photo, then send both to the scan engine.")
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

                Button(action: {
                    showScanFlow = true
                }) {
                    AIscendButtonLabel(
                        title: "Start New Scan",
                        leadingSymbol: "camera.aperture"
                    )
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))
            }
        }
    }

    private var previousScansTab: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                Text("Previous Scans")
                    .aiscendTextStyle(.sectionTitle)

                Text("Blank for now.")
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)

                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.55))
                    .frame(height: 220)
                    .overlay(
                        Text("Previous scans coming soon")
                            .aiscendTextStyle(.secondaryBody, color: AIscendTheme.Colors.textMuted)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                            .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                    )
            }
        }
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
}

private extension AIscendScanStudioView {
    enum StudioTab: Hashable {
        case newScan
        case previousScans
    }
}

#Preview {
    NavigationStack {
        AIscendScanStudioView(model: AppModel())
            .toolbar(.hidden, for: .navigationBar)
    }
}