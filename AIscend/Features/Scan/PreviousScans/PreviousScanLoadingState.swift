//
//  PreviousScanLoadingState.swift
//  AIscend
//

import SwiftUI

struct PreviousScanLoadingState: View {
    var body: some View {
        LazyVStack(spacing: AIscendTheme.Spacing.mediumLarge) {
            ForEach(0..<4, id: \.self) { _ in
                PreviousScanLoadingCard()
            }
        }
        .accessibilityLabel("Loading previous scans")
    }
}

private struct PreviousScanLoadingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AIscendTheme.Spacing.mediumLarge) {
            HStack {
                PreviousScanShimmerBlock(cornerRadius: 10)
                    .frame(width: 168, height: 22)

                Spacer()

                PreviousScanShimmerBlock(cornerRadius: 17)
                    .frame(width: 34, height: 34)
            }

            HStack(spacing: AIscendTheme.Spacing.small) {
                PreviousScanShimmerBlock(cornerRadius: 24)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(ScanPhotoLayout.portraitAspectRatio, contentMode: .fit)

                PreviousScanShimmerBlock(cornerRadius: 24)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(ScanPhotoLayout.portraitAspectRatio, contentMode: .fit)
            }

            PreviousScanShimmerBlock(cornerRadius: 12)
                .frame(width: 220, height: 42)

            PreviousScanShimmerBlock(cornerRadius: 999)
                .frame(height: 9)

            HStack(spacing: AIscendTheme.Spacing.small) {
                PreviousScanShimmerBlock(cornerRadius: 18)
                    .frame(height: 54)
                PreviousScanShimmerBlock(cornerRadius: 18)
                    .frame(height: 54)
                PreviousScanShimmerBlock(cornerRadius: 18)
                    .frame(height: 54)
            }
        }
        .padding(AIscendTheme.Spacing.mediumLarge)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.12)

                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
    }
}

struct PreviousScanShimmerBlock: View {
    let cornerRadius: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shimmerX: CGFloat = -1.2

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.075))
            .overlay {
                if !reduceMotion {
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [
                                .clear,
                                Color.white.opacity(0.18),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 0.68)
                        .offset(x: geometry.size.width * shimmerX)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                }
            }
            .onAppear {
                guard !reduceMotion else {
                    return
                }

                shimmerX = -1.2
                withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                    shimmerX = 1.2
                }
            }
    }
}
