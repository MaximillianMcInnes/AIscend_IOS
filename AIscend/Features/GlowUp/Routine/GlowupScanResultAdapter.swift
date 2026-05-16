//
//  GlowupScanResultAdapter.swift
//  AIscend
//

import Foundation

func buildGlowupInputFromScanResult(scanResult: PersistedScanRecord) -> GlowupRoutineInput {
    GlowupScanResultAdapter(scanResult: scanResult).build()
}

private struct GlowupScanResultAdapter {
    let scanResult: PersistedScanRecord

    func build() -> GlowupRoutineInput {
        let overallLabel = ScanJSONValue.formatted(number: scanResult.overallScore.rounded())
        let potentialLabel = ScanJSONValue.formatted(number: scanResult.potentialScore.rounded())
        let summary = "Built from this scan's \(overallLabel) overall read and \(potentialLabel) potential read."

        return GlowupRoutineInput(
            scanId: scanResult.meta.scanId?.trimmedNonEmpty,
            source: "scan_results",
            fingerprint: scanResult.saveFingerprint,
            overallScore: scanResult.overallScore,
            potentialScore: scanResult.potentialScore,
            generatedFromSummary: summary,
            sections: [
                furtherRecommendations(),
                eyebrowRecommendations(),
                jawAreaRecommendationsSimple(),
                lipRecommendations(),
                sideProfileGlowUpCard(),
                skinCareRecommendations(),
                generalRecommendations()
            ]
        )
    }

    private func furtherRecommendations() -> GlowupRoutineSection {
        let signals = signals(
            matching: ["harmony", "symmetry", "balance", "proportion", "ratio", "hair", "forehead", "third"],
            fallbackLabels: ["Overall score", "Potential score"]
        )

        return buildHaircutSection(
            signals: signals,
            snapshotChips: chips(from: signals),
            personalisedTips: tips(from: signals, fallback: "Anchor haircut changes to the strongest returned harmony signal, then rescan before changing direction.")
        )
    }

    private func buildHaircutSection(
        signals: [GlowupScanSignal],
        snapshotChips: [String],
        personalisedTips: [String]
    ) -> GlowupRoutineSection {
        let primarySignal = signals.first.map { "\($0.label.lowercased()) signal (\($0.value))" } ?? "available facial balance read"
        let matchedActions = [
            "Use the \(primarySignal) as the haircut anchor instead of a generic face-shape preset.",
            "Ask for controlled side volume and a cleaner perimeter so the upper face reads intentional.",
            "Bring 2-3 reference photos with similar hair density and texture, then compare in matched lighting before changing length again."
        ]
        let stylingActions = [
            "Style with direction rather than extra width: towel-dry, set the part or push-back, then use a small amount of matte product.",
            "Keep enough top length to support the strongest harmony or proportion read without fully hiding the forehead.",
            "If the sides expand during the day, use less product there and ask for tighter taper control next cut."
        ]
        let productActions = [
            "Wash and condition on a steady schedule that keeps the hair clean without stripping it.",
            "Use lightweight, low-irritation products and avoid heavy buildup around the hairline.",
            "Track scalp dryness, itch, flatness, or oiliness before adding another styling product."
        ]
        let goals = [
            GlowupGoalSubSection(
                title: "Haircut matched to your face",
                goal: "Choose a cut that balances the scan-returned proportions and facial framing signals.",
                actions: matchedActions,
                personalisedTips: Array(personalisedTips.prefix(1))
            ),
            GlowupGoalSubSection(
                title: "Style your hair accordingly",
                goal: "Use styling that reinforces the cut and enhances visible structure.",
                actions: stylingActions,
                personalisedTips: signals.first.map { ["Watch whether the \($0.label.lowercased()) read improves after the next scan."] } ?? []
            ),
            GlowupGoalSubSection(
                title: "Use natural products for hair",
                goal: "Keep hair healthy and consistent with simple, low-irritation product habits.",
                actions: productActions,
                personalisedTips: Array(personalisedTips.dropFirst().prefix(2))
            )
        ]

        return GlowupRoutineSection(
            key: .haircut,
            title: "Haircut & Harmony",
            goal: "Use haircut shape and grooming contrast to support the scan's harmony and proportion signals.",
            summary: "Use the haircut as a framing tool around \(primarySignal), without pretending the scan returned a fixed face-shape label.",
            goals: goals,
            observedSignals: signals,
            actions: goals.flatMap(\.actions),
            personalisedTips: personalisedTips,
            snapshotChips: snapshotChips,
            avoid: [
                "Do not choose a cut from a generic face-shape preset if this scan did not return that value.",
                "Avoid extreme bulk changes until the next scan confirms the framing is helping."
            ],
            symbol: "scissors",
            accent: .sky
        )
    }

    private func eyebrowRecommendations() -> GlowupRoutineSection {
        let signals = signals(
            matching: ["brow", "eyebrow", "eye", "canthal", "orbital", "lid"],
            fallbackLabels: ["Eye score"]
        )

        return buildEyebrowSection(
            signals: signals,
            snapshotChips: chips(from: signals),
            personalisedTips: tips(from: signals, fallback: "Make small brow edits and compare them against the exact eye-area signal shown here.")
        )
    }

    private func buildEyebrowSection(
        signals: [GlowupScanSignal],
        snapshotChips: [String],
        personalisedTips: [String]
    ) -> GlowupRoutineSection {
        let primarySignal = signals.first.map { "\($0.label.lowercased()) (\($0.value))" } ?? "eye-area snapshot"
        let shapeActions = [
            "Use the \(primarySignal) as the brow baseline, then tidy only obvious stray hairs under the natural line.",
            "Brush brows upward before trimming so length changes stay small and symmetrical.",
            "Preserve density through the middle and tail unless the scan clearly shows the area reads too heavy."
        ]
        let liftActions = [
            "Set the brow tail slightly up and outward with clear gel to improve the lift impression without forcing a new shape.",
            "Keep inner starts soft and balanced so the eye-area spacing reads clean rather than harsh.",
            "Recheck under neutral lighting before removing more hair; small direction changes usually show faster than plucking."
        ]
        let dailyActions = [
            "Spend 2-3 minutes brushing, setting, and checking both brows in the same mirror light.",
            "Use a cold rinse or simple caffeine eye product only if puffiness is part of your eye-area read.",
            "Take one matched-light photo after grooming so the next scan has a fair comparison."
        ]
        let goals = [
            GlowupGoalSubSection(
                title: "Shape & flow",
                goal: "Build clean structure without thinning the brows or changing expression dramatically.",
                actions: shapeActions,
                personalisedTips: Array(personalisedTips.prefix(1))
            ),
            GlowupGoalSubSection(
                title: "Lift & spacing illusion",
                goal: "Use brow direction and inner-start softness to improve framing from the scan's eye-area fields.",
                actions: liftActions,
                personalisedTips: signals.first.map { ["Compare this against the returned \($0.label.lowercased()) value on your next scan."] } ?? []
            ),
            GlowupGoalSubSection(
                title: "Daily 2-3 minute routine",
                goal: "Make the eye-area routine repeatable so the next scan reflects consistent grooming, not random changes.",
                actions: dailyActions,
                personalisedTips: Array(personalisedTips.dropFirst().prefix(2))
            )
        ]

        return GlowupRoutineSection(
            key: .eyebrow,
            title: "Eyebrows & Eye Area",
            goal: "Sharpen the upper-face frame while preserving the scan's natural eye-area balance.",
            summary: "The brow plan is based on the scan's eye-area fields, with restraint so the expression stays natural.",
            goals: goals,
            observedSignals: signals,
            actions: goals.flatMap(\.actions),
            personalisedTips: personalisedTips,
            snapshotChips: snapshotChips,
            avoid: [
                "Avoid over-thinning the brow, especially when the scan already reads the upper face as balanced.",
                "Do not force a dramatic arch from a single scan."
            ],
            symbol: "eye.fill",
            accent: .mint
        )
    }

    private func jawAreaRecommendationsSimple() -> GlowupRoutineSection {
        let signals = signals(
            matching: ["jaw", "chin", "mandible", "lower", "gonial", "hollow", "neckline", "posture"],
            fallbackLabels: ["Jaw score", "Overall score"]
        )
        let jawText = signals.map { "\($0.label) \($0.value)" }.joined(separator: " ").lowercased()
        var personalisedTips: [String] = []

        if jawText.contains("short") {
            personalisedTips.append("If chin reads short, keep the beard neckline slightly lower to lengthen the lower third visually.")
        } else if jawText.contains("narrow") {
            personalisedTips.append("If jaw width reads narrow, short boxed stubble can add stronger side framing.")
        } else if jawText.contains("round") {
            personalisedTips.append("If chin reads round, keep beard lines straighter at the chin apex instead of rounding them.")
        } else if jawText.contains("wide") {
            personalisedTips.append("If chin reads wide, keep the point tidy so it does not look heavy or bulbous.")
        }

        if jawText.contains("soft") || jawText.contains("blur") {
            personalisedTips.append("If jawline looks soft, prioritize sleep, hydration, and a consistent neckline first because those show fastest.")
        } else if jawText.contains("hollow") {
            personalisedTips.append("If cheeks read hollow, avoid pushing leanness too hard so the face does not look gaunt.")
        }

        personalisedTips.append(contentsOf: tips(
            from: signals,
            fallback: "Baseline: consistent neckline, posture, and matched lighting will show the fastest change in photos."
        ))
        personalisedTips = uniqueStrings(personalisedTips).prefixArray(3)

        let postureActions = [
            "Mewing cue: tongue fully on palate, lips closed, nasal breathing. Use light pressure, not force.",
            "Posture: stack ears over shoulders and do gentle chin-tuck reps 2x/day for 10 reps.",
            "Nasal breathing check-in 3x/day: lips sealed, tongue up, jaw relaxed."
        ]
        let chewingActions = [
            "Chew firm gum for 10 minutes once per day. Stop if you get pain, clicking, locking, or headaches.",
            "Eat harder foods sometimes, like apples, carrots, or lean meat, and chew evenly on both sides.",
            "Alternate chewing sides every minute when doing deliberate chewing work to reduce asymmetry."
        ]
        let groomingActions = [
            "Keep the neckline 1-2 finger widths above the Adam's apple; do not set it too high.",
            "De-bloat basics: hydrate, moderate sodium at night, and keep sleep consistent so the jaw edge shows.",
            "Keep facial hair edges crisp every 5-7 days and match both sides carefully.",
            "For photos, use top-front lighting and a slight chin tuck so definition shows accurately."
        ]
        let goals = [
            GlowupGoalSubSection(
                title: "Posture and mewing",
                goal: "Improve how the jawline presents through relaxed tongue posture, nasal breathing, and stacked alignment.",
                actions: postureActions,
                personalisedTips: ["Aim for relaxed tongue posture. If it hurts, reduce pressure."]
            ),
            GlowupGoalSubSection(
                title: "Chewing and diet",
                goal: "Use safe, low-dose chewing and harder-food habits without aggravating the jaw.",
                actions: chewingActions,
                personalisedTips: ["Hard chewing is not for everyone. If your jaw clicks or hurts, stop and reduce intensity."]
            ),
            GlowupGoalSubSection(
                title: "Grooming and definition",
                goal: "Make the lower face easier to read with clean edges, symmetry, and unobstructed photos.",
                actions: groomingActions,
                personalisedTips: personalisedTips
            )
        ]

        return GlowupRoutineSection(
            key: .jaw,
            title: "Jaw - Quick Wins",
            goal: "Improve the lower-face read through posture, grooming edges, recovery, and clearer cheek/jaw visibility.",
            summary: "Jaw work is saved as three practical goals: posture and mewing cues, safe chewing habits, and grooming definition.",
            goals: goals,
            observedSignals: signals,
            actions: goals.flatMap(\.actions),
            personalisedTips: personalisedTips,
            snapshotChips: uniqueStrings(chips(from: signals) + ["Fastest win: neckline + posture", "Daily dose: 5-10 min"]),
            avoid: [
                "Avoid claims or routines promising bone growth or permanent jaw structure changes.",
                "Stop any exercise that causes pain, clicking, locking, dizziness, or headaches."
            ],
            symbol: "triangle.bottomhalf.filled",
            accent: .dawn
        )
    }

    private func lipRecommendations() -> GlowupRoutineSection {
        let signals = signals(
            matching: ["lip", "mouth", "philtrum", "smile", "cupid", "fullness", "color", "colour"],
            fallbackLabels: ["Lip context", "Overall score"]
        )
        let personalisedTips = uniqueStrings([
            "Day: use SPF lip balm outdoors and reapply after eating or drinking.",
            "Night: use a thicker occlusive layer and avoid lip-licking because it dries the lips out."
        ] + tips(from: signals, fallback: "Hydrated, sealed, reflective lips look fuller fastest."))
        .prefixArray(3)

        let hydrationActions = [
            "AM: apply hyaluronic acid or a simple hydrating serum on damp lips.",
            "Immediately seal with petrolatum or an occlusive balm to lock water in.",
            "Reapply after eating or drinking if lips feel dry or tight."
        ]
        let edgeActions = [
            "2-3x/week max: use a soft toothbrush or mild scrub for 10-15 seconds.",
            "Exfoliate at night, then immediately seal with balm. No acids needed.",
            "Never exfoliate cracked lips. Heal first, then restart."
        ]
        let expressionActions = [
            "Day: use SPF lip balm outdoors and reapply every 2 hours when in sun or wind.",
            "Use a thin glossy or occlusive layer for reflectivity and an instant fullness effect.",
            "Before photos: hydrate, seal, then dab excess so it looks natural rather than greasy."
        ]
        let goals = [
            GlowupGoalSubSection(
                title: "Hydrate and seal daily",
                goal: "Build a stronger lip barrier so lips stay smoother, fuller-looking, and comfortable.",
                actions: hydrationActions,
                personalisedTips: ["If irritation happens, simplify to occlusive balm only for 3-5 days."]
            ),
            GlowupGoalSubSection(
                title: "Gentle exfoliation",
                goal: "Remove flaky texture without triggering irritation.",
                actions: edgeActions,
                personalisedTips: ["Over-exfoliation is the main reason lips look worse. Less wins."]
            ),
            GlowupGoalSubSection(
                title: "Protect and enhance",
                goal: "Preserve lip definition and boost reflectivity for a fast fuller look.",
                actions: expressionActions,
                personalisedTips: personalisedTips
            )
        ]

        return GlowupRoutineSection(
            key: .lip,
            title: "Lip Fullness Guide",
            goal: "Keep the mouth area hydrated, sealed, protected, and more reflective for a fast non-surgical upgrade.",
            summary: "The lip section now saves the hydrate-and-seal routine, gentle exfoliation limits, and SPF/gloss payoff stack.",
            goals: goals,
            observedSignals: signals,
            actions: goals.flatMap(\.actions),
            personalisedTips: personalisedTips,
            snapshotChips: uniqueStrings(chips(from: signals) + ["Fastest win: gloss/occlusion", "Main driver: barrier health", "Protect: SPF balm", "Cadence: AM + PM"]),
            avoid: [
                "Avoid aggressive exfoliation, especially on cracked or irritated lips.",
                "Avoid lip-licking because it increases dryness and can make lips look smaller.",
                "Do not infer filler-style changes from a scan that only reports visual proportion."
            ],
            symbol: "mouth.fill",
            accent: .sky
        )
    }

    private func sideProfileGlowUpCard() -> GlowupRoutineSection {
        let signals = signals(
            matching: ["side", "profile", "projection", "nose", "convexity", "chin", "neckline", "ramus", "gonial"],
            fallbackLabels: ["Side profile score", "Potential score"]
        )

        return buildSideProfileSection(
            signals: signals,
            snapshotChips: chips(from: signals),
            personalisedTips: tips(from: signals, fallback: "Keep side-profile comparisons strict: same lens height, same distance, same relaxed jaw.")
        )
    }

    private func buildSideProfileSection(
        signals: [GlowupScanSignal],
        snapshotChips: [String],
        personalisedTips: [String]
    ) -> GlowupRoutineSection {
        let sideText = signals.map { "\($0.label) \($0.value)" }.joined(separator: " ").lowercased()
        var tailoredTips: [String] = []

        if sideText.contains("short") {
            tailoredTips.append("Posture stack: ears over shoulders plus gentle chin-tuck reps 2-3x/day.")
        }
        if sideText.contains("maxilla") || sideText.contains("low") || sideText.contains("convex") {
            tailoredTips.append("Use full-tongue contact on the palate and nasal breathing cues as posture anchors.")
        }
        if sideText.contains("recess") || sideText.contains("retrud") {
            tailoredTips.append("Turn 10-15 degrees and raise the camera slightly for a stronger forward read.")
        }
        if sideText.contains("soft") || sideText.contains("blur") {
            tailoredTips.append("Day-before photos: hydrate well and lower evening salt to reduce puffiness.")
        }
        if sideText.contains("overbite") {
            tailoredTips.append("Relax lips and keep the camera just above eye line to avoid upper-lip strain.")
        }
        if sideText.contains("underbite") {
            tailoredTips.append("Avoid ultra-low angles and use soft top-front lighting.")
        }

        let resolvedTips = uniqueStrings(tailoredTips + personalisedTips + [
            "Maintain clean borders: neckline tidy and consistent lighting for definition."
        ])
        .prefixArray(3)

        let cameraActions = [
            "Use raised top-front light, ideally window light slightly above eye line.",
            "Try a 3/4 angle with a 10-15 degree turn to reduce flatness.",
            "Keep the camera slightly above eye line rather than low angle."
        ]
        let postureActions = [
            "Use a long neck and small chin tuck for a cleaner jaw edge.",
            "Practice tall neck posture and relaxed jaw position before photos.",
            "Keep the jaw relaxed; do not clench or force a forward position for the scan."
        ]
        let groomingActions = [
            "Keep the neckline crisp: 1-2 fingers above the Adam's apple and trim every 5-7 days.",
            "Keep collar, hair, and beard edges from hiding the neck and chin line.",
            "Use clean sideburn and neckline edges if facial hair is part of the profile frame."
        ]

        return GlowupRoutineSection(
            key: .side,
            title: "Side Profile (Non-Surgical)",
            goal: "Make the profile read stronger through lighting, camera technique, neck posture, and clean grooming edges.",
            summary: "This side-profile section turns the scan into camera, posture, and framing actions that can change the visual read fast.",
            goals: [
                GlowupGoalSubSection(
                    title: "Camera cheat codes",
                    goal: "Keep every side-profile check comparable so the routine responds to the scan, not camera drift.",
                    actions: cameraActions,
                    personalisedTips: Array(resolvedTips.prefix(1))
                ),
                GlowupGoalSubSection(
                    title: "Posture reset",
                    goal: "Use relaxed alignment cues that improve the visual read without making structural claims.",
                    actions: postureActions,
                    personalisedTips: signals.first.map { ["Watch the returned \($0.label.lowercased()) signal when comparing side photos."] } ?? []
                ),
                GlowupGoalSubSection(
                    title: "Profile framing",
                    goal: "Keep hair, collar, and grooming edges from obscuring the side-profile lines.",
                    actions: groomingActions,
                    personalisedTips: Array(resolvedTips.dropFirst().prefix(2))
                )
            ],
            observedSignals: signals,
            actions: cameraActions + postureActions + groomingActions,
            personalisedTips: resolvedTips,
            snapshotChips: uniqueStrings(snapshotChips + ["Fastest win: posture + lighting", "Today: 2 min setup"]),
            avoid: [
                "Avoid judging progress from a single low-angle side photo.",
                "Avoid ultra-low camera angles when checking profile progress.",
                "Do not treat posture cues as a medical or orthodontic fix."
            ],
            symbol: "person.crop.rectangle.stack.fill",
            accent: .mint
        )
    }

    private func skinCareRecommendations() -> GlowupRoutineSection {
        let signals = signals(
            matching: ["skin", "acne", "texture", "clarity", "oil", "redness", "pore", "features"],
            fallbackLabels: ["Skin score"]
        )
        let skinText = signals.map { "\($0.label) \($0.value)" }.joined(separator: " ").lowercased()
        var personalisedTips = ["SPF daily is non-negotiable for clarity and anti-aging."]

        if skinText.contains("red") || skinText.contains("rosacea") {
            personalisedTips.append("Use azelaic on non-retinal nights to help calm visible redness.")
        }
        if skinText.contains("wrinkle") || skinText.contains("aging") || skinText.contains("ageing") {
            personalisedTips.append("Vitamin C in the morning plus retinal at night is the best long-term combo.")
        }
        if skinText.contains("eye") || skinText.contains("dark circle") {
            personalisedTips.append("Use caffeine eye serum in the morning and sleep slightly elevated.")
        }
        if skinText.contains("sensitive") || skinText.contains("irritation") {
            personalisedTips.append("Buffer retinal with moisturiser and ramp slowly.")
        }
        if skinText.contains("pigment") || skinText.contains("dark spot") || skinText.contains("melasma") {
            personalisedTips.append("Prioritise SPF plus Vitamin C; azelaic can help with dark spots.")
        }
        personalisedTips.append(contentsOf: tips(from: signals, fallback: "Patch test new actives and stop if irritated."))
        personalisedTips = uniqueStrings(personalisedTips).prefixArray(3)

        return buildSkinSection(
            signals: signals,
            snapshotChips: uniqueStrings(chips(from: signals) + ["Core: SPF daily", "Retinal: start 2x/week", "Rule: do not stack actives"]),
            amRoutine: (
                actions: [
                    "AM: cleanse gently, then use Vitamin C if tolerated.",
                    "Apply lightweight moisturiser, then broad-spectrum SPF 50+ as the last step.",
                    "Use caffeine eye serum if puffiness or darkness is part of your scan read."
                ],
                personalisedTips: Array(personalisedTips.prefix(1))
            ),
            pmRoutine: (
                actions: [
                    "PM: cleanse, then use retinal 0.05% treatment 2x/week to start.",
                    "Follow with barrier repair cream so the skin does not get tight or reactive.",
                    "Track new products for two weeks before judging whether the scan response improved."
                ],
                personalisedTips: Array(personalisedTips.dropFirst().prefix(1))
            ),
            weeklyBoosters: (
                actions: [
                    "Use azelaic acid 2-4x/week depending on sensitivity, especially for redness or tone.",
                    "Use gentle PHA or lactic exfoliant 1-2x/week on non-retinal nights.",
                    "Use a hydrating mask when skin feels tight, dry, or overworked."
                ],
                personalisedTips: Array(personalisedTips.dropFirst(2).prefix(1))
            )
        )
    }

    private func buildSkinSection(
        signals: [GlowupScanSignal],
        snapshotChips: [String],
        amRoutine: (actions: [String], personalisedTips: [String]),
        pmRoutine: (actions: [String], personalisedTips: [String]),
        weeklyBoosters: (actions: [String], personalisedTips: [String])
    ) -> GlowupRoutineSection {
        let goals = [
            GlowupGoalSubSection(
                title: "AM routine",
                goal: "Protect, brighten, and maintain skin clarity through a simple morning routine.",
                actions: amRoutine.actions,
                personalisedTips: amRoutine.personalisedTips
            ),
            GlowupGoalSubSection(
                title: "PM routine",
                goal: "Repair the skin barrier and gradually improve texture, clarity, and tone.",
                actions: pmRoutine.actions,
                personalisedTips: pmRoutine.personalisedTips
            ),
            GlowupGoalSubSection(
                title: "Weekly boosters",
                goal: "Use optional treatments carefully without irritating the skin barrier.",
                actions: weeklyBoosters.actions,
                personalisedTips: weeklyBoosters.personalisedTips
            )
        ]

        return GlowupRoutineSection(
            key: .skin,
            title: "Skin Routine",
            goal: "Support texture, clarity, barrier consistency, and glow using the skin fields returned by the scan.",
            summary: "Skin now saves an AM protect-and-brighten routine, a PM repair-and-renew routine, and optional weekly boosters.",
            goals: goals,
            observedSignals: signals,
            actions: goals.flatMap(\.actions),
            personalisedTips: goals.flatMap(\.personalisedTips),
            snapshotChips: snapshotChips,
            avoid: [
                "Avoid exfoliants on the same night as retinal.",
                "If irritation happens, reduce frequency first, then simplify.",
                "Patch test new actives, especially retinal and acids.",
                "See a clinician for painful, severe, or persistent skin concerns."
            ],
            symbol: "drop.fill",
            accent: .mint
        )
    }

    private func generalRecommendations() -> GlowupRoutineSection {
        let signals = signals(
            matching: ["overall", "potential", "harmony", "symmetry", "balance", "skin", "jaw", "eye", "lip"],
            fallbackLabels: ["Overall score", "Potential score"]
        )
        let personalisedTips = tips(from: signals, fallback: "Use the scan as a feedback loop, not a verdict. Adjust one variable at a time.")
        let photoActions = [
            "Take the next comparison photo with the same lighting, distance, lens height, and expression.",
            "Save one front and one side reference so future scans are judged against consistent evidence.",
            "Ask the AI advisor to explain any scan field before making a bigger change."
        ]
        let movementActions = [
            "Do 30 minutes of easy cardio 3-5 times per week or use a step goal that fits your current baseline.",
            "Add short mobility sessions for shoulders, neck, and upper back so posture reads cleaner.",
            "Keep the routine repeatable; consistency matters more than a single intense day."
        ]
        let nutritionActions = [
            "Build meals around protein, fruit or vegetables, training carbs, and healthy fats.",
            "Keep water and salt intake consistent so puffiness changes are easier to interpret.",
            "Plan treats instead of letting random snacks drive day-to-day energy and skin changes."
        ]
        let sleepActions = [
            "Aim for a stable sleep and wake time that supports skin, mood, and training recovery.",
            "Dim screens before bed when possible and get daylight soon after waking.",
            "Track whether poor sleep affects the next scan before changing multiple routine variables."
        ]
        let goals = [
            GlowupGoalSubSection(
                title: "Scan feedback loop",
                goal: "Make every scan comparable so the routine can update from real changes.",
                actions: photoActions,
                personalisedTips: Array(personalisedTips.prefix(1))
            ),
            GlowupGoalSubSection(
                title: "Cardio & daily movement",
                goal: "Improve fitness, posture, energy, and overall presentation through consistency.",
                actions: movementActions,
                personalisedTips: []
            ),
            GlowupGoalSubSection(
                title: "Protein, hydration & low-bloat habits",
                goal: "Support recovery and a fresher look while keeping day-to-day variables stable.",
                actions: nutritionActions,
                personalisedTips: signals.first.map { ["Watch how the \($0.label.lowercased()) signal responds after two consistent weeks."] } ?? []
            ),
            GlowupGoalSubSection(
                title: "Sleep & recovery",
                goal: "Support skin, mood, training recovery, and day-to-day performance.",
                actions: sleepActions,
                personalisedTips: Array(personalisedTips.dropFirst().prefix(2))
            )
        ]

        return GlowupRoutineSection(
            key: .general,
            title: "General",
            goal: "Turn the scan into a repeatable weekly loop: one grooming move, one recovery move, one honest check-in.",
            summary: "The routine stays tied to the scan without overreaching beyond what the JSON actually contains.",
            goals: goals,
            observedSignals: signals,
            actions: goals.flatMap(\.actions),
            personalisedTips: personalisedTips,
            snapshotChips: chips(from: signals),
            avoid: [
                "Avoid chasing every section at once.",
                "Do not treat appearance scoring as medical diagnosis or permanent identity."
            ],
            symbol: "sparkles.rectangle.stack.fill",
            accent: .dawn
        )
    }

    private func signals(matching keywords: [String], fallbackLabels: [String]) -> [GlowupScanSignal] {
        let matched = flattenedSignals()
            .filter { signal in
                let searchable = "\(signal.id) \(signal.label)".lowercased()
                return keywords.contains(where: { searchable.contains($0) })
            }

        let deduped = deduplicated(matched)
        if !deduped.isEmpty {
            return Array(deduped.prefix(4))
        }

        return fallbackSignals(labels: fallbackLabels)
    }

    private func flattenedSignals() -> [GlowupScanSignal] {
        var values: [String: ScanJSONValue] = scanResult.payload.raw
        values["front_profile"] = .object(scanResult.payload.frontProfile)
        values["side_profile"] = .object(scanResult.payload.sideProfile)
        values["scores"] = .object(scanResult.payload.scores.asObject)

        return flatten(values).compactMap { key, value in
            guard let display = value.displayString?.trimmedNonEmpty else {
                return nil
            }

            let object = value.objectValue
            let detail = object?["description"]?.stringValue
                ?? object?["why"]?.stringValue
                ?? object?["notes"]?.stringValue
            return GlowupScanSignal(
                id: key,
                label: PersistedScanRecord.normalizedLabel(for: key.components(separatedBy: ".").last ?? key),
                value: display,
                detail: detail?.trimmedNonEmpty
            )
        }
    }

    private func fallbackSignals(labels: [String]) -> [GlowupScanSignal] {
        labels.compactMap { label in
            switch label {
            case "Overall score":
                return GlowupScanSignal(
                    id: "score.overall",
                    label: label,
                    value: ScanJSONValue.formatted(number: scanResult.overallScore.rounded()),
                    detail: "Used because the scan did not include a more specific field for this section."
                )
            case "Potential score":
                return GlowupScanSignal(
                    id: "score.potential",
                    label: label,
                    value: ScanJSONValue.formatted(number: scanResult.potentialScore.rounded()),
                    detail: "Used as a broad upside signal when the section field is missing."
                )
            case "Eye score":
                return scoreSignal(id: "score.eyes", label: label, value: scanResult.payload.scores.eyes)
            case "Jaw score":
                return scoreSignal(id: "score.jaw", label: label, value: scanResult.payload.scores.jaw)
            case "Side profile score":
                return scoreSignal(id: "score.side", label: label, value: scanResult.payload.scores.side)
            case "Skin score":
                return scoreSignal(id: "score.skin", label: label, value: scanResult.payload.scores.skin)
            default:
                return GlowupScanSignal(
                    id: "fallback.\(label.lowercased().replacingOccurrences(of: " ", with: "-"))",
                    label: label,
                    value: "Unavailable in this scan",
                    detail: "No dedicated scan JSON field was returned for this section."
                )
            }
        }
    }

    private func scoreSignal(id: String, label: String, value: Double?) -> GlowupScanSignal {
        GlowupScanSignal(
            id: id,
            label: label,
            value: value.map { ScanJSONValue.formatted(number: $0.rounded()) } ?? "Unavailable in this scan",
            detail: value == nil ? "No dedicated score was returned for this section." : nil
        )
    }

    private func flatten(_ values: [String: ScanJSONValue], prefix: String = "") -> [(key: String, value: ScanJSONValue)] {
        values.flatMap { key, value in
            let composedKey = prefix.isEmpty ? key : "\(prefix).\(key)"

            if let object = value.objectValue {
                return flatten(object, prefix: composedKey)
            }

            return [(key: composedKey, value: value)]
        }
    }

    private func deduplicated(_ signals: [GlowupScanSignal]) -> [GlowupScanSignal] {
        var seen = Set<String>()
        var unique: [GlowupScanSignal] = []

        for signal in signals {
            let identity = "\(signal.label.lowercased())|\(signal.value.lowercased())"
            guard seen.insert(identity).inserted else {
                continue
            }
            unique.append(signal)
        }

        return unique
    }

    private func tips(from signals: [GlowupScanSignal], fallback: String) -> [String] {
        let detailed = signals.compactMap { signal -> String? in
            guard let detail = signal.detail?.trimmedNonEmpty else {
                return nil
            }

            return "\(signal.label): \(detail)"
        }

        if detailed.isEmpty {
            return [fallback]
        }

        return Array(detailed.prefix(3))
    }

    private func chips(from signals: [GlowupScanSignal]) -> [String] {
        let chips = signals.map { "\($0.label): \($0.value)" }
        return chips.isEmpty ? ["Scan signal unavailable"] : Array(chips.prefix(4))
    }

    private func uniqueStrings(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return nil
            }

            guard seen.insert(trimmed.lowercased()).inserted else {
                return nil
            }

            return trimmed
        }
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension Array {
    func prefixArray(_ maxLength: Int) -> [Element] {
        Array(prefix(maxLength))
    }
}
