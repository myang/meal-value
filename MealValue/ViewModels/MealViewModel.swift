import Foundation
import SwiftUI
import SwiftData
import UIKit

/// Main ViewModel for managing meal recording workflow
@Observable
final class MealViewModel {
    var currentMeal: Meal?
    var currentLayerIndex: Int = 0
    var capturedImage: UIImage?
    var isAnalyzing: Bool = false
    var analysisError: String?
    var showCamera: Bool = false
    var showManualEntry: Bool = false

    private let openAIService: OpenAIVisionService?

    init() {
        let apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
        self.openAIService = apiKey.isEmpty ? nil : OpenAIVisionService(apiKey: apiKey)
    }

    /// Start recording a new meal
    func startNewMeal(type: MealType) {
        let meal = Meal(name: type.rawValue, mealType: type)
        self.currentMeal = meal
        self.currentLayerIndex = 0
    }

    /// Add a new layer to the current meal
    func addLayer(name: String) {
        guard let meal = currentMeal else { return }
        let layer = FoodLayer(
            name: name,
            orderIndex: meal.layers.count
        )
        meal.layers.append(layer)
        currentLayerIndex = meal.layers.count - 1
    }

    /// Capture photo for the current layer
    func setPhotoForCurrentLayer(_ image: UIImage) {
        guard let meal = currentMeal,
              currentLayerIndex < meal.layers.count else { return }

        self.capturedImage = image
        let layer = meal.sortedLayers[currentLayerIndex]
        layer.photoData = image.jpegData(compressionQuality: 0.8)
    }

    /// Analyze the current layer's photo using OpenAI Vision
    func analyzeCurrentLayer() async {
        guard let image = capturedImage,
              let meal = currentMeal,
              currentLayerIndex < meal.layers.count else { return }

        let layer = meal.sortedLayers[currentLayerIndex]

        guard let service = openAIService else {
            analysisError = "OpenAI API key not configured. Go to Settings to add your API key, or use manual food entry."
            return
        }

        isAnalyzing = true
        analysisError = nil

        do {
            let result = try await service.analyzeImage(
                image,
                layerContext: layer.name
            )

            layer.aiAnalysisRaw = try? String(
                data: JSONEncoder().encode(result),
                encoding: .utf8
            )

            // Convert detected foods to FoodItem models
            for detected in result.foods {
                let category = FoodCategory(rawValue: detected.category) ?? .other
                let nutrition = NutritionInfo(
                    calories: detected.nutrition.calories,
                    protein: detected.nutrition.protein,
                    carbohydrates: detected.nutrition.carbohydrates,
                    fat: detected.nutrition.fat,
                    fiber: detected.nutrition.fiber,
                    sugar: detected.nutrition.sugar,
                    sodium: detected.nutrition.sodium,
                    cholesterol: detected.nutrition.cholesterol,
                    saturatedFat: detected.nutrition.saturatedFat,
                    vitaminA: detected.nutrition.vitaminA,
                    vitaminC: detected.nutrition.vitaminC,
                    calcium: detected.nutrition.calcium,
                    iron: detected.nutrition.iron,
                    potassium: detected.nutrition.potassium
                )

                let foodItem = FoodItem(
                    name: detected.name,
                    category: category,
                    portionGrams: detected.estimatedPortionGrams,
                    portionDescription: detected.portionDescription,
                    confidence: detected.confidence,
                    nutrition: nutrition
                )
                layer.foodItems.append(foodItem)
            }

            // Recalculate meal totals
            meal.recalculateNutrition()
            meal.nutritionScore = meal.calculateScore()

        } catch {
            analysisError = error.localizedDescription
        }

        isAnalyzing = false
    }

    /// Manually add a food item from the database to the current layer
    func addManualFoodItem(name: String, ref: FoodReference, grams: Double) {
        guard let meal = currentMeal,
              currentLayerIndex < meal.layers.count else { return }

        let layer = meal.sortedLayers[currentLayerIndex]
        let nutrition = ref.nutritionFor(grams: grams)

        let foodItem = FoodItem(
            name: name,
            category: ref.category,
            portionGrams: grams,
            portionDescription: "\(Int(grams))g",
            confidence: 1.0,
            nutrition: nutrition
        )
        layer.foodItems.append(foodItem)

        meal.recalculateNutrition()
        meal.nutritionScore = meal.calculateScore()
    }

    /// Remove a food item from a layer
    func removeFoodItem(_ item: FoodItem, from layer: FoodLayer) {
        layer.foodItems.removeAll { $0.id == item.id }
        currentMeal?.recalculateNutrition()
        currentMeal?.nutritionScore = currentMeal?.calculateScore() ?? 0
    }

    /// Finalize the meal and save
    func finalizeMeal(context: ModelContext) {
        guard let meal = currentMeal else { return }
        meal.isAnalyzed = true
        meal.recalculateNutrition()
        meal.nutritionScore = meal.calculateScore()
        context.insert(meal)
        try? context.save()
        resetState()
    }

    /// Reset the recording state
    func resetState() {
        currentMeal = nil
        currentLayerIndex = 0
        capturedImage = nil
        isAnalyzing = false
        analysisError = nil
    }
}
