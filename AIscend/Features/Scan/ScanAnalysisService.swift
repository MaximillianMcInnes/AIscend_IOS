//
//  ScanAnalysisService.swift
//  AIscend
//

import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseStorage)
import FirebaseStorage
#endif

protocol ScanAnalysisServiceProtocol: Sendable {
    func analyze(frontImageData: Data, sideImageData: Data, email: String?, userID: String?, isPremium: Bool) async throws -> PersistedScanRecord
}

actor ScanAnalysisService: ScanAnalysisServiceProtocol {
    private let configuration: AIscendChatConfiguration
    private let session: URLSession

    init(
        configuration: AIscendChatConfiguration = .live,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
    }

    func analyze(frontImageData: Data, sideImageData: Data, email: String?, userID: String?, isPremium: Bool) async throws -> PersistedScanRecord {
        guard let baseURL = configuration.apiBaseURL else {
            throw ScanAnalysisError.missingBaseURL
        }

        let idToken = try await firebaseIDToken()
        let uploadedImages = try await uploadScanImages(
            frontImageData: frontImageData,
            sideImageData: sideImageData,
            userID: userID
        )
        let subscription = isPremium ? "paid" : "free"
        let url = Self.endpointURL(baseURL: baseURL, path: configuration.scanAnalyzePath)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 240

        request.httpBody = try JSONEncoder().encode(
            FaceScanAPIRequest(
                frontImageURL: uploadedImages.frontURL,
                sideImageURL: uploadedImages.sideURL,
                email: email,
                subscription: subscription
            )
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            throw ScanAnalysisError.transport(Self.transportMessage(for: urlError))
        } catch {
            throw ScanAnalysisError.transport("The scan could not reach AIScend right now. Check your connection and try again.")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScanAnalysisError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ScanAnalysisError.backend(
                statusCode: httpResponse.statusCode,
                message: Self.backendMessage(from: data, statusCode: httpResponse.statusCode)
            )
        }

        return try Self.decodeRecord(
            from: data,
            fallbackEmail: email,
            frontURL: uploadedImages.frontURL,
            sideURL: uploadedImages.sideURL,
            subscription: subscription
        )
    }
}

private extension ScanAnalysisService {
    struct UploadedScanImages {
        let frontURL: String
        let sideURL: String
    }

    struct FaceScanAPIRequest: Encodable {
        let frontImageURL: String
        let sideImageURL: String
        let email: String?
        let subscription: String

        enum CodingKeys: String, CodingKey {
            case frontImageURL = "FrontimageUrl"
            case sideImageURL = "SideimageUrl"
            case email
            case subscription
        }
    }

    func uploadScanImages(frontImageData: Data, sideImageData: Data, userID: String?) async throws -> UploadedScanImages {
        #if canImport(FirebaseStorage)
        let safeUserID = userID?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "anonymous"
        let scanID = UUID().uuidString
        let root = Storage.storage().reference().child("face_scans/\(safeUserID)/\(scanID)")

        async let frontURL = uploadImage(frontImageData, to: root.child("front.jpg"))
        async let sideURL = uploadImage(sideImageData, to: root.child("side.jpg"))

        return try await UploadedScanImages(frontURL: frontURL, sideURL: sideURL)
        #else
        throw ScanAnalysisError.upload("Scan photo upload is not configured in this build. Add Firebase Storage before running backend face scans.")
        #endif
    }

    #if canImport(FirebaseStorage)
    func uploadImage(_ data: Data, to reference: StorageReference) async throws -> String {
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                reference.putData(data, metadata: metadata) { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }

            let url = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                reference.downloadURL { url, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let url {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(throwing: ScanAnalysisError.upload("AIScend could not create a download URL for your scan photos. Please try again."))
                    }
                }
            }

            return url.absoluteString
        } catch {
            throw ScanAnalysisError.upload("AIScend could not upload your scan photos. Check your connection and try again.")
        }
    }
    #endif

    static func endpointURL(baseURL: URL, path: String) -> URL {
        path
            .split(separator: "/")
            .reduce(baseURL) { partialResult, component in
                partialResult.appendingPathComponent(String(component))
            }
    }

    func firebaseIDToken() async throws -> String {
        #if canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else {
            throw ScanAnalysisError.notAuthenticated
        }

        return try await withCheckedThrowingContinuation { continuation in
            user.getIDTokenForcingRefresh(true) { token, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let token, !token.isEmpty {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: ScanAnalysisError.notAuthenticated)
                }
            }
        }
        #else
        throw ScanAnalysisError.notAuthenticated
        #endif
    }

    static func decodeRecord(
        from data: Data,
        fallbackEmail: String?,
        frontURL: String,
        sideURL: String,
        subscription: String
    ) throws -> PersistedScanRecord {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let record = try? decoder.decode(PersistedScanRecord.self, from: data), record.isDisplayable {
            return record.withFallbackMeta(email: fallbackEmail, frontURL: frontURL, sideURL: sideURL, type: subscription)
        }

        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ScanAnalysisError.invalidResponse
        }

        for key in ["result", "scan", "data", "analysis"] {
            if let nested = object[key],
               let nestedData = try? JSONSerialization.data(withJSONObject: nested),
               let record = try? decoder.decode(PersistedScanRecord.self, from: nestedData),
               record.isDisplayable {
                return record.withFallbackMeta(email: fallbackEmail, frontURL: frontURL, sideURL: sideURL, type: subscription)
            }
        }

        let jsonData = try JSONSerialization.data(withJSONObject: object)
        let payload = try decoder.decode(ScanPayload.self, from: jsonData)
        let metaData = try? JSONSerialization.data(withJSONObject: object["meta"] ?? [:])
        let meta = metaData.flatMap { try? decoder.decode(ScanResultMeta.self, from: $0) }
        let record = PersistedScanRecord(
            payload: payload,
            meta: meta ?? ScanResultMeta(frontUrl: frontURL, sideUrl: sideURL, email: fallbackEmail, type: subscription, source: "scan-flow"),
            savedAt: .now
        )

        guard record.isDisplayable else {
            throw ScanAnalysisError.invalidResponse
        }

        return record.withFallbackMeta(email: fallbackEmail, frontURL: frontURL, sideURL: sideURL, type: subscription)
    }

    static func backendMessage(from data: Data, statusCode: Int) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for key in ["detail", "error", "message"] {
                if let message = object[key] as? String, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return actionableMessage(from: message, statusCode: statusCode)
                }

                if let details = object[key] as? [[String: Any]] {
                    let messages = details.compactMap { detail -> String? in
                        guard let message = detail["msg"] as? String else { return nil }
                        let location = (detail["loc"] as? [Any])?
                            .compactMap { "\($0)" }
                            .filter { $0 != "body" }
                            .joined(separator: " ")

                        if let location, !location.isEmpty {
                            return "\(location): \(message)"
                        }

                        return message
                    }

                    if !messages.isEmpty {
                        return actionableMessage(from: messages.joined(separator: "\n"), statusCode: statusCode)
                    }
                }
            }
        }

        return actionableMessage(from: nil, statusCode: statusCode)
    }

    static func actionableMessage(from rawMessage: String?, statusCode: Int) -> String {
        let message = rawMessage?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let message, !message.isEmpty {
            return message
        }

        switch statusCode {
        case 400:
            return "AIScend could not read these photos. Use clear, well-lit front and side images with exactly one face visible."
        case 401:
            return "Your session expired. Sign in again, then rerun the scan."
        case 403:
            return "This scan is blocked for the current account. Confirm you are signed in with the same email and try again."
        case 413:
            return "The photos are too large to upload. Try retaking them or choosing smaller images."
        case 500...599:
            return "The scan server hit an issue while processing your photos. Please try again in a moment."
        default:
            return "AIScend could not analyze this scan right now. Please try again."
        }
    }

    static func transportMessage(for error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return "Your connection dropped while uploading the scan. Check Wi-Fi or cellular, then try again."
        case .timedOut:
            return "The scan took longer than expected. Try again with a stronger connection."
        case .cannotFindHost, .cannotConnectToHost:
            return "AIScend could not reach the scan server. Check the API URL and try again."
        default:
            return "The scan could not reach AIScend right now. Check your connection and try again."
        }
    }
}

enum ScanAnalysisError: LocalizedError, Equatable {
    case missingBaseURL
    case notAuthenticated
    case invalidResponse
    case upload(String)
    case transport(String)
    case backend(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .missingBaseURL:
            "Add `API_BASE_URL` to the app configuration before running a scan."
        case .notAuthenticated:
            "Sign in before running a private scan."
        case .invalidResponse:
            "AIScend returned an unreadable scan result. Please try again."
        case .upload(let message), .transport(let message):
            message
        case .backend(_, let message):
            message
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .missingBaseURL:
            return "Open the app configuration and set `API_BASE_URL` to your FastAPI host."
        case .notAuthenticated:
            return "Sign in again, then rerun the scan."
        case .invalidResponse:
            return "Try again. If this keeps happening, the backend response format may need checking."
        case .upload:
            return "Use a stable connection and make sure photo upload permissions are available."
        case .transport:
            return "Check your connection, then try running the scan again."
        case .backend(let statusCode, _):
            switch statusCode {
            case 400:
                return "Use a clear front selfie and a clean side-profile photo. Make sure only one face is visible."
            case 401:
                return "Sign in again so AIScend can refresh your secure token."
            case 403:
                return "Make sure the account email matches the signed-in user and that your access is active."
            default:
                return "Try again in a moment. If it keeps failing, send this message to support."
            }
        }
    }

    var alertTitle: String {
        switch self {
        case .missingBaseURL:
            return "Scan server missing"
        case .notAuthenticated:
            return "Sign in required"
        case .invalidResponse:
            return "Result unreadable"
        case .upload:
            return "Photo upload failed"
        case .transport:
            return "Connection problem"
        case .backend(let statusCode, _):
            switch statusCode {
            case 400:
                return "Fix your photos"
            case 401:
                return "Session expired"
            case 403:
                return "Account mismatch"
            default:
                return "Scan failed"
            }
        }
    }
}

private extension PersistedScanRecord {
    func withFallbackMeta(email: String?, frontURL: String, sideURL: String, type: String) -> PersistedScanRecord {
        var copy = self
        if copy.meta.email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            copy.meta.email = email
        }
        if copy.meta.frontUrl?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            copy.meta.frontUrl = frontURL
        }
        if copy.meta.sideUrl?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            copy.meta.sideUrl = sideURL
        }
        if copy.meta.type?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            copy.meta.type = type
        }
        if copy.meta.source?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            copy.meta.source = "scan-flow"
        }
        if copy.savedAt == nil {
            copy.savedAt = .now
        }
        return copy
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
