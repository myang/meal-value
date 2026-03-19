import Foundation
import SwiftData

/// A recognized food item within a food layer
@Model
final class FoodItem {
    var id: UUID
    var name: String
    var category: FoodCategory
    var portionGrams: Double
    var portionDescription: String  // e.g., "1 cup", "150g", "1 breast"
    var confidence: Double          // AI recognition confidence 0-1
    @Relationship(deleteRule: .cascade)
    var nutrition: NutritionInfo

    @Relationship(inverse: \FoodLayer.foodItems)
    var layer: FoodLayer?

    init(
        name: String,
        category: FoodCategory,
        portionGrams: Double,
        portionDescription: String = "",
        confidence: Double = 1.0,
        nutrition: NutritionInfo = NutritionInfo()
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.portionGrams = portionGrams
        self.portionDescription = portionDescription
        self.confidence = confidence
        self.nutrition = nutrition
    }
}

enum FoodCategory: String, Codable, CaseIterable, Identifiable {
    case vegetable = "Vegetable"
    case fruit = "Fruit"
    case protein = "Protein"
    case grain = "Grain"
    case dairy = "Dairy"
    case fat = "Fat & Oil"
    case sauce = "Sauce & Condiment"
    case beverage = "Beverage"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .vegetable: return "leaf.fill"
        case .fruit: return "apple.logo"
        case .protein: return "fish.fill"
        case .grain: return "takeoutbag.and.cup.and.straw.fill"
        case .dairy: return "cup.and.saucer.fill"
        case .fat: return "drop.fill"
        case .sauce: return "flask.fill"
        case .beverage: return "waterbottle.fill"
        case .other: return "fork.knife"
        }
    }

    var color: String {
        switch self {
        case .vegetable: return "green"
        case .fruit: return "orange"
        case .protein: return "red"
        case .grain: return "brown"
        case .dairy: return "blue"
        case .fat: return "yellow"
        case .sauce: return "purple"
        case .beverage: return "cyan"
        case .other: return "gray"
        }
    }
}
