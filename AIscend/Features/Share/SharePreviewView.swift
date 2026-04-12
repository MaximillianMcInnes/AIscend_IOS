//
//  SharePreviewView.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import SwiftUI
import UIKit

struct SharePreviewView: View {
    let payload: AIScendSharePayload
    let onDismiss: () -> Void

    @State private var selectedTemplate: AIScendShareTemplate
    @State private var privacyMode: AIScendSharePrivacyMode = .privateMode
    @State private var activityItems: [Any] = []
    @State private var showingShareSheet = false
    @State private var isProcessing = false
    @State private var activeAlert: SharePreviewAlert?
    @State private var toast: SharePreviewToast?

    private let exportService = ShareExportService()

    init(
        payload: AIScendSharePayload,
        onDismiss: @escaping () -> Void = {}
    ) {
        self.payload = payload
        self.onDismiss = onDismiss
        _selectedTemplate = State(initialValue: payload.recommendedTemplate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AIscendBackdrop()
                DashboardAmbientLayer()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xLarge) {
                        previewHeader
                        previewCard
                        templateSection
                        privacySection
                    }
                    .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                    .padding(.top, AIscendTheme.Spacing.large)
                    .padding(.bottom, 160)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    AIscendBadge(
                        title: "Share Preview",
                        symbol: "square.and.arrow.up",
                        style: .accent
                    )
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AIscendTheme.Colors.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.88))
                            )
                            .overlay(
                                Circle()
                                    .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                actionBar
            }
            .sheet(isPresented: $showingShareSheet) {
                AIScendActivityView(activityItems: activityItems)
            }
            .alert(item: $activeAlert) { item in
                Alert(
                    title: Text(item.title),
                    message: Text(item.message),
                    dismissButton: .default(Text("Close"))
                )
            }
            .overlay(alignment: .top) {
                if let toast {
                    SharePreviewToastView(toast: toast)
                        .padding(.top, 84)
                        .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var previewHeader: some View {
        DashboardGlassCard(tone: .hero) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.small) {
                Text("Share a polished AIScend moment")
                    .aiscendTextStyle(.sectionTitle)

                Text("Use a premium template, keep identity hidden by default, then export a clean social-ready card instead of a raw app screenshot.")
                    .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
            }
        }
    }

    private var previewCard: some View {
        DashboardGlassCard {
            AIScendShareCardView(
                payload: payload,
                template: selectedTemplate,
                privacyMode: privacyMode
            )
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
        }
    }

    private var templateSection: some View {
        DashboardGlassCard {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendSectionHeader(
                    eyebrow: "Template",
                    title: "Choose the visual tone",
                    subtitle: "AIScend templates are built for premium flexes, not generic screenshots."
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        ForEach(payload.availableTemplates) { template in
                            ShareSelectionChip(
                                title: template.title,
                                subtitle: template.subtitle,
                                isSelected: template == selectedTemplate
                            ) {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                selectedTemplate = template
                            }
                        }
                    }
                    .padding(.trailing, AIscendTheme.Spacing.medium)
                }
            }
        }
    }

    private var privacySection: some View {
        DashboardGlassCard(tone: .subtle) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.medium) {
                AIscendSectionHeader(
                    eyebrow: "Privacy",
                    title: "Control what leaves the app",
                    subtitle: "Private is the default. Minimal softens details further. Named only appears when you explicitly want the signature attached."
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AIscendTheme.Spacing.small) {
                        ForEach(AIScendSharePrivacyMode.allCases) { option in
                            ShareSelectionChip(
                                title: option.title,
                                subtitle: option.subtitle,
                                isSelected: option == privacyMode
                            ) {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                privacyMode = option
                            }
                        }
                    }
                    .padding(.trailing, AIscendTheme.Spacing.medium)
                }
            }
        }
    }

    private var actionBar: some View {
        VStack(spacing: AIscendTheme.Spacing.small) {
            if isProcessing {
                HStack(spacing: AIscendTheme.Spacing.small) {
                    ProgressView()
                        .tint(AIscendTheme.Colors.accentGlow)

                    Text("Preparing premium export")
                        .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                }
                .padding(.horizontal, AIscendTheme.Spacing.medium)
                .padding(.vertical, AIscendTheme.Spacing.small)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color(hex: "11151C").opacity(0.94))
                )
            }

            HStack(spacing: AIscendTheme.Spacing.small) {
                Button(action: saveToPhotos) {
                    AIscendButtonLabel(title: "Save Image", leadingSymbol: "arrow.down.to.line")
                }
                .buttonStyle(AIscendButtonStyle(variant: .secondary))
                .disabled(isProcessing)

                Button(action: shareCard) {
                    AIscendButtonLabel(title: "Share", leadingSymbol: "square.and.arrow.up")
                }
                .buttonStyle(AIscendButtonStyle(variant: .primary))
                .disabled(isProcessing)
            }
        }
        .padding(.horizontal, AIscendTheme.Spacing.screenInset)
        .padding(.top, AIscendTheme.Spacing.small)
        .padding(.bottom, AIscendTheme.Spacing.small)
        .background(
            LinearGradient(
                colors: [
                    .clear,
                    AIscendTheme.Colors.appBackground.opacity(0.78),
                    AIscendTheme.Colors.appBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func shareCard() {
        guard !isProcessing else {
            return
        }

        Task { @MainActor in
            isProcessing = true
            defer { isProcessing = false }

            do {
                activityItems = try exportService.shareItems(
                    payload: payload,
                    template: selectedTemplate,
                    privacyMode: privacyMode
                )
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                showingShareSheet = true
            } catch {
                activeAlert = SharePreviewAlert(
                    title: "Share Failed",
                    message: error.localizedDescription
                )
            }
        }
    }

    private func saveToPhotos() {
        guard !isProcessing else {
            return
        }

        Task { @MainActor in
            isProcessing = true
            defer { isProcessing = false }

            do {
                let image = try exportService.renderImage(
                    payload: payload,
                    template: selectedTemplate,
                    privacyMode: privacyMode
                )

                try await exportService.saveToPhotos(image)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                showToast(title: "Saved To Photos", message: "Your AIScend card is ready to post or archive.")
            } catch {
                activeAlert = SharePreviewAlert(
                    title: "Save Failed",
                    message: error.localizedDescription
                )
            }
        }
    }

    private func showToast(title: String, message: String) {
        let nextToast = SharePreviewToast(title: title, message: message)

        withAnimation(.easeInOut(duration: 0.22)) {
            toast = nextToast
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if toast == nextToast {
                withAnimation(.easeInOut(duration: 0.22)) {
                    toast = nil
                }
            }
        }
    }
}

private struct ShareSelectionChip: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AIscendTheme.Spacing.xxSmall) {
                Text(title)
                    .aiscendTextStyle(.cardTitle, color: AIscendTheme.Colors.textPrimary)

                Text(subtitle)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 156, alignment: .leading)
            .padding(AIscendTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .fill(
                        isSelected
                        ? AIscendTheme.Colors.accentPrimary.opacity(0.18)
                        : AIscendTheme.Colors.surfaceHighlight.opacity(0.72)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                    .stroke(
                        isSelected
                        ? AIscendTheme.Colors.accentGlow.opacity(0.42)
                        : AIscendTheme.Colors.borderSubtle,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SharePreviewToast: Equatable {
    let title: String
    let message: String
}

private struct SharePreviewAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct SharePreviewToastView: View {
    let toast: SharePreviewToast

    var body: some View {
        HStack(spacing: AIscendTheme.Spacing.medium) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AIscendTheme.Colors.accentGlow)

            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .aiscendTextStyle(.cardTitle)

                Text(toast.message)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(AIscendTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .fill(Color(hex: "11151C").opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.24)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AIscendTheme.Radius.large, style: .continuous)
                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.28), radius: 18, x: 0, y: 12)
    }
}

private struct AIScendActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SharePreviewView(
        payload: .scanResult(from: .previewPremium, identityLine: "premium@aiscend.app")
    )
}
