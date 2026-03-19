import Foundation

/// Codable representation of meal data for Google Drive export/import
struct MealExportData: Codable {
    var id: String
    var name: String
    var mealType: String
    var date: Date
    var notes: String
    var nutritionScore: Int
    var layers: [LayerExportData]
    var totalNutrition: NutritionExportData

    struct LayerExportData: Codable {
        var id: String
        var name: String
        var orderIndex: Int
        var foodItems: [FoodItemExportData]
    }

    struct FoodItemExportData: Codable {
        var id: String
        var name: String
        var category: String
        var portionGrams: Double
        var portionDescription: String
        var confidence: Double
        var nutrition: NutritionExportData
    }

    struct NutritionExportData: Codable {
        var calories: Double
        var protein: Double
        var carbohydrates: Double
        var fat: Double
        var fiber: Double
        var sugar: Double
        var sodium: Double
        var cholesterol: Double
        var saturatedFat: Double
        var vitaminA: Double
        var vitaminC: Double
        var calcium: Double
        var iron: Double
        var potassium: Double
    }
}

// MARK: - Conversion helpers

extension MealExportData {
    init(from meal: Meal) {
        self.id = meal.id.uuidString
        self.name = meal.name
        self.mealType = meal.mealType.rawValue
        self.date = meal.date
        self.notes = meal.notes
        self.nutritionScore = meal.nutritionScore
        self.layers = meal.sortedLayers.map { LayerExportData(from: $0) }
        self.totalNutrition = NutritionExportData(from: meal.totalNutrition)
    }
}

extension MealExportData.LayerExportData {
    init(from layer: FoodLayer) {
        self.id = layer.id.uuidString
        self.name = layer.name
        self.orderIndex = layer.orderIndex
        self.foodItems = layer.foodItems.map { MealExportData.FoodItemExportData(from: $0) }
    }
}

extension MealExportData.FoodItemExportData {
    init(from item: FoodItem) {
        self.id = item.id.uuidString
        self.name = item.name
        self.category = item.category.rawValue
        self.portionGrams = item.portionGrams
        self.portionDescription = item.portionDescription
        self.confidence = item.confidence
        self.nutrition = MealExportData.NutritionExportData(from: item.nutrition)
    }
}

extension MealExportData.NutritionExportData {
    init(from info: NutritionInfo) {
        self.calories = info.calories
        self.protein = info.protein
        self.carbohydrates = info.carbohydrates
        self.fat = info.fat
        self.fiber = info.fiber
        self.sugar = info.sugar
        self.sodium = info.sodium
        self.cholesterol = info.cholesterol
        self.saturatedFat = info.saturatedFat
        self.vitaminA = info.vitaminA
        self.vitaminC = info.vitaminC
        self.calcium = info.calcium
        self.iron = info.iron
        self.potassium = info.potassium
    }
}
