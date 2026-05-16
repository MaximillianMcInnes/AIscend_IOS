//
//  ScanPayloadDecodingTests.swift
//  AIscendTests
//
//  Created by Codex on 5/11/26.
//

import Foundation
import Testing
@testable import AIscend

struct ScanPayloadDecodingTests {

    @Test func backendScanPayloadWithSnakeCaseSideProfileDecodesIntoDisplayableRecord() throws {
        let payload = try JSONDecoder().decode(ScanPayload.self, from: Data(Self.backendPayload.utf8))
        let record = PersistedScanRecord(
            payload: payload,
            meta: ScanResultMeta(type: "paid"),
            savedAt: nil
        )

        #expect(payload.scores.overall == 85)
        #expect(payload.scores.potential == 95)
        #expect(payload.scores.skin == 88.5)
        #expect(payload.scores.side == 85)
        #expect(payload.frontProfile["face"]?.objectValue?["face_shape"]?.stringValue == "Square")
        #expect(payload.frontProfile["skin"]?.objectValue?["acne_level"]?.stringValue == "Clear Skin")
        #expect(payload.frontProfile["skin"]?.objectValue?["features"]?.arrayValue?.count == 3)
        #expect(payload.sideProfile["face"]?.objectValue?["chin_projection"]?.stringValue == "Projected")
        #expect(payload.frontProfile["lips"]?.objectValue?["size"]?.stringValue == "top lip too thin")
        #expect(payload.frontProfile["lips"]?.objectValue?["fullness"]?.stringValue == "Thin")
        #expect(record.isDisplayable)
        #expect(record.accessLevel == .premium)
        #expect(record.pageSequence.contains(.sideProfile))
    }

    @Test func backendEnvelopeDataPayloadDecodesLikeWebClientResponse() throws {
        let payload = try JSONDecoder().decode(ScanPayload.self, from: Data(Self.backendEnvelopePayload.utf8))
        let meta = try JSONDecoder().decode(ScanResultMeta.self, from: Data(Self.backendEnvelopePayload.utf8))
        let record = PersistedScanRecord(
            payload: payload,
            meta: meta,
            savedAt: nil
        )

        #expect(payload.scores.overall == 85)
        #expect(payload.scores.side == 85)
        #expect(payload.frontProfile["lips"]?.objectValue?["type"]?.stringValue == "Thin")
        #expect(payload.sideProfile["face"]?.objectValue?["ramus"]?.stringValue == "Tall ramus")
        #expect(meta.email == "maxsasmryt@gmail.com")
        #expect(meta.type == "paid")
        #expect(record.isDisplayable)
        #expect(record.accessLevel == .premium)
    }

    private static let backendEnvelopePayload = """
    {
        "status": "success",
        "uid": "H9jf9coulDOa2Jp6xLId4TvlUOm1",
        "email": "maxsasmryt@gmail.com",
        "subscription": "paid",
        "data": \(backendPayload)
    }
    """

    private static let backendPayload = """
    {
        "Scores": {
            "overall": 85.0,
            "potential": 95.0,
            "eyes": 82.0,
            "jaw": 82.0,
            "side_profile": 85.0,
            "skin": 88.5
        },
        "front_profile": {
            "face": {
                "face_shape": "Square",
                "FWHR": "ideal",
                "width_height": "face too short",
                "cheekbones": "ultra high set",
                "cheekbone_prominence": "prominent",
                "facial_thirds": "forehead too small",
                "facial_symmetry": "Good",
                "philtrum": "too long",
                "nose_width": "Too wide",
                "nose_length": "ideal",
                "nose_symmetry": "asymmetrical",
                "nose_symmetry_score": 0.6066
            },
            "eyes": {
                "eye_spacing": "ideal",
                "type": "hunter",
                "colour": "N/A",
                "eyebrows_colour": "brown",
                "eyebrow_tilt": "negative",
                "eyebrow_setness": "Low",
                "eyebrow_type": "Straight Brows",
                "canthal_tilt": "neutral",
                "eyebrow_symmetry": "Symetical",
                "color": "Green Gray"
            },
            "lips": {
                "cupids_bow": "present",
                "size": "top lip too thin",
                "colour": "Coral Rose",
                "width": "ideal",
                "fullness": "Thin",
                "type": "Thin"
            },
            "jaw_area": {
                "visibility": "normal",
                "chin_length": "ideal",
                "chin_width": "ideal",
                "chin": "too round",
                "jaw_width": "ideal"
            },
            "Phenotype": {
                "eyes": "Green Gray",
                "hair": "Dark Brown"
            }
        },
        "side_profile": {
            "face": {
                "ramus": "Tall ramus",
                "mandible": "neutral",
                "maxilla": "convex",
                "chin_projection": "Projected",
                "gonial_angle": "gonial angle too large",
                "over / under bite": "Balanced",
                "jaw_visibility": "good"
            },
            "nose": {
                "nose_bump": "Present",
                "nose_shape": "Straight",
                "brow_ridge_prominence": "Prominent"
            }
        },
        "ratios": {
            "canthal_tilt": -0.003643173638137493,
            "cheekbone_prominence": 1.6380321732667875,
            "chin_projection": 0.0,
            "gonial_angle": 143.2165696451322
        },
        "sideProfile": {},
        "Acne_level": "Clear Skin",
        "Skin_features": [
            "FOREHEAD WRINKLES",
            "FACE REDNESS",
            "RAZOR BUMPS"
        ]
    }
    """
}
