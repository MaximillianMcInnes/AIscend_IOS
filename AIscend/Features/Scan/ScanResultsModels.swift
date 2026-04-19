//
//  ScanResultsModels.swift
//  AIscend
//
//  Created by Codex on 4/8/26.
//

import Foundation

enum ScanJSONValue: Codable, Hashable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: ScanJSONValue])
    case array([ScanJSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let numberValue = try? container.decode(Double.self) {
            self = .number(numberValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let objectValue = try? container.decode([String: ScanJSONValue].self) {
            self = .object(objectValue)
        } else if let arrayValue = try? container.decode([ScanJSONValue].self) {
            self = .array(arrayValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported scan JSON value."
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

    var stringValue: String? {
        switch self {
        case .string(let value):
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        case .number(let value):
            return Self.formatted(number: value)
        case .bool(let value):
            return value ? "Yes" : "No"
        default:
            return nil
        }
    }

    var numberValue: Double? {
        switch self {
        case .number(let value):
            value
        case .string(let value):
            Double(value)
        default:
            nil
        }
    }

    var objectValue: [String: ScanJSONValue]? {
        if case .object(let value) = self {
            return value
        }

        return nil
    }

    var arrayValue: [ScanJSONValue]? {
        if case .array(let value) = self {
            return value
        }

        return nil
    }

    var displayString: String? {
        switch self {
        case .string, .number, .bool:
            return stringValue
        case .object(let value):
            return value["value"]?.displayString
            ?? value["label"]?.displayString
            ?? value["rating"]?.displayString
            ?? value["score"]?.displayString
            ?? value["status"]?.displayString
        case .array(let value):
            let labels = value.compactMap(\.displayString)
            guard !labels.isEmpty else {
                return nil
            }

            let previewLabels = Array(labels.prefix(3))
            return previewLabels.joined(separator: " | ")
        case .null:
            return nil
        }
    }

    static func formatted(number: Double) -> String {
        if number.rounded() == number {
            return "\(Int(number))"
        }

        return String(format: "%.1f", number)
    }
}

struct ScanScores: Codable, Hashable, Sendable {
    var overall: Double?
    var potential: Double?
    var eyes: Double?
    var skin: Double?
    var jaw: Double?
    var side: Double?

    init(
        overall: Double? = nil,
        potential: Double? = nil,
        eyes: Double? = nil,
        skin: Double? = nil,
        jaw: Double? = nil,
        side: Double? = nil
    ) {
        self.overall = overall
        self.potential = potential
        self.eyes = eyes
        self.skin = skin
        self.jaw = jaw
        self.side = side
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        let values = container.allKeys.reduce(into: [String: ScanJSONValue]()) { partialResult, key in
            partialResult[key.stringValue] = (try? container.decode(ScanJSONValue.self, forKey: key)) ?? .null
        }

        self.init(object: values)
    }

    init(object: [String: ScanJSONValue]) {
        overall = Self.number(for: ["overall", "Overall"], in: object)
        potential = Self.number(for: ["potential", "Potential"], in: object)
        eyes = Self.number(for: ["eyes", "Eyes"], in: object)
        skin = Self.number(for: ["skin", "Skin"], in: object)
        jaw = Self.number(for: ["jaw", "Jaw"], in: object)
        side = Self.number(for: ["side", "Side"], in: object)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(overall, forKey: .overall)
        try container.encodeIfPresent(potential, forKey: .potential)
        try container.encodeIfPresent(eyes, forKey: .eyes)
        try container.encodeIfPresent(skin, forKey: .skin)
        try container.encodeIfPresent(jaw, forKey: .jaw)
        try container.encodeIfPresent(side, forKey: .side)
    }

    private enum CodingKeys: String, CodingKey {
        case overall
        case potential
        case eyes
        case skin = "Skin"
        case jaw
        case side = "Side"
    }

    private static func number(for keys: [String], in object: [String: ScanJSONValue]) -> Double? {
        for key in keys {
            if let value = object[key]?.numberValue {
                return value
            }
        }

        return nil
    }
}

struct ScanResultMeta: Codable, Hashable, Sendable {
    var frontUrl: String?
    var sideUrl: String?
    var email: String?
    var type: String?
    var scanId: String?
    var source: String?

    init(
        frontUrl: String? = nil,
        sideUrl: String? = nil,
        email: String? = nil,
        type: String? = nil,
        scanId: String? = nil,
        source: String? = nil
    ) {
        self.frontUrl = frontUrl
        self.sideUrl = sideUrl
        self.email = email
        self.type = type
        self.scanId = scanId
        self.source = source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        let values = container.allKeys.reduce(into: [String: ScanJSONValue]()) { partialResult, key in
            partialResult[key.stringValue] = (try? container.decode(ScanJSONValue.self, forKey: key)) ?? .null
        }

        frontUrl = Self.string(for: ["frontUrl", "frontURL", "front_url", "frontImageUrl"], in: values)
        sideUrl = Self.string(for: ["sideUrl", "sideURL", "side_url", "sideImageUrl"], in: values)
        email = Self.string(for: ["email", "Email"], in: values)
        type = Self.string(for: ["type", "scanType", "access"], in: values)
        scanId = Self.string(for: ["scanId", "scanID", "id"], in: values)
        source = Self.string(for: ["source", "origin"], in: values)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(frontUrl, forKey: .frontUrl)
        try container.encodeIfPresent(sideUrl, forKey: .sideUrl)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(scanId, forKey: .scanId)
        try container.encodeIfPresent(source, forKey: .source)
    }

    var accessLevel: ScanResultsAccess {
        explicitAccessLevel ?? .free
    }

    var explicitAccessLevel: ScanResultsAccess? {
        let normalized = type?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""

        guard !normalized.isEmpty else {
            return nil
        }

        if normalized.contains("premium") || normalized.contains("paid") || normalized.contains("pro") {
            return .premium
        }

        if normalized.contains("free") || normalized.contains("basic") || normalized.contains("preview") {
            return .free
        }

        return nil
    }

    private enum CodingKeys: String, CodingKey {
        case frontUrl
        case sideUrl
        case email
        case type
        case scanId
        case source
    }

    private static func string(for keys: [String], in object: [String: ScanJSONValue]) -> String? {
        for key in keys {
            if let value = object[key]?.stringValue {
                return value
            }
        }

        return nil
    }
}

struct ScanPayload: Codable, Hashable, Sendable {
    var scores: ScanScores
    var frontProfile: [String: ScanJSONValue]
    var sideProfile: [String: ScanJSONValue]
    var raw: [String: ScanJSONValue]

    init(
        scores: ScanScores = ScanScores(),
        frontProfile: [String: ScanJSONValue] = [:],
        sideProfile: [String: ScanJSONValue] = [:],
        raw: [String: ScanJSONValue] = [:]
    ) {
        self.scores = scores
        self.frontProfile = frontProfile
        self.sideProfile = sideProfile
        self.raw = raw
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        let rawValues = container.allKeys.reduce(into: [String: ScanJSONValue]()) { partialResult, key in
            partialResult[key.stringValue] = (try? container.decode(ScanJSONValue.self, forKey: key)) ?? .null
        }

        let scoreObject = rawValues["Scores"]?.objectValue
            ?? rawValues["scores"]?.objectValue
            ?? [:]

        self.init(
            scores: ScanScores(object: scoreObject),
            frontProfile: rawValues["front_profile"]?.objectValue
                ?? rawValues["frontProfile"]?.objectValue
                ?? [:],
            sideProfile: rawValues["side_profile"]?.objectValue
                ?? rawValues["sideProfile"]?.objectValue
                ?? [:],
            raw: rawValues
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        var encoded = raw
        encoded["Scores"] = .object(scores.asObject)
        encoded["front_profile"] = .object(frontProfile)
        encoded["side_profile"] = .object(sideProfile)

        for (key, value) in encoded {
            try container.encode(value, forKey: .required(key))
        }
    }
}

struct PersistedScanRecord: Codable, Hashable, Sendable {
    var payload: ScanPayload
    var meta: ScanResultMeta
    var savedAt: Date?

    var accessLevel: ScanResultsAccess {
        if let explicitAccessLevel = meta.explicitAccessLevel {
            return explicitAccessLevel
        }

        if payload.scores.jaw != nil || payload.scores.side != nil {
            return .premium
        }

        return .free
    }

    var pageSequence: [ScanResultsPageID] {
        switch accessLevel {
        case .free:
            [.overview, .placement, .harmony, .eyes, .lips, .premiumPush, .done]
        case .premium:
            [.overview, .placement, .harmony, .eyes, .lips, .jaw, .sideProfile, .done]
        }
    }

    var overallScore: Double {
        payload.scores.overall ?? payload.scores.potential ?? 72
    }

    var potentialScore: Double {
        payload.scores.potential ?? min(overallScore + 6, 96)
    }

    var percentile: Int {
        max(4, 32 - Int(max(overallScore - 56, 0) * 0.62))
    }

    var tierTitle: String {
        switch overallScore {
        case ..<62:
            "Foundation"
        case ..<70:
            "Ascent"
        case ..<80:
            "Prime"
        default:
            "Sovereign"
        }
    }

    var headline: String {
        switch overallScore {
        case ..<62:
            "The base structure is in place. AIScend sees clear room for visible movement."
        case ..<70:
            "Presentation is already reading stronger. The next gains come from cleaner precision."
        case ..<80:
            "This is a strong read with real upside. Small refinements now compound faster."
        default:
            "The scan is landing in premium territory. The value now is in sharpening the high-leverage details."
        }
    }

    var placementNarrative: String {
        "AIScend places this scan above roughly \(100 - percentile)% of comparable reads in the current band."
    }

    var isDisplayable: Bool {
        overallScore > 0
        || payload.scores.potential != nil
        || !payload.frontProfile.isEmpty
        || !payload.sideProfile.isEmpty
    }

    var isFreshScanCandidate: Bool {
        (meta.source?.lowercased() == "scan-flow")
        && (meta.scanId?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    var saveFingerprint: String {
        [
            meta.frontUrl ?? "",
            meta.sideUrl ?? "",
            meta.email ?? "",
            meta.type ?? "",
            String(format: "%.1f", overallScore)
        ].joined(separator: "|")
    }

    var archiveFingerprint: String {
        [
            meta.frontUrl?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            meta.sideUrl?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            meta.email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? "",
            meta.type?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? "",
            String(format: "%.1f", overallScore)
        ].joined(separator: "|")
    }

    static let previewFree = PersistedScanRecord(
        payload: ScanPayload(
            scores: ScanScores(overall: 71, potential: 83, eyes: 74, skin: 68, jaw: 79, side: 76),
            frontProfile: [
                "facial_harmony": .object([
                    "score": .number(72),
                    "description": .string("Overall balance is clean, with the lower third already reading more structured than average.")
                ]),
                "eye_spacing": .object([
                    "value": .string("Balanced"),
                    "description": .string("Spacing reads calm and proportionate, which helps the face feel more composed.")
                ]),
                "brow_frame": .object([
                    "value": .string("Strong"),
                    "description": .string("The brow line frames the eyes well and supports a sharper first read.")
                ]),
                "upper_lip_definition": .object([
                    "value": .string("Developing"),
                    "description": .string("Definition is present but still benefits from hydration and cleaner edge contrast.")
                ]),
                "lip_balance": .object([
                    "value": .string("Balanced"),
                    "description": .string("The mouth area reads proportionate, which keeps the center face calm.")
                ]),
                "canthal_tilt": .object([
                    "value": .string("Locked"),
                    "description": .string("Unlock premium to see the full eye-area read and improvement guidance.")
                ]),
                "orbital_support": .object([
                    "value": .string("Locked"),
                    "description": .string("Premium reveals deeper structure commentary and more detailed coaching.")
                ])
            ],
            sideProfile: [
                "profile_projection": .object([
                    "value": .string("Balanced"),
                    "description": .string("Profile projection is solid, with premium detail available for the full side read.")
                ])
            ]
        ),
        meta: ScanResultMeta(
            frontUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
            sideUrl: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d",
            email: "max@aiscend.app",
            type: "free",
            scanId: nil,
            source: "scan-flow"
        ),
        savedAt: .now
    )

    static let previewPremium = PersistedScanRecord(
        payload: ScanPayload(
            scores: ScanScores(overall: 78, potential: 89, eyes: 80, skin: 74, jaw: 82, side: 81),
            frontProfile: [
                "facial_harmony": .object([
                    "score": .number(79),
                    "description": .string("Feature balance is notably coherent. The scan reads structured and controlled.")
                ]),
                "symmetry_read": .object([
                    "value": .string("Strong"),
                    "description": .string("Symmetry is contributing to a cleaner global read and better first-impression stability.")
                ]),
                "eye_spacing": .object([
                    "value": .string("Strong"),
                    "description": .string("Spacing is working for you and helps the eyes read alert without strain.")
                ]),
                "brow_frame": .object([
                    "value": .string("Strong"),
                    "description": .string("Brows currently amplify eye presence and create stronger upper-face definition.")
                ]),
                "lip_balance": .object([
                    "value": .string("Balanced"),
                    "description": .string("Lip proportion is stable, keeping the center face composed.")
                ]),
                "jaw_definition": .object([
                    "value": .string("Strong"),
                    "description": .string("The lower third reads more deliberate and more masculine than average.")
                ]),
                "chin_support": .object([
                    "value": .string("Balanced"),
                    "description": .string("Chin support is adequate and does not break the profile line.")
                ])
            ],
            sideProfile: [
                "nose_projection": .object([
                    "value": .string("Balanced"),
                    "description": .string("Projection is proportionate and sits cleanly inside the profile line.")
                ]),
                "facial_convexity": .object([
                    "value": .string("Controlled"),
                    "description": .string("Overall convexity is reading composed, which strengthens side presentation.")
                ]),
                "neckline_posture": .object([
                    "value": .string("Strong"),
                    "description": .string("Posture is helping the profile read sharper and more athletic.")
                ])
            ]
        ),
        meta: ScanResultMeta(
            frontUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
            sideUrl: "https://images.unsplash.com/photo-1492562080023-ab3db95bfbce",
            email: "premium@aiscend.app",
            type: "premium",
            scanId: "archived-premium-scan",
            source: "history"
        ),
        savedAt: .now
    )
}

enum ScanResultsAccess: String, Codable, Hashable, Sendable {
    case free
    case premium
}

enum ScanResultsPageID: String, CaseIterable, Identifiable, Hashable, Sendable {
    case overview
    case placement
    case harmony
    case eyes
    case lips
    case jaw
    case sideProfile
    case premiumPush
    case done

    var id: String { rawValue }
}

struct ScanTraitRowModel: Identifiable, Hashable, Sendable {
    let id: String
    let label: String
    let value: String
    let explanation: String
    let locked: Bool
}

enum ScanAutoSaveState: Equatable, Sendable {
    case idle
    case skipped
    case syncing
    case saved(String)
    case localOnly
    case failed(String)

    var statusLine: String? {
        switch self {
        case .idle, .skipped:
            nil
        case .syncing:
            "Saving scan to your archive"
        case .saved:
            "Saved to your archive"
        case .localOnly:
            "Stored on this device"
        case .failed(let message):
            message
        }
    }
}

struct ScanAutoSaveResult: Sendable {
    let result: PersistedScanRecord
    let state: ScanAutoSaveState
}

struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        return nil
    }

    static func required(_ value: String) -> DynamicCodingKey {
        guard let key = DynamicCodingKey(stringValue: value) else {
            preconditionFailure("Unable to create coding key for \(value)")
        }

        return key
    }
}

extension ScanScores {
    var asObject: [String: ScanJSONValue] {
        var object: [String: ScanJSONValue] = [:]

        if let overall {
            object["overall"] = .number(overall)
        }

        if let potential {
            object["potential"] = .number(potential)
        }

        if let eyes {
            object["eyes"] = .number(eyes)
        }

        if let skin {
            object["Skin"] = .number(skin)
        }

        if let jaw {
            object["jaw"] = .number(jaw)
        }

        if let side {
            object["Side"] = .number(side)
        }

        return object
    }
}

extension PersistedScanRecord {
    static func normalizedLabel(for rawKey: String) -> String {
        rawKey
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: ".", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .map { chunk in
                let lower = chunk.lowercased()
                switch lower {
                case "jaw":
                    return "Jaw"
                case "lips":
                    return "Lips"
                case "eye", "eyes":
                    return "Eyes"
                case "brow", "brows":
                    return "Brows"
                default:
                    return lower.capitalized
                }
            }
            .joined(separator: " ")
    }
}
