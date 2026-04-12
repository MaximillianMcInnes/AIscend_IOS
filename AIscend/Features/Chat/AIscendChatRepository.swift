//
//  AIscendChatRepository.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

protocol AIscendChatRepositoryProtocol: Sendable {
    func loadThreads(for email: String?, userID: String?) async throws -> [AIscendChatThread]
    func save(thread: AIscendChatThread, userID: String?) async throws -> AIscendChatThread
    func loadQuota(for email: String?, userID: String?) async -> AIscendChatQuota
}

/// Security note:
/// - Client email is used only as a query convenience and must never be treated as authoritative on its own.
/// - The backend must validate the Firebase ID token and ensure the token identity matches the request email.
/// - Firestore rules must restrict chat reads and writes to the owning UID or email fields on the document.
/// - Any quota shown here is advisory UI state; server-side and Firestore enforcement remain authoritative.
actor AIscendChatRepository: AIscendChatRepositoryProtocol {
    private let configuration: AIscendChatConfiguration

    #if canImport(FirebaseFirestore)
    private let firestore: Firestore
    private var activeChatCollectionName: String?
    #endif

    init(configuration: AIscendChatConfiguration = .live) {
        self.configuration = configuration

        #if canImport(FirebaseFirestore)
        self.firestore = Firestore.firestore()
        #endif
    }

    func loadThreads(for email: String?, userID: String?) async throws -> [AIscendChatThread] {
        let normalizedEmail = normalizedEmail(email)
        let normalizedUserID = normalizedUserID(userID)

        guard normalizedEmail != nil || normalizedUserID != nil else {
            throw AIscendChatError.notAuthenticated
        }

        #if canImport(FirebaseFirestore)
        let collectionNames = configuration.chatCollectionCandidates
        var lastError: Error?

        for collectionName in collectionNames {
            do {
                let documents = try await chatDocuments(
                    in: collectionName,
                    email: normalizedEmail,
                    userID: normalizedUserID
                )

                let threads = documents
                    .compactMap(Self.normalizeThread(from:))
                    .sorted { $0.updatedAt > $1.updatedAt }

                if !threads.isEmpty {
                    activeChatCollectionName = collectionName
                    return threads
                }
            } catch {
                lastError = error
            }
        }

        if let firstCollection = collectionNames.first {
            activeChatCollectionName = firstCollection
        }

        if let lastError {
            throw lastError
        }

        return []
        #else
        let _ = userID
        throw AIscendChatError.firestoreUnavailable
        #endif
    }

    func save(thread: AIscendChatThread, userID: String?) async throws -> AIscendChatThread {
        #if canImport(FirebaseFirestore)
        let collectionName = activeChatCollectionName ?? configuration.chatCollectionCandidates.first ?? "CHATBOT_CHATS"
        let collection = firestore.collection(collectionName)
        let documentReference: DocumentReference

        if let documentID = thread.documentID, !documentID.isEmpty {
            documentReference = collection.document(documentID)
        } else {
            documentReference = collection.document()
        }

        let encodedMessages = try Self.encodeMessages(thread.messages)
        var payload: [String: Any] = [
            "email": thread.email.lowercased(),
            "ownerEmail": thread.email.lowercased(),
            "title": thread.displayTitle,
            "updatedAt": Timestamp(date: thread.updatedAt),
            "createdAt": Timestamp(date: thread.createdAt),
            "json": encodedMessages,
            "messageCount": thread.messages.count,
            "userMessageCount": thread.messages.filter { $0.sender == .user }.count
        ]

        if let userID, !userID.isEmpty {
            payload["ownerUID"] = userID
        }

        if !thread.sources.isEmpty {
            payload["sources"] = Self.encodeSources(thread.sources)
        }

        try await setData(payload, on: documentReference, merge: true)

        return AIscendChatThread(
            id: documentReference.documentID,
            email: thread.email.lowercased(),
            title: thread.displayTitle,
            messages: thread.messages,
            updatedAt: thread.updatedAt,
            createdAt: thread.createdAt,
            sources: thread.sources
        )
        #else
        let _ = userID
        throw AIscendChatError.firestoreUnavailable
        #endif
    }

    func loadQuota(for email: String?, userID: String?) async -> AIscendChatQuota {
        let normalizedEmail = normalizedEmail(email)
        let normalizedUserID = normalizedUserID(userID)

        guard normalizedEmail != nil || normalizedUserID != nil else {
            return .unknown
        }

        #if canImport(FirebaseFirestore)
        for collectionName in configuration.quotaCollectionCandidates {
            if let quota = await quotaFromCollection(
                collectionName,
                email: normalizedEmail,
                userID: normalizedUserID
            ) {
                return quota
            }
        }

        return AIscendChatQuota(
            monthlyLimit: configuration.fallbackFreeMonthlyLimit,
            sourceDescription: configuration.fallbackFreeMonthlyLimit == nil ? nil : "App configuration"
        )
        #else
        let _ = userID
        return .unknown
        #endif
    }
}

#if canImport(FirebaseFirestore)
private extension AIscendChatRepository {
    struct StoredMessage: Codable {
        let sender: String
        let text: String
    }

    func chatDocuments(in collectionName: String, email: String?, userID: String?) async throws -> [DocumentSnapshot] {
        let collection = firestore.collection(collectionName)

        if let email {
            for emailField in ["email", "ownerEmail", "emailLowercased"] {
                let documents = try await orderedDocuments(
                    for: collection.whereField(emailField, isEqualTo: email)
                )

                if !documents.isEmpty {
                    return documents
                }
            }
        }

        guard let userID, !userID.isEmpty else {
            return []
        }

        for userField in ["ownerUID", "uid", "userID", "userId"] {
            let documents = try await orderedDocuments(
                for: collection.whereField(userField, isEqualTo: userID)
            )

            if !documents.isEmpty {
                return documents
            }
        }

        return []
    }

    func quotaFromCollection(_ collectionName: String, email: String?, userID: String?) async -> AIscendChatQuota? {
        let collection = firestore.collection(collectionName)

        if let userID, !userID.isEmpty {
            if let directDocument = try? await getDocument(collection.document(userID)),
               directDocument.exists,
               let quota = Self.normalizeQuota(from: directDocument, source: collectionName)
            {
                return quota
            }
        }

        if let email {
            if let directDocument = try? await getDocument(collection.document(email)),
               directDocument.exists,
               let quota = Self.normalizeQuota(from: directDocument, source: collectionName)
            {
                return quota
            }
        }

        if let email {
            for emailField in ["email", "ownerEmail", "emailLowercased"] {
                if let document = try? await firstDocument(in: collection.whereField(emailField, isEqualTo: email)),
                   let quota = Self.normalizeQuota(from: document, source: collectionName)
                {
                    return quota
                }
            }
        }

        guard let userID, !userID.isEmpty else {
            return nil
        }

        for userField in ["ownerUID", "uid", "userID", "userId"] {
            if let document = try? await firstDocument(in: collection.whereField(userField, isEqualTo: userID)),
               let quota = Self.normalizeQuota(from: document, source: collectionName)
            {
                return quota
            }
        }

        return nil
    }

    func orderedDocuments(for query: Query) async throws -> [DocumentSnapshot] {
        do {
            let snapshot = try await getDocuments(query.order(by: "updatedAt", descending: true))
            return snapshot.documents
        } catch {
            let snapshot = try await getDocuments(query)
            return snapshot.documents.sorted {
                let lhs = Self.dateValue(for: ["updatedAt", "updated_at", "lastUpdated"], in: $0.data()) ?? .distantPast
                let rhs = Self.dateValue(for: ["updatedAt", "updated_at", "lastUpdated"], in: $1.data()) ?? .distantPast
                return lhs > rhs
            }
        }
    }

    func firstDocument(in query: Query) async throws -> DocumentSnapshot? {
        let snapshot = try await getDocuments(query.limit(to: 1))
        return snapshot.documents.first
    }

    static func normalizeThread(from document: DocumentSnapshot) -> AIscendChatThread? {
        let data = document.data() ?? [:]
        let email = stringValue(for: ["email", "ownerEmail", "emailLowercased"], in: data) ?? ""
        let updatedAt = dateValue(for: ["updatedAt", "updated_at", "lastUpdated"], in: data) ?? .now
        let createdAt = dateValue(for: ["createdAt", "created_at"], in: data) ?? updatedAt
        let title = stringValue(for: ["title", "chatTitle", "name"], in: data) ?? ""
        let sources = decodeSources(from: data["sources"] ?? data["sourceMetadata"])
        var messages = decodeMessages(from: data)

        if !sources.isEmpty, let lastAssistantIndex = messages.lastIndex(where: { $0.sender == .bot }) {
            messages[lastAssistantIndex].sources = sources
        }

        return AIscendChatThread(
            id: document.documentID,
            email: email,
            title: title,
            messages: messages,
            updatedAt: updatedAt,
            createdAt: createdAt,
            sources: sources
        )
    }

    static func normalizeQuota(from document: DocumentSnapshot, source: String) -> AIscendChatQuota? {
        let data = document.data() ?? [:]
        let plan = stringValue(for: ["plan", "planType", "subscriptionStatus", "tier"], in: data)?.lowercased()
        let isPremium = boolValue(for: ["isPremium", "premium", "paid", "hasPremium"], in: data)
            ?? ["premium", "pro", "paid", "trialing", "active"].contains(plan ?? "")
        let remainingChats = intValue(for: ["remainingChats", "remaining", "chatLimitRemaining", "monthlyRemainingChats"], in: data)
        let monthlyLimit = intValue(for: ["monthlyLimit", "monthlyChatLimit", "chatLimit"], in: data)
        let usedChats = intValue(for: ["usedChats", "monthlyChatsUsed", "chatUsage", "chatCount"], in: data)
        let trialEligible = boolValue(for: ["trialEligible", "trialAvailable", "eligibleForTrial"], in: data) ?? true

        if !isPremium && remainingChats == nil && monthlyLimit == nil && usedChats == nil && plan == nil {
            return nil
        }

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
            sourceDescription: source
        )
    }

    static func encodeMessages(_ messages: [AIscendChatMessage]) throws -> String {
        let payload = messages.map {
            StoredMessage(sender: $0.sender.rawValue, text: $0.text)
        }

        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)
        return String(decoding: data, as: UTF8.self)
    }

    static func encodeSources(_ sources: [AIscendChatSource]) -> [[String: String]] {
        sources.map { source in
            [
                "label": source.label,
                "title": source.title ?? "",
                "detail": source.detail ?? "",
                "url": source.url ?? "",
                "type": source.type ?? ""
            ]
        }
    }

    static func decodeMessages(from data: [String: Any]) -> [AIscendChatMessage] {
        for key in ["json", "messages", "conversation", "history", "transcript"] {
            if let jsonString = data[key] as? String,
               let decoded = decodeMessageString(jsonString),
               !decoded.isEmpty
            {
                return decoded
            }

            if let rawMessages = data[key] as? [[String: Any]], !rawMessages.isEmpty {
                let parsed = rawMessages.compactMap(parseMessage(from:))
                if !parsed.isEmpty {
                    return parsed
                }
            }
        }

        let legacyPair = decodeLegacyMessages(from: data)
        if !legacyPair.isEmpty {
            return legacyPair
        }

        return []
    }

    static func decodeMessageString(_ jsonString: String) -> [AIscendChatMessage]? {
        let data = Data(jsonString.utf8)
        let decoder = JSONDecoder()

        if let storedMessages = try? decoder.decode([StoredMessage].self, from: data) {
            return storedMessages.map { storedMessage in
                AIscendChatMessage(
                    sender: storedMessage.sender.lowercased() == AIscendChatSender.user.rawValue ? .user : .bot,
                    text: storedMessage.text
                )
            }
        }

        if let arrays = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            let parsed = arrays.compactMap(parseMessage(from:))
            return parsed.isEmpty ? nil : parsed
        }

        return nil
    }

    static func parseMessage(from raw: [String: Any]) -> AIscendChatMessage? {
        let rawSender = stringValue(for: ["sender", "role"], in: raw)?.lowercased() ?? AIscendChatSender.bot.rawValue
        let text = stringValue(for: ["text", "content", "message"], in: raw) ?? ""
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return AIscendChatMessage(
            sender: rawSender == AIscendChatSender.user.rawValue ? .user : .bot,
            text: text
        )
    }

    static func decodeLegacyMessages(from data: [String: Any]) -> [AIscendChatMessage] {
        let userText = stringValue(
            for: ["userMessage", "user_message", "prompt", "question", "query", "request"],
            in: data
        )
        let assistantText = stringValue(
            for: ["assistantMessage", "assistant_message", "answer", "response", "reply", "botMessage"],
            in: data
        )

        var messages: [AIscendChatMessage] = []

        if let userText, !userText.isEmpty {
            messages.append(.user(userText))
        }

        if let assistantText, !assistantText.isEmpty {
            messages.append(.bot(assistantText))
        }

        return messages
    }

    static func decodeSources(from rawValue: Any?) -> [AIscendChatSource] {
        guard let rawValue else {
            return []
        }

        if let dictionaries = rawValue as? [[String: Any]] {
            return dictionaries.compactMap(parseSource(from:))
        }

        if let strings = rawValue as? [String] {
            return strings.map { AIscendChatSource(label: $0, title: nil, detail: nil, url: nil, type: nil) }
        }

        if let jsonString = rawValue as? String,
           let data = jsonString.data(using: .utf8),
           let arrays = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        {
            return arrays.compactMap(parseSource(from:))
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

    static func dateValue(for keys: [String], in data: [String: Any]) -> Date? {
        for key in keys {
            guard let rawValue = data[key] else {
                continue
            }

            switch rawValue {
            case let timestamp as Timestamp:
                return timestamp.dateValue()
            case let date as Date:
                return date
            case let number as NSNumber:
                return Date(timeIntervalSince1970: number.doubleValue / (number.doubleValue > 9_999_999_999 ? 1000 : 1))
            case let string as String:
                if let interval = Double(string) {
                    return Date(timeIntervalSince1970: interval / (interval > 9_999_999_999 ? 1000 : 1))
                }

                let formatter = ISO8601DateFormatter()
                if let date = formatter.date(from: string) {
                    return date
                }
            default:
                break
            }
        }

        return nil
    }

    func getDocuments(_ query: Query) async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { continuation in
            query.getDocuments { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: AIscendChatError.invalidResponse)
                }
            }
        }
    }

    func getDocument(_ reference: DocumentReference) async throws -> DocumentSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            reference.getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: AIscendChatError.invalidResponse)
                }
            }
        }
    }

    func setData(_ data: [String: Any], on reference: DocumentReference, merge: Bool) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.setData(data, merge: merge) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func normalizedEmail(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else {
            return nil
        }

        return trimmed.lowercased()
    }

    func normalizedUserID(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}
#endif
