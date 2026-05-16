//
//  FaceScanAPIClient.swift
//  AIscend
//

import Foundation

actor FaceScanAPIClient {
    static let automaticSubscription = "free"

    private static let faceScanPath = "api/face_scan"

    private let configuration: AIscendChatConfiguration
    private let session: URLSession

    init(
        configuration: AIscendChatConfiguration = .live,
        session: URLSession? = nil
    ) {
        self.configuration = configuration
        self.session = session ?? Self.makeLongRunningSession()
    }

    func analyze(
        frontImageURL rawFrontImageURL: String,
        sideImageURL rawSideImageURL: String,
        email: String,
        idToken: String,
        subscription: String = FaceScanAPIClient.automaticSubscription
    ) async throws -> PersistedScanRecord {
        guard let baseURL = configuration.apiBaseURL else {
            throw ScanAnalysisError.missingBaseURL
        }

        let frontImageURL = try Self.validatedDownloadURL(rawFrontImageURL, label: "front")
        let sideImageURL = try Self.validatedDownloadURL(rawSideImageURL, label: "side")
        let url = try Self.endpointURL(baseURL: baseURL)
        let requestBody = FaceScanAPIRequest(
            frontImageURL: frontImageURL,
            sideImageURL: sideImageURL,
            email: email,
            subscription: subscription
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 180
        request.httpBody = try JSONEncoder().encode(requestBody)

        Self.logRequestStart(url: url, body: requestBody, tokenExists: !idToken.isEmpty)

        let data: Data
        let response: URLResponse
        let startedAt = Date()
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

        Self.logResponseFinish(data, response: httpResponse, elapsed: Date().timeIntervalSince(startedAt))

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ScanAnalysisError.backend(
                statusCode: httpResponse.statusCode,
                message: Self.backendMessage(from: data, statusCode: httpResponse.statusCode)
            )
        }

        return try Self.decodeRecord(
            from: data,
            fallbackEmail: email,
            frontURL: frontImageURL,
            sideURL: sideImageURL,
            subscription: subscription
        )
    }
}

private extension FaceScanAPIClient {
    struct FaceScanAPIRequest: Encodable {
        let frontImageURL: String
        let sideImageURL: String
        let email: String
        let subscription: String

        enum CodingKeys: String, CodingKey {
            case frontImageURL = "FrontimageUrl"
            case sideImageURL = "SideimageUrl"
            case email
            case subscription
        }
    }

    struct ScanFaceResponse: Decodable {
        let status: String?
        let uid: String?
        let email: String?
        let subscription: String?
        let data: ScanPayload
    }

    static func makeLongRunningSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 180
        configuration.timeoutIntervalForResource = 240
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration)
    }

    static func endpointURL(baseURL: URL) throws -> URL {
        var base = baseURL.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines)
        while base.hasSuffix("/") {
            base.removeLast()
        }

        let endpoint: String
        if base.hasSuffix("/api/face_scan") {
            endpoint = base
        } else if base.hasSuffix("/api") {
            endpoint = "\(base)/face_scan"
        } else {
            endpoint = "\(base)/\(faceScanPath)"
        }

        guard let url = URL(string: endpoint),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty != nil,
              url.path == "/api/face_scan"
        else {
            throw ScanAnalysisError.invalidEndpointURL(endpoint)
        }

        return url
    }

    static func validatedDownloadURL(_ rawURL: String, label: String) throws -> String {
        let trimmed = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ScanAnalysisError.missingImageURL(label)
        }

        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty != nil
        else {
            throw ScanAnalysisError.uploadURLNotResolved(label)
        }

        return trimmed
    }

    static func decodeRecord(
        from data: Data,
        fallbackEmail: String?,
        frontURL: String,
        sideURL: String,
        subscription: String
    ) throws -> PersistedScanRecord {
        guard !data.isEmpty else {
            throw ScanAnalysisError.emptyResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let response = try? decoder.decode(ScanFaceResponse.self, from: data) {
            let record = PersistedScanRecord(
                payload: response.data,
                meta: ScanResultMeta(
                    frontUrl: frontURL,
                    sideUrl: sideURL,
                    email: response.email ?? fallbackEmail,
                    type: response.subscription ?? subscription,
                    scanId: response.uid,
                    source: "scan-flow"
                ),
                savedAt: .now
            )

            guard record.isDisplayable else {
                throw ScanAnalysisError.invalidResponse
            }

            return record.withFallbackMeta(email: fallbackEmail, frontURL: frontURL, sideURL: sideURL, type: subscription)
        }

        if let record = try? decoder.decode(PersistedScanRecord.self, from: data), record.isDisplayable {
            return record.withFallbackMeta(email: fallbackEmail, frontURL: frontURL, sideURL: sideURL, type: subscription)
        }

        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ScanAnalysisError.decodingFailed(debugRawResponse(from: data))
        }

        for key in ["result", "scan", "data", "analysis"] {
            if let nested = object[key],
               let nestedData = try? JSONSerialization.data(withJSONObject: nested),
               let record = try? decoder.decode(PersistedScanRecord.self, from: nestedData),
               record.isDisplayable {
                return record.withFallbackMeta(email: fallbackEmail, frontURL: frontURL, sideURL: sideURL, type: subscription)
            }
        }

        let payloadObject = Self.scanPayloadObject(from: object)
        let jsonData = try JSONSerialization.data(withJSONObject: payloadObject)
        let payload: ScanPayload
        do {
            payload = try decoder.decode(ScanPayload.self, from: jsonData)
        } catch {
            Self.logDecodeFailure(error, data: data)
            throw ScanAnalysisError.decodingFailed(debugRawResponse(from: data))
        }

        let metaSource = object["meta"] ?? object
        let metaData = try? JSONSerialization.data(withJSONObject: metaSource)
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

    static func scanPayloadObject(from object: [String: Any]) -> Any {
        if let dataObject = object["data"] as? [String: Any], looksLikeScanPayload(dataObject) {
            return dataObject
        }

        return object
    }

    static func looksLikeScanPayload(_ object: [String: Any]) -> Bool {
        object["Scores"] != nil
        || object["scores"] != nil
        || object["front_profile"] != nil
        || object["frontProfile"] != nil
        || object["side_profile"] != nil
        || object["sideProfile"] != nil
    }

    static func logRequestStart(url: URL, body: FaceScanAPIRequest, tokenExists: Bool) {
        #if DEBUG
        print(
            """
            [FaceScanAPIClient] Starting face scan request to \(url.absoluteString)
            [FaceScanAPIClient] Request body fields: FrontimageUrl length=\(body.frontImageURL.count), SideimageUrl length=\(body.sideImageURL.count), email set=\(!body.email.isEmpty), subscription=\(body.subscription), token exists=\(tokenExists)
            """
        )
        #endif
    }

    static func logResponseFinish(_ data: Data, response: HTTPURLResponse, elapsed: TimeInterval) {
        #if DEBUG
        let body: String
        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
           let prettyBody = String(data: prettyData, encoding: .utf8) {
            body = prettyBody
        } else {
            body = String(data: data, encoding: .utf8) ?? "<\(data.count) bytes; not utf8>"
        }

        print(
            """
            [FaceScanAPIClient] Face scan completed with status \(response.statusCode) in \(String(format: "%.1f", elapsed))s
            [FaceScanAPIClient] Backend response \(response.statusCode) \(response.url?.absoluteString ?? "")
            \(body)
            """
        )
        #endif
    }

    static func logDecodeFailure(_ error: Error, data: Data) {
        #if DEBUG
        print(
            """
            [FaceScanAPIClient] Decoding failed: \(error)
            [FaceScanAPIClient] Raw response prefix: \(debugRawResponse(from: data))
            """
        )
        #endif
    }

    static func debugRawResponse(from data: Data) -> String {
        #if DEBUG
        let raw = String(data: data, encoding: .utf8) ?? "<\(data.count) bytes; not utf8>"
        return String(raw.prefix(500))
        #else
        return ""
        #endif
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
        case .cancelled:
            return "Scan cancelled."
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
