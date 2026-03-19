import Foundation
import SwiftUI

enum FoodCategory: String, Codable, CaseIterable, Identifiable {
    case vegetables
    case protein
    case carbs
    case fats
    case sauce
    case fruit
    case other

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .vegetables: .green
        case .protein: .orange
        case .carbs: .yellow
        case .fats: .pink
        case .sauce: .purple
        case .fruit: .red
        case .other: .gray
        }
    }
}

enum PortionSize: String, Codable, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }
    var multiplier: Double {
        switch self {
        case .small: 0.8
        case .medium: 1.0
        case .large: 1.35
        }
    }
}

struct NutritionValues: Codable, Hashable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double

    static let zero = NutritionValues(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0)

    static func + (lhs: NutritionValues, rhs: NutritionValues) -> NutritionValues {
        NutritionValues(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat,
            fiber: lhs.fiber + rhs.fiber
        )
    }
}

struct LayerRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    var createdAt = Date()
    var category: FoodCategory
    var foodName: String
    var portionSize: PortionSize
    var estimatedWeightGrams: Double
    var nutrition: NutritionValues
    var imageData: Data?
}

struct MealRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    var createdAt = Date()
    var mealName: String
    var notes: String
    var layers: [LayerRecord]

    var totalNutrition: NutritionValues {
        layers.reduce(.zero) { $0 + $1.nutrition }
    }

    var nutritionScore: Int {
        NutritionEngine.scoreMeal(self)
    }
}

struct FoodProfile: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let category: FoodCategory
    let defaultWeightGrams: Double
    let per100g: NutritionValues
}

struct NutritionSummary {
    let meals: [MealRecord]
    let total: NutritionValues
    let averageCaloriesPerMeal: Double
    let averageProteinPerMeal: Double
    let averageFiberPerMeal: Double
}
