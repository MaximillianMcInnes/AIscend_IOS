//
//  ScanPhotoLayout.swift
//  AIscend
//

import CoreGraphics
import Foundation

#if canImport(UIKit)
import UIKit
#endif

enum ScanPhotoLayout {
    static let portraitAspectRatio: CGFloat = 3.0 / 4.0
}

enum ScanCaptureGuide: Equatable {
    case front
    case side

    var title: String {
        switch self {
        case .front:
            "Front selfie"
        case .side:
            "Side profile"
        }
    }

    var instruction: String {
        switch self {
        case .front:
            "Center your face in the outline with even lighting."
        case .side:
            "Turn 90 degrees and line up your forehead, nose, lips, and chin."
        }
    }
}

struct ScanPhotoSource {
    let localURL: URL?
    let remoteURL: URL?

    var hasImageSource: Bool {
        localURL != nil || remoteURL != nil
    }

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

#if canImport(UIKit)
extension UIImage {
    static func aiscendPreparedScanImage(
        from data: Data,
        compressionQuality: CGFloat = 0.88
    ) async -> (image: UIImage, data: Data)? {
        await Task.detached(priority: .userInitiated) {
            guard let image = UIImage(data: data) else {
                return nil
            }

            return image.aiscendPreparedScanImage(compressionQuality: compressionQuality)
        }.value
    }

    func aiscendPreparedScanImage(
        compressionQuality: CGFloat = 0.88
    ) -> (image: UIImage, data: Data)? {
        // Performance: crop and JPEG encode camera photos away from SwiftUI state updates.
        // Large picker images otherwise create visible stalls just before the preview appears.
        let scanImage = aiscendCroppedToScanPortrait()
        guard let compressedData = scanImage.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }

        return (scanImage, compressedData)
    }

    func aiscendCroppedToScanPortrait(
        aspectRatio: CGFloat = ScanPhotoLayout.portraitAspectRatio
    ) -> UIImage {
        let normalizedImage = aiscendNormalizedOrientation()

        guard aspectRatio > 0,
              let cgImage = normalizedImage.cgImage
        else {
            return normalizedImage
        }

        let pixelWidth = CGFloat(cgImage.width)
        let pixelHeight = CGFloat(cgImage.height)

        guard pixelWidth > 0, pixelHeight > 0 else {
            return normalizedImage
        }

        let currentAspectRatio = pixelWidth / pixelHeight
        guard abs(currentAspectRatio - aspectRatio) > 0.001 else {
            return normalizedImage
        }

        let cropRect: CGRect
        if currentAspectRatio > aspectRatio {
            let targetWidth = pixelHeight * aspectRatio
            cropRect = CGRect(
                x: (pixelWidth - targetWidth) / 2.0,
                y: 0,
                width: targetWidth,
                height: pixelHeight
            )
        } else {
            let targetHeight = pixelWidth / aspectRatio
            cropRect = CGRect(
                x: 0,
                y: (pixelHeight - targetHeight) / 2.0,
                width: pixelWidth,
                height: targetHeight
            )
        }

        let pixelBounds = CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight)
        let integralCropRect = cropRect.integral.intersection(pixelBounds)

        guard !integralCropRect.isNull,
              let croppedImage = cgImage.cropping(to: integralCropRect)
        else {
            return normalizedImage
        }

        return UIImage(cgImage: croppedImage, scale: normalizedImage.scale, orientation: .up)
    }

    private func aiscendNormalizedOrientation() -> UIImage {
        guard imageOrientation != .up else {
            return self
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
#endif
