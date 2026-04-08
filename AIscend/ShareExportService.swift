//
//  ShareExportService.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Photos
import SwiftUI
import UIKit

enum AIScendShareExportError: LocalizedError {
    case renderFailed
    case photoAccessDenied
    case encodingFailed
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .renderFailed:
            "AIScend couldn't render this share card yet."
        case .photoAccessDenied:
            "Photo access is needed to save the card to your library."
        case .encodingFailed:
            "The share image could not be prepared."
        case .saveFailed(let message):
            message
        }
    }
}

@MainActor
final class ShareExportService {
    private let canvasSize = CGSize(width: 1080, height: 1350)

    func renderImage(
        payload: AIScendSharePayload,
        template: AIScendShareTemplate,
        privacyMode: AIScendSharePrivacyMode
    ) throws -> UIImage {
        let content = AIScendShareCardView(
            payload: payload,
            template: template,
            privacyMode: privacyMode
        )
        .frame(width: canvasSize.width, height: canvasSize.height)
        .preferredColorScheme(.dark)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 3

        guard let image = renderer.uiImage else {
            throw AIScendShareExportError.renderFailed
        }

        return image
    }

    func shareItems(
        payload: AIScendSharePayload,
        template: AIScendShareTemplate,
        privacyMode: AIScendSharePrivacyMode
    ) throws -> [Any] {
        let image = try renderImage(
            payload: payload,
            template: template,
            privacyMode: privacyMode
        )

        return [payload.shareCaption, image]
    }

    func saveToPhotos(_ image: UIImage) async throws {
        guard let pngData = image.pngData() else {
            throw AIScendShareExportError.encodingFailed
        }

        let authorization = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        switch authorization {
        case .authorized, .limited:
            break
        default:
            throw AIScendShareExportError.photoAccessDenied
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: pngData, options: nil)
            }, completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: AIScendShareExportError.saveFailed(error.localizedDescription))
                    return
                }

                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: AIScendShareExportError.saveFailed("AIScend could not save the image to Photos."))
                }
            })
        }
    }
}
