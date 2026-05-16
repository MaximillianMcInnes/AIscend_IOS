//
//  PreviousScanPhotoPair.swift
//  AIscend
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct PreviousScanPhotoPair: View {
    let frontRawValue: String?
    let sideRawValue: String?

    var body: some View {
        HStack(alignment: .top, spacing: AIscendTheme.Spacing.small) {
            PreviousScanPhotoTile(title: "Front", rawValue: frontRawValue)
            PreviousScanPhotoTile(title: "Side", rawValue: sideRawValue)
        }
    }
}

private struct PreviousScanPhotoTile: View {
    let title: String
    let rawValue: String?

    private var source: ScanPhotoSource {
        ScanPhotoSource(rawValue: rawValue)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(hex: "10141D"))

                photoContent
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                LinearGradient(
                    colors: [
                        .clear,
                        Color.black.opacity(0.74)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(tileShape)

                Text(title)
                    .aiscendTextStyle(.caption, color: AIscendTheme.Colors.textPrimary)
                    .padding(AIscendTheme.Spacing.medium)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(ScanPhotoLayout.portraitAspectRatio, contentMode: .fit)
        .clipShape(tileShape)
        .overlay(tileShape.stroke(Color.white.opacity(0.10), lineWidth: 1))
    }

    @ViewBuilder
    private var photoContent: some View {
        #if canImport(UIKit)
        if source.hasImageSource {
            AIscendCachedImage(
                localURL: source.localURL,
                remoteURL: source.remoteURL,
                maxPixelDimension: 700,
                contentMode: .fill
            ) {
                placeholder
            }
            .scaledToFill()
        } else {
            placeholder
        }
        #else
        if let remoteURL = source.remoteURL {
            remoteImage(remoteURL)
        } else {
            placeholder
        }
        #endif
    }

    private func remoteImage(_ url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .empty:
                placeholder
                    .overlay(PreviousScanShimmerBlock(cornerRadius: 24))
            default:
                placeholder
            }
        }
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [
                Color(hex: "1A1F2B"),
                Color(hex: "0B0E15")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            ZStack {
                Circle()
                    .fill(AIscendTheme.Colors.accentGlow.opacity(0.18))
                    .frame(width: 92, height: 92)
                    .blur(radius: 18)

                Image(systemName: "person.crop.rectangle")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(AIscendTheme.Colors.textMuted)
            }
        }
    }

    private var tileShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
    }
}
