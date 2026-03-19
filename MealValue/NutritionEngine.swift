import Foundation

enum NutritionEngine {
    static let foodProfiles: [FoodProfile] = [
        .init(name: "Broccoli", category: .vegetables, defaultWeightGrams: 120, per100g: .init(calories: 35, protein: 2.4, carbs: 7.2, fat: 0.4, fiber: 3.3)),
        .init(name: "Mixed salad", category: .vegetables, defaultWeightGrams: 100, per100g: .init(calories: 20, protein: 1.2, carbs: 3.6, fat: 0.2, fiber: 2.1)),
        .init(name: "Roasted vegetables", category: .vegetables, defaultWeightGrams: 130, per100g: .init(calories: 55, protein: 1.8, carbs: 10.0, fat: 1.7, fiber: 3.0)),
        .init(name: "Chicken breast", category: .protein, defaultWeightGrams: 140, per100g: .init(calories: 165, protein: 31.0, carbs: 0.0, fat: 3.6, fiber: 0.0)),
        .init(name: "Salmon", category: .protein, defaultWeightGrams: 130, per100g: .init(calories: 208, protein: 20.0, carbs: 0.0, fat: 13.0, fiber: 0.0)),
        .init(name: "Pork loin", category: .protein, defaultWeightGrams: 140, per100g: .init(calories: 195, protein: 27.0, carbs: 0.0, fat: 8.0, fiber: 0.0)),
        .init(name: "Lean beef", category: .protein, defaultWeightGrams: 140, per100g: .init(calories: 217, protein: 26.0, carbs: 0.0, fat: 12.0, fiber: 0.0)),
        .init(name: "Tofu", category: .protein, defaultWeightGrams: 120, per100g: .init(calories: 144, protein: 17.0, carbs: 3.0, fat: 9.0, fiber: 1.0)),
        .init(name: "Rice", category: .carbs, defaultWeightGrams: 150, per100g: .init(calories: 130, protein: 2.7, carbs: 28.0, fat: 0.3, fiber: 0.4)),
        .init(name: "Potatoes", category: .carbs, defaultWeightGrams: 180, per100g: .init(calories: 87, protein: 1.9, carbs: 20.1, fat: 0.1, fiber: 1.8)),
        .init(name: "Pasta", category: .carbs, defaultWeightGrams: 160, per100g: .init(calories: 157, protein: 5.8, carbs: 30.9, fat: 0.9, fiber: 1.8)),
        .init(name: "Avocado", category: .fats, defaultWeightGrams: 70, per100g: .init(calories: 160, protein: 2.0, carbs: 8.5, fat: 14.7, fiber: 6.7)),
        .init(name: "Olive oil dressing", category: .sauce, defaultWeightGrams: 20, per100g: .init(calories: 884, protein: 0.0, carbs: 0.0, fat: 100.0, fiber: 0.0)),
        .init(name: "Yogurt sauce", category: .sauce, defaultWeightGrams: 30, per100g: .init(calories: 70, protein: 3.4, carbs: 5.0, fat: 4.0, fiber: 0.0)),
        .init(name: "Apple", category: .fruit, defaultWeightGrams: 120, per100g: .init(calories: 52, protein: 0.3, carbs: 14.0, fat: 0.2, fiber: 2.4)),
    ]

    static func foods(for category: FoodCategory) -> [FoodProfile] {
        foodProfiles.filter { $0.category == category }
    }

    static func estimate(profile: FoodProfile, portion: PortionSize, manualWeight: Double? = nil) -> NutritionValues {
        let grams = manualWeight ?? profile.defaultWeightGrams * portion.multiplier
        let factor = grams / 100
        return NutritionValues(
            calories: profile.per100g.calories * factor,
            protein: profile.per100g.protein * factor,
            carbs: profile.per100g.carbs * factor,
            fat: profile.per100g.fat * factor,
            fiber: profile.per100g.fiber * factor
        )
    }

    static func scoreMeal(_ meal: MealRecord) -> Int {
        let total = meal.totalNutrition
        var score = 70
        if total.protein >= 25 { score += 10 }
        if total.fiber >= 8 { score += 10 }
        if total.calories > 900 { score -= 8 }
        if total.fat > 40 { score -= 5 }
        if !meal.layers.contains(where: { $0.category == .vegetables }) { score -= 10 }
        if meal.layers.filter({ $0.category == .protein }).isEmpty { score -= 8 }
        return max(0, min(100, score))
    }

    static func summarize(meals: [MealRecord]) -> NutritionSummary {
        let total = meals.map(\.totalNutrition).reduce(.zero, +)
        let count = Double(max(meals.count, 1))
        return NutritionSummary(
            meals: meals,
            total: total,
            averageCaloriesPerMeal: total.calories / count,
            averageProteinPerMeal: total.protein / count,
            averageFiberPerMeal: total.fiber / count
        )
    }
}
