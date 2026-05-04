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
        HStack(spacing: AIscendTheme.Spacing.small) {
            PreviousScanPhotoTile(title: "Front", rawValue: frontRawValue)
            PreviousScanPhotoTile(title: "Side", rawValue: sideRawValue)
        }
    }
}

private struct PreviousScanPhotoTile: View {
    let title: String
    let rawValue: String?

    @State private var didRevealImage = false

    private var source: PreviousScanImageSource {
        PreviousScanImageSource(rawValue: rawValue)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "10141D"))

            photoContent

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
        .frame(maxWidth: .infinity)
        .frame(height: 184)
        .clipShape(tileShape)
        .overlay(tileShape.stroke(Color.white.opacity(0.10), lineWidth: 1))
        .onChange(of: rawValue) { _, _ in
            didRevealImage = false
        }
    }

    @ViewBuilder
    private var photoContent: some View {
        #if canImport(UIKit)
        if let localImage = source.localURL.flatMap({ UIImage(contentsOfFile: $0.path) }) {
            Image(uiImage: localImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(didRevealImage ? 1 : 0)
                .scaleEffect(didRevealImage ? 1 : 1.035)
                .blur(radius: didRevealImage ? 0 : 10)
                .onAppear(perform: revealImageIfNeeded)
        } else if let remoteURL = source.remoteURL {
            remoteImage(remoteURL)
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(didRevealImage ? 1 : 0)
                    .scaleEffect(didRevealImage ? 1 : 1.035)
                    .blur(radius: didRevealImage ? 0 : 10)
                    .onAppear(perform: revealImageIfNeeded)
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

    private func revealImageIfNeeded() {
        guard !didRevealImage else {
            return
        }

        withAnimation(.easeOut(duration: 0.42)) {
            didRevealImage = true
        }
    }
}

private struct PreviousScanImageSource {
    let localURL: URL?
    let remoteURL: URL?

    init(rawValue: String?) {
        let trimmedValue = Self.trimmed(rawValue)
        localURL = Self.resolveLocalURL(from: trimmedValue)
        remoteURL = Self.resolveRemoteURL(from: trimmedValue)
    }

    private static func trimmed(_ rawValue: String?) -> String? {
        let value = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        return value?.isEmpty == false ? value : nil
    }

    private static func resolveLocalURL(from rawValue: String?) -> URL? {
        guard let rawValue else {
            return nil
        }

        return candidateLocalURLs(for: rawValue)
            .first(where: { FileManager.default.fileExists(atPath: $0.path) })
    }

    private static func candidateLocalURLs(for rawValue: String) -> [URL] {
        var candidates: [URL] = []

        if rawValue.hasPrefix("/") {
            candidates.append(URL(fileURLWithPath: rawValue))
        }

        if let directURL = URL(string: rawValue), directURL.isFileURL {
            candidates.append(directURL)
        }

        if let decodedValue = rawValue.removingPercentEncoding {
            if decodedValue.hasPrefix("/") {
                candidates.append(URL(fileURLWithPath: decodedValue))
            }

            if let decodedURL = URL(string: decodedValue), decodedURL.isFileURL {
                candidates.append(decodedURL)
            }
        }

        if !rawValue.contains("://"), !rawValue.hasPrefix("/") {
            let directories = [
                FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
                FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
                FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first,
                FileManager.default.temporaryDirectory
            ].compactMap { $0 }

            for directory in directories {
                candidates.append(directory.appendingPathComponent(rawValue))
                candidates.append(directory.appendingPathComponent("ScanCaptures", isDirectory: true).appendingPathComponent(rawValue))
            }
        }

        return candidates
    }

    private static func resolveRemoteURL(from rawValue: String?) -> URL? {
        guard let rawValue else {
            return nil
        }

        let candidates = [
            rawValue,
            rawValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            rawValue.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        ]

        for candidate in candidates.compactMap({ $0 }) {
            guard let url = URL(string: candidate),
                  let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https"
            else {
                continue
            }

            return url
        }

        return nil
    }
}
