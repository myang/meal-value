import Foundation
import SwiftData

/// A complete meal record with multiple food layers
@Model
final class Meal {
    var id: UUID
    var name: String              // e.g., "Lunch", "Dinner"
    var mealType: MealType
    var date: Date
    var notes: String
    var overallPhotoData: Data?   // Photo of the complete assembled meal
    var nutritionScore: Int       // 0-100 overall meal quality score
    var isAnalyzed: Bool          // Whether AI analysis is complete

    @Relationship(deleteRule: .cascade)
    var layers: [FoodLayer]

    @Relationship(deleteRule: .cascade)
    var totalNutrition: NutritionInfo

    init(
        name: String = "",
        mealType: MealType = .lunch,
        date: Date = Date(),
        notes: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.mealType = mealType
        self.date = date
        self.notes = notes
        self.nutritionScore = 0
        self.isAnalyzed = false
        self.layers = []
        self.totalNutrition = NutritionInfo()
    }

    /// Recalculate total nutrition from all layers
    func recalculateNutrition() {
        let combined = layers.reduce(NutritionInfo.zero) { result, layer in
            result.adding(layer.totalNutrition)
        }
        totalNutrition.calories = combined.calories
        totalNutrition.protein = combined.protein
        totalNutrition.carbohydrates = combined.carbohydrates
        totalNutrition.fat = combined.fat
        totalNutrition.fiber = combined.fiber
        totalNutrition.sugar = combined.sugar
        totalNutrition.sodium = combined.sodium
        totalNutrition.cholesterol = combined.cholesterol
        totalNutrition.saturatedFat = combined.saturatedFat
        totalNutrition.vitaminA = combined.vitaminA
        totalNutrition.vitaminC = combined.vitaminC
        totalNutrition.calcium = combined.calcium
        totalNutrition.iron = combined.iron
        totalNutrition.potassium = combined.potassium
    }

    /// Calculate a nutrition quality score (0-100)
    func calculateScore() -> Int {
        guard totalNutrition.calories > 0 else { return 0 }

        var score: Double = 50 // Base score

        // Protein ratio bonus (target ~30% of calories)
        let proteinCalRatio = (totalNutrition.protein * 4) / totalNutrition.calories
        if proteinCalRatio >= 0.25 && proteinCalRatio <= 0.35 { score += 15 }
        else if proteinCalRatio >= 0.15 { score += 8 }

        // Fiber bonus
        let fiberPerMeal = DailyRecommended.fiber / 3
        if totalNutrition.fiber >= fiberPerMeal { score += 10 }
        else if totalNutrition.fiber >= fiberPerMeal * 0.5 { score += 5 }

        // Vegetable presence bonus
        let hasVegetables = layers.flatMap(\.foodItems).contains { $0.category == .vegetable }
        if hasVegetables { score += 10 }

        // Saturated fat penalty
        let satFatCalRatio = (totalNutrition.saturatedFat * 9) / totalNutrition.calories
        if satFatCalRatio > 0.1 { score -= 10 }

        // Sodium penalty
        let sodiumPerMeal = DailyRecommended.sodium / 3
        if totalNutrition.sodium > sodiumPerMeal * 1.5 { score -= 10 }

        // Sugar penalty
        let sugarPerMeal = DailyRecommended.sugar / 3
        if totalNutrition.sugar > sugarPerMeal { score -= 10 }

        // Variety bonus - more food categories = better
        let categories = Set(layers.flatMap(\.foodItems).map(\.category))
        if categories.count >= 4 { score += 10 }
        else if categories.count >= 3 { score += 5 }

        return max(0, min(100, Int(score)))
    }

    /// Sorted layers by orderIndex
    var sortedLayers: [FoodLayer] {
        layers.sorted { $0.orderIndex < $1.orderIndex }
    }
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "carrot.fill"
        }
    }
}
