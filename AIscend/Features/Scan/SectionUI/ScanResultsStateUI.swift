//
//  ScanResultsStateUI.swift
//  AIscend
//

import SwiftUI

struct ScanResultsLoadingState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendBrandMark(size: 60)

            AIscendBadge(
                title: "Result reveal",
                symbol: "sparkles.rectangle.stack.fill",
                style: .accent
            )

            AIscendLoadingIndicator()

            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xSmall) {
                Text("Preparing the result sequence")
                    .aiscendTextStyle(.sectionTitle)

                Text("AIScend is validating the latest scan, checking archive state, and building the guided reveal.")
                    .aiscendTextStyle(.body)
            }
        }
        .frame(maxWidth: 460, alignment: .leading)
        .padding(AIscendTheme.Spacing.xLarge)
        .aiscendChatGlassCard(cornerRadius: 30, glowOpacity: 0.12)
        .padding(AIscendTheme.Spacing.screenInset)
    }
}

struct ScanResultsEmptyState: View {
    let onOpenScan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
            AIscendBadge(
                title: "No scan found",
                symbol: "viewfinder.circle.fill",
                style: .neutral
            )

            AIscendSectionHeader(
                title: "No scan result is ready right now",
                subtitle: "Run a fresh capture to open the full AIScend reveal flow and unlock the latest result sequence."
            )

            Button(action: onOpenScan) {
                AIscendButtonLabel(title: "Go To Scan", leadingSymbol: "camera.aperture")
            }
            .buttonStyle(AIscendButtonStyle(variant: .primary))
        }
        .frame(maxWidth: 460, alignment: .leading)
        .padding(AIscendTheme.Spacing.xLarge)
        .aiscendChatGlassCard(cornerRadius: 30, glowOpacity: 0.10)
        .padding(AIscendTheme.Spacing.screenInset)
    }
}