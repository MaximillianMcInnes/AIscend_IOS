//
//  ScanCapturePageView.swift
//  AIscend
//

import PhotosUI
import SwiftUI
import UIKit

struct ScanCapturePageView: View {
    let title: String
    let subtitle: String
    let image: UIImage?
    let symbol: String
    let buttonTitle: String
    let stepTitle: String
    let onBack: (() -> Void)?
    let onClose: () -> Void
    let onPickImage: (UIImage, Data) -> Void
    let onContinue: (() -> Void)?
    let footnote: String?

    @State private var pickerItem: PhotosPickerItem?
    @State private var isLoading = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AIscendTheme.Spacing.large) {
                    topBar(topInset: geometry.safeAreaInsets.top)

                    DashboardGlassCard {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                            Text(stepTitle)
                                .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textMuted)

                            Text(title)
                                .aiscendTextStyle(.sectionTitle)

                            Text(subtitle)
                                .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                        }
                    }

                    DashboardGlassCard {
                        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .fill(AIscendTheme.Colors.surfaceHighlight.opacity(0.52))
                                    .frame(height: 320)

                                if let image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 320)
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                                } else {
                                    VStack(spacing: AIscendTheme.Spacing.small) {
                                        Image(systemName: symbol)
                                            .font(.system(size: 42, weight: .medium))
                                            .foregroundStyle(AIscendTheme.Colors.accentGlow)

                                        Text("No image selected")
                                            .aiscendTextStyle(.cardTitle)

                                        Text("Choose a photo from your library.")
                                            .aiscendTextStyle(.body, color: AIscendTheme.Colors.textSecondary)
                                    }
                                    .padding(AIscendTheme.Spacing.large)
                                }

                                if isLoading {
                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                                        .fill(Color.black.opacity(0.35))

                                    ProgressView()
                                        .tint(AIscendTheme.Colors.accentGlow)
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(AIscendTheme.Colors.borderSubtle, lineWidth: 1)
                            )

                            PhotosPicker(selection: $pickerItem, matching: .images) {
                                AIscendButtonLabel(
                                    title: buttonTitle,
                                    leadingSymbol: "photo.badge.plus"
                                )
                            }
                            .buttonStyle(AIscendButtonStyle(variant: .secondary))

                            if let onContinue {
                                Button(action: onContinue) {
                                    AIscendButtonLabel(
                                        title: "Continue",
                                        leadingSymbol: "arrow.right"
                                    )
                                }
                                .buttonStyle(AIscendButtonStyle(variant: .primary))
                            }

                            if let footnote, !footnote.isEmpty {
                                Text(footnote)
                                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.accentGlow)
                            }
                        }
                    }
                }
                .padding(.horizontal, AIscendTheme.Spacing.screenInset)
                .padding(.bottom, AIscendTheme.Spacing.xxLarge)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: pickerItem) { _, newValue in
            guard let newValue else { return }
            Task {
                await importPhoto(from: newValue)
            }
        }
    }

    private func topBar(topInset: CGFloat) -> some View {
        HStack {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AIscendTheme.Colors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color(hex: "10141B").opacity(0.86))
                                .overlay(Circle().fill(.ultraThinMaterial).opacity(0.55))
                        )
                        .overlay(
                            Circle()
                                .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AIscendTheme.Colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color(hex: "10141B").opacity(0.86))
                            .overlay(Circle().fill(.ultraThinMaterial).opacity(0.55))
                    )
                    .overlay(
                        Circle()
                            .stroke(AIscendTheme.Colors.borderStrong, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, topInset + AIscendTheme.Spacing.small)
    }

    private func importPhoto(from item: PhotosPickerItem) async {
        await MainActor.run {
            isLoading = true
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let compressed = image.jpegData(compressionQuality: 0.88) else {
                await MainActor.run {
                    isLoading = false
                }
                return
            }

            await MainActor.run {
                onPickImage(image, compressed)
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}