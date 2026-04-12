//
//  AIscendChatService.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

protocol AIscendChatServiceProtocol: Sendable {
    func sendQuery(message: String, email: String?, userID: String?, filters: AIscendChatFilters?) async throws -> AIscendChatRAGResult
    func loadAuthQuotaSnapshot() async -> AIscendChatQuota
}

/// Security note:
/// - `/rag/query` must treat the Firebase bearer token as the source of truth and verify the token on the server.
/// - The request email is provided for convenience and analytics only; the server must reject mismatches.
/// - Premium status and limits can be mirrored in token claims for fast UI reads, but server quota checks remain authoritative.
actor AIscendChatService: AIscendChatServiceProtocol {
    private let configuration: AIscendChatConfiguration
    private let session: URLSession

    init(
        configuration: AIscendChatConfiguration = .live,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
    }

    func sendQuery(message: String, email: String?, userID: String?, filters: AIscendChatFilters?) async throws -> AIscendChatRAGResult {
        guard let baseURL = configuration.backendBaseURL else {
            throw AIscendChatError.missingBackendBaseURL
        }

        let identity = try await authenticatedIdentity()
        guard let chatIdentity = AIscendChatIdentity(
            userID: identity.userID.isEmpty ? userID : identity.userID,
            email: identity.email ?? email
        ) else {
            throw AIscendChatError.missingEmail
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("rag/query"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(identity.idToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60
        request.httpBody = try JSONEncoder().encode(RAGRequest(
            user_message: message,
            email: chatIdentity.requestEmail,
            filters: filters
        ))

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIscendChatError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AIscendChatError.backend(
                backendMessage(from: data, statusCode: httpResponse.statusCode)
            )
        }

        return try parseResult(from: data)
    }

    func loadAuthQuotaSnapshot() async -> AIscendChatQuota {
        guard let identity = try? await authenticatedIdentity(forceRefresh: false) else {
            return .unknown
        }

        let claims = identity.claims
        let plan = Self.stringValue(for: ["plan", "planType", "subscriptionStatus", "tier"], in: claims)?.lowercased()
        let isPremium = Self.boolValue(for: ["isPremium", "premium", "paid", "hasPremium"], in: claims)
            ?? ["premium", "pro", "paid", "trialing", "active"].contains(plan ?? "")
        let remainingChats = Self.intValue(for: ["remainingChats", "remaining", "chatLimitRemaining", "monthlyRemainingChats"], in: claims)
        let monthlyLimit = Self.intValue(for: ["monthlyLimit", "monthlyChatLimit", "chatLimit"], in: claims)
        let usedChats = Self.intValue(for: ["usedChats", "monthlyChatsUsed", "chatUsage", "chatCount"], in: claims)
        let trialEligible = Self.boolValue(for: ["trialEligible", "trialAvailable", "eligibleForTrial"], in: claims) ?? true

        let resolvedRemaining: Int?
        if let remainingChats {
            resolvedRemaining = remainingChats
        } else if let monthlyLimit, let usedChats {
            resolvedRemaining = max(monthlyLimit - usedChats, 0)
        } else {
            resolvedRemaining = nil
        }

        return AIscendChatQuota(
            isPremium: isPremium,
            remainingChats: resolvedRemaining,
            monthlyLimit: monthlyLimit,
            usedChats: usedChats,
            trialEligible: trialEligible,
            sourceDescription: "Firebase token claims"
        )
    }
}

private extension AIscendChatService {
    struct AuthenticatedIdentity {
        let userID: String
        let email: String?
        let idToken: String
        let claims: [String: Any]
    }

    struct RAGRequest: Encodable {
        let user_message: String
        let email: String
        let filters: AIscendChatFilters?
    }

    func authenticatedIdentity(forceRefresh: Bool = true) async throws -> AuthenticatedIdentity {
        #if canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else {
            throw AIscendChatError.notAuthenticated
        }

        let idToken = try await fetchIDToken(for: user, forceRefresh: forceRefresh)
        let tokenResult = try await fetchTokenResult(for: user, forceRefresh: false)

        return AuthenticatedIdentity(
            userID: user.uid,
            email: user.email,
            idToken: idToken,
            claims: tokenResult.claims
        )
        #else
        throw AIscendChatError.notAuthenticated
        #endif
    }

    func parseResult(from data: Data) throws -> AIscendChatRAGResult {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIscendChatError.invalidResponse
        }

        let answer = Self.stringValue(for: ["answer", "response", "message"], in: object) ?? ""
        guard !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIscendChatError.invalidResponse
        }

        let usedContext = Self.stringValue(for: ["used_context", "usedContext"], in: object)
        let sources = Self.decodeSources(from: object["sources"] ?? object["source_metadata"])

        return AIscendChatRAGResult(
            answer: answer,
            usedContext: usedContext,
            sources: sources
        )
    }

    func backendMessage(from data: Data, statusCode: Int) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let message = Self.stringValue(for: ["detail", "error", "message"], in: object)
            if let message, !message.isEmpty {
                return message
            }
        }

        switch statusCode {
        case 401, 403:
            return "Your session needs to be refreshed before AIScend can continue the conversation."
        case 429:
            return "Your chat limit has been reached for now. Premium keeps the advisor open."
        default:
            return "AIScend could not complete that request right now."
        }
    }

    static func decodeSources(from rawValue: Any?) -> [AIscendChatSource] {
        guard let rawValue else {
            return []
        }

        if let dictionaries = rawValue as? [[String: Any]] {
            return dictionaries.compactMap(parseSource(from:))
        }

        if let jsonString = rawValue as? String,
           let data = jsonString.data(using: .utf8),
           let dictionaries = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        {
            return dictionaries.compactMap(parseSource(from:))
        }

        if let strings = rawValue as? [String] {
            return strings.map { AIscendChatSource(label: $0, title: nil, detail: nil, url: nil, type: nil) }
        }

        return []
    }

    static func parseSource(from raw: [String: Any]) -> AIscendChatSource? {
        let label = stringValue(for: ["label", "name", "source", "title"], in: raw) ?? "Source"
        let title = stringValue(for: ["title", "pageTitle", "documentTitle"], in: raw)
        let detail = stringValue(for: ["detail", "snippet", "description"], in: raw)
        let url = stringValue(for: ["url", "href", "link"], in: raw)
        let type = stringValue(for: ["type", "kind"], in: raw)
        return AIscendChatSource(label: label, title: title, detail: detail, url: url, type: type)
    }

    static func stringValue(for keys: [String], in data: [String: Any]) -> String? {
        for key in keys {
            if let value = data[key] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }

        return nil
    }

    static func intValue(for keys: [String], in data: [String: Any]) -> Int? {
        for key in keys {
            if let value = data[key] as? Int {
                return value
            }

            if let value = data[key] as? NSNumber {
                return value.intValue
            }

            if let value = data[key] as? String, let intValue = Int(value) {
                return intValue
            }
        }

        return nil
    }

    static func boolValue(for keys: [String], in data: [String: Any]) -> Bool? {
        for key in keys {
            if let value = data[key] as? Bool {
                return value
            }

            if let value = data[key] as? NSNumber {
                return value.boolValue
            }

            if let value = data[key] as? String {
                switch value.lowercased() {
                case "true", "1", "yes", "active", "premium", "paid":
                    return true
                case "false", "0", "no", "free", "inactive":
                    return false
                default:
                    break
                }
            }
        }

        return nil
    }

    #if canImport(FirebaseAuth)
    func fetchIDToken(for user: User, forceRefresh: Bool) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            user.getIDTokenForcingRefresh(forceRefresh) { token, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: AIscendChatError.notAuthenticated)
                }
            }
        }
    }

    func fetchTokenResult(for user: User, forceRefresh: Bool) async throws -> AuthTokenResult {
        try await withCheckedThrowingContinuation { continuation in
            user.getIDTokenResult(forcingRefresh: forceRefresh) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: AIscendChatError.notAuthenticated)
                }
            }
        }
    }
    #endif
}
