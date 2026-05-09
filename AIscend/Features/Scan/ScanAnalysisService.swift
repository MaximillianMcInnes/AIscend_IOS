//
//  ScanAnalysisService.swift
//  AIscend
//

import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

protocol ScanAnalysisServiceProtocol: Sendable {
    func analyze(frontImageData: Data, sideImageData: Data, email: String?, userID: String?) async throws -> PersistedScanRecord
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

    func analyze(frontImageData: Data, sideImageData: Data, email: String?, userID: String?) async throws -> PersistedScanRecord {
        guard let baseURL = configuration.apiBaseURL else {
            throw ScanAnalysisError.missingBaseURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        let url = baseURL.appendingPathComponent(configuration.scanAnalyzePath)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        if let idToken = try? await firebaseIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = Self.multipartBody(
            boundary: boundary,
            fields: [
                "email": email ?? "",
                "user_id": userID ?? "",
                "type": "free"
            ],
            files: [
                MultipartFile(fieldName: "front", filename: "front.jpg", mimeType: "image/jpeg", data: frontImageData),
                MultipartFile(fieldName: "side", filename: "side.jpg", mimeType: "image/jpeg", data: sideImageData)
            ]
        )

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScanAnalysisError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ScanAnalysisError.backend(Self.backendMessage(from: data, statusCode: httpResponse.statusCode))
        }

        return try Self.decodeRecord(from: data, fallbackEmail: email)
    }
}

private extension ScanAnalysisService {
    struct MultipartFile {
        let fieldName: String
        let filename: String
        let mimeType: String
        let data: Data
    }

    static func multipartBody(boundary: String, fields: [String: String], files: [MultipartFile]) -> Data {
        var body = Data()

        for (name, value) in fields where !value.isEmpty {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }

        for file in files {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.filename)\"\r\n")
            body.appendString("Content-Type: \(file.mimeType)\r\n\r\n")
            body.append(file.data)
            body.appendString("\r\n")
        }

        body.appendString("--\(boundary)--\r\n")
        return body
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

    static func decodeRecord(from data: Data, fallbackEmail: String?) throws -> PersistedScanRecord {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let record = try? decoder.decode(PersistedScanRecord.self, from: data), record.isDisplayable {
            return record.withFallbackMeta(email: fallbackEmail)
        }

        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ScanAnalysisError.invalidResponse
        }

        for key in ["result", "scan", "data", "analysis"] {
            if let nested = object[key],
               let nestedData = try? JSONSerialization.data(withJSONObject: nested),
               let record = try? decoder.decode(PersistedScanRecord.self, from: nestedData),
               record.isDisplayable {
                return record.withFallbackMeta(email: fallbackEmail)
            }
        }

        let jsonData = try JSONSerialization.data(withJSONObject: object)
        let payload = try decoder.decode(ScanPayload.self, from: jsonData)
        let metaData = try? JSONSerialization.data(withJSONObject: object["meta"] ?? [:])
        let meta = metaData.flatMap { try? decoder.decode(ScanResultMeta.self, from: $0) }
        let record = PersistedScanRecord(
            payload: payload,
            meta: meta ?? ScanResultMeta(email: fallbackEmail, type: "free", source: "scan-flow"),
            savedAt: .now
        )

        guard record.isDisplayable else {
            throw ScanAnalysisError.invalidResponse
        }

        return record.withFallbackMeta(email: fallbackEmail)
    }

    static func backendMessage(from data: Data, statusCode: Int) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for key in ["detail", "error", "message"] {
                if let message = object[key] as? String, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return message
                }
            }
        }

        return "AIScend could not analyze this scan right now. Please try again."
    }
}

enum ScanAnalysisError: LocalizedError, Equatable {
    case missingBaseURL
    case notAuthenticated
    case invalidResponse
    case backend(String)

    var errorDescription: String? {
        switch self {
        case .missingBaseURL:
            "Add `API_BASE_URL` to the app configuration before running a scan."
        case .notAuthenticated:
            "Sign in before running a private scan."
        case .invalidResponse:
            "AIScend returned an unreadable scan result. Please try again."
        case .backend(let message):
            message
        }
    }
}

private extension PersistedScanRecord {
    func withFallbackMeta(email: String?) -> PersistedScanRecord {
        var copy = self
        if copy.meta.email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            copy.meta.email = email
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

private extension Data {
    mutating func appendString(_ value: String) {
        if let data = value.data(using: .utf8) {
            append(data)
        }
    }
}
