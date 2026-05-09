//
//  FoodRecognitionPipeline.swift
//  AIscend
//

import CoreGraphics
import Foundation
import UIKit

struct FoodDetectionRegion: Codable, Equatable, Hashable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}

struct DetectedFoodItem: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var category: String
    var confidence: Double
    var estimatedPortion: Double
    var region: FoodDetectionRegion

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        confidence: Double,
        estimatedPortion: Double,
        region: FoodDetectionRegion
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.confidence = confidence
        self.estimatedPortion = estimatedPortion
        self.region = region
    }
}

enum FoodRecognitionSource: String, Codable, CaseIterable {
    case heuristicVision
    case visionFramework
    case coreML
    case openAIImageAnalysis
    case nutritionAPI
    case barcode
    case mealMemory

    var title: String {
        switch self {
        case .heuristicVision:
            return "AIScend Vision"
        case .visionFramework:
            return "Vision"
        case .coreML:
            return "Core ML"
        case .openAIImageAnalysis:
            return "OpenAI"
        case .nutritionAPI:
            return "Nutrition API"
        case .barcode:
            return "Barcode"
        case .mealMemory:
            return "Meal Memory"
        }
    }
}

struct FoodRecognitionOutput {
    var items: [DetectedFoodItem]
    var confidence: Double
    var source: FoodRecognitionSource
    var imageSignature: FoodImageSignature?
}

struct FoodImageSignature: Equatable {
    var brightness: Double
    var saturation: Double
    var warmth: Double
    var aspectRatio: Double
}

protocol FoodImageRecognitionProvider {
    func recognizeFood(in image: UIImage) async throws -> FoodRecognitionOutput?
}

protocol BarcodeMealRecognitionProvider {
    func recognizeBarcodeMeal(from image: UIImage) async throws -> FoodRecognitionOutput?
}

protocol MealMemoryRecognitionProvider {
    func matchRememberedMeal(from image: UIImage) async throws -> FoodRecognitionOutput?
}

struct FoodRecognitionPipeline {
    var visionProvider: FoodImageRecognitionProvider?
    var coreMLProvider: FoodImageRecognitionProvider?
    var openAIProvider: FoodImageRecognitionProvider?
    var barcodeProvider: BarcodeMealRecognitionProvider?
    var mealMemoryProvider: MealMemoryRecognitionProvider?

    func recognizeFood(in image: UIImage?) async throws -> FoodRecognitionOutput {
        if let image {
            if let memory = try await mealMemoryProvider?.matchRememberedMeal(from: image) {
                return memory
            }

            if let barcode = try await barcodeProvider?.recognizeBarcodeMeal(from: image) {
                return barcode
            }

            if let vision = try await visionProvider?.recognizeFood(in: image) {
                return vision
            }

            if let coreML = try await coreMLProvider?.recognizeFood(in: image) {
                return coreML
            }

            if let openAI = try await openAIProvider?.recognizeFood(in: image) {
                return openAI
            }
        }

        let signature = image.map(makeSignature(from:))
        let items = makeHeuristicItems(signature: signature)
        let confidence = min(0.94, items.map(\.confidence).reduce(0, +) / Double(max(items.count, 1)) + (signature == nil ? -0.08 : 0.04))

        return FoodRecognitionOutput(
            items: items,
            confidence: confidence,
            source: .heuristicVision,
            imageSignature: signature
        )
    }

    private func makeSignature(from image: UIImage) -> FoodImageSignature {
        guard
            let cgImage = image.cgImage,
            let data = cgImage.dataProvider?.data,
            let bytes = CFDataGetBytePtr(data)
        else {
            return FoodImageSignature(brightness: 0.58, saturation: 0.48, warmth: 0.52, aspectRatio: Double(image.size.width / max(image.size.height, 1)))
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = max(cgImage.bitsPerPixel / 8, 4)
        let bytesPerRow = cgImage.bytesPerRow
        let xStride = max(width / 18, 1)
        let yStride = max(height / 18, 1)

        var brightness = 0.0
        var saturation = 0.0
        var warmth = 0.0
        var samples = 0.0

        for y in stride(from: 0, to: height, by: yStride) {
            for x in stride(from: 0, to: width, by: xStride) {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let r = Double(bytes[offset]) / 255.0
                let g = Double(bytes[offset + min(1, bytesPerPixel - 1)]) / 255.0
                let b = Double(bytes[offset + min(2, bytesPerPixel - 1)]) / 255.0
                let maxRGB = max(r, g, b)
                let minRGB = min(r, g, b)

                brightness += (r + g + b) / 3.0
                saturation += maxRGB == 0 ? 0 : (maxRGB - minRGB) / maxRGB
                warmth += max(0, r - b) + (g * 0.18)
                samples += 1
            }
        }

        let safeSamples = max(samples, 1)
        return FoodImageSignature(
            brightness: brightness / safeSamples,
            saturation: saturation / safeSamples,
            warmth: min(1, warmth / safeSamples),
            aspectRatio: Double(image.size.width / max(image.size.height, 1))
        )
    }

    private func makeHeuristicItems(signature: FoodImageSignature?) -> [DetectedFoodItem] {
        guard let signature else {
            return [
                DetectedFoodItem(
                    name: "Lean protein bowl",
                    category: "protein bowl",
                    confidence: 0.82,
                    estimatedPortion: 1.0,
                    region: FoodDetectionRegion(x: 0.16, y: 0.18, width: 0.68, height: 0.62)
                ),
                DetectedFoodItem(
                    name: "Mixed greens",
                    category: "vegetable",
                    confidence: 0.76,
                    estimatedPortion: 0.7,
                    region: FoodDetectionRegion(x: 0.08, y: 0.46, width: 0.34, height: 0.32)
                )
            ]
        }

        if signature.saturation > 0.58 && signature.warmth > 0.54 {
            return [
                DetectedFoodItem(name: "Chicken rice bowl", category: "protein bowl", confidence: 0.89, estimatedPortion: 1.08, region: FoodDetectionRegion(x: 0.15, y: 0.17, width: 0.52, height: 0.48)),
                DetectedFoodItem(name: "Roasted vegetables", category: "vegetable", confidence: 0.81, estimatedPortion: 0.72, region: FoodDetectionRegion(x: 0.50, y: 0.43, width: 0.34, height: 0.34)),
                DetectedFoodItem(name: "Sauce", category: "condiment", confidence: 0.68, estimatedPortion: 0.35, region: FoodDetectionRegion(x: 0.34, y: 0.29, width: 0.22, height: 0.18))
            ]
        }

        if signature.brightness < 0.36 {
            return [
                DetectedFoodItem(name: "Burger", category: "dense meal", confidence: 0.84, estimatedPortion: 1.0, region: FoodDetectionRegion(x: 0.18, y: 0.20, width: 0.56, height: 0.44)),
                DetectedFoodItem(name: "Fries", category: "starch", confidence: 0.78, estimatedPortion: 0.8, region: FoodDetectionRegion(x: 0.53, y: 0.48, width: 0.32, height: 0.30))
            ]
        }

        if signature.warmth < 0.35 && signature.saturation > 0.38 {
            return [
                DetectedFoodItem(name: "Sushi plate", category: "seafood", confidence: 0.86, estimatedPortion: 1.0, region: FoodDetectionRegion(x: 0.14, y: 0.18, width: 0.66, height: 0.46)),
                DetectedFoodItem(name: "Soy sauce", category: "condiment", confidence: 0.74, estimatedPortion: 0.28, region: FoodDetectionRegion(x: 0.58, y: 0.58, width: 0.24, height: 0.20))
            ]
        }

        if signature.brightness > 0.66 {
            return [
                DetectedFoodItem(name: "Greek yogurt bowl", category: "protein breakfast", confidence: 0.87, estimatedPortion: 0.95, region: FoodDetectionRegion(x: 0.17, y: 0.18, width: 0.62, height: 0.52)),
                DetectedFoodItem(name: "Fruit topping", category: "fruit", confidence: 0.80, estimatedPortion: 0.5, region: FoodDetectionRegion(x: 0.28, y: 0.24, width: 0.38, height: 0.26))
            ]
        }

        return [
            DetectedFoodItem(name: "Salmon grain plate", category: "protein plate", confidence: 0.85, estimatedPortion: 1.0, region: FoodDetectionRegion(x: 0.13, y: 0.17, width: 0.58, height: 0.48)),
            DetectedFoodItem(name: "Avocado", category: "healthy fat", confidence: 0.77, estimatedPortion: 0.42, region: FoodDetectionRegion(x: 0.54, y: 0.42, width: 0.28, height: 0.24)),
            DetectedFoodItem(name: "Greens", category: "vegetable", confidence: 0.72, estimatedPortion: 0.64, region: FoodDetectionRegion(x: 0.10, y: 0.50, width: 0.34, height: 0.26))
        ]
    }
}
