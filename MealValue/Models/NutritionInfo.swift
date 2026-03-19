import Foundation
import SwiftData

/// Nutritional information for a food item or aggregated for a meal
@Model
final class NutritionInfo {
    var calories: Double       // kcal
    var protein: Double        // grams
    var carbohydrates: Double  // grams
    var fat: Double            // grams
    var fiber: Double          // grams
    var sugar: Double          // grams
    var sodium: Double         // mg
    var cholesterol: Double    // mg
    var saturatedFat: Double   // grams
    var vitaminA: Double       // mcg RAE
    var vitaminC: Double       // mg
    var calcium: Double        // mg
    var iron: Double           // mg
    var potassium: Double      // mg

    init(
        calories: Double = 0,
        protein: Double = 0,
        carbohydrates: Double = 0,
        fat: Double = 0,
        fiber: Double = 0,
        sugar: Double = 0,
        sodium: Double = 0,
        cholesterol: Double = 0,
        saturatedFat: Double = 0,
        vitaminA: Double = 0,
        vitaminC: Double = 0,
        calcium: Double = 0,
        iron: Double = 0,
        potassium: Double = 0
    ) {
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.cholesterol = cholesterol
        self.saturatedFat = saturatedFat
        self.vitaminA = vitaminA
        self.vitaminC = vitaminC
        self.calcium = calcium
        self.iron = iron
        self.potassium = potassium
    }

    /// Add another NutritionInfo's values to this one
    func adding(_ other: NutritionInfo) -> NutritionInfo {
        NutritionInfo(
            calories: calories + other.calories,
            protein: protein + other.protein,
            carbohydrates: carbohydrates + other.carbohydrates,
            fat: fat + other.fat,
            fiber: fiber + other.fiber,
            sugar: sugar + other.sugar,
            sodium: sodium + other.sodium,
            cholesterol: cholesterol + other.cholesterol,
            saturatedFat: saturatedFat + other.saturatedFat,
            vitaminA: vitaminA + other.vitaminA,
            vitaminC: vitaminC + other.vitaminC,
            calcium: calcium + other.calcium,
            iron: iron + other.iron,
            potassium: potassium + other.potassium
        )
    }

    /// Scale nutrition values by a multiplier (e.g., for portion adjustment)
    func scaled(by multiplier: Double) -> NutritionInfo {
        NutritionInfo(
            calories: calories * multiplier,
            protein: protein * multiplier,
            carbohydrates: carbohydrates * multiplier,
            fat: fat * multiplier,
            fiber: fiber * multiplier,
            sugar: sugar * multiplier,
            sodium: sodium * multiplier,
            cholesterol: cholesterol * multiplier,
            saturatedFat: saturatedFat * multiplier,
            vitaminA: vitaminA * multiplier,
            vitaminC: vitaminC * multiplier,
            calcium: calcium * multiplier,
            iron: iron * multiplier,
            potassium: potassium * multiplier
        )
    }

    static var zero: NutritionInfo { NutritionInfo() }
}

/// Daily recommended values for nutrition scoring
struct DailyRecommended {
    static let calories: Double = 2000
    static let protein: Double = 50
    static let carbohydrates: Double = 275
    static let fat: Double = 78
    static let fiber: Double = 28
    static let sugar: Double = 50
    static let sodium: Double = 2300
    static let cholesterol: Double = 300
    static let saturatedFat: Double = 20
    static let vitaminA: Double = 900
    static let vitaminC: Double = 90
    static let calcium: Double = 1300
    static let iron: Double = 18
    static let potassium: Double = 4700
}
