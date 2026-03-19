import Foundation

enum AdviceEngine {
    static func advice(for meals: [MealRecord]) -> [String] {
        guard !meals.isEmpty else {
            return ["Start logging meals to unlock weekly and monthly nutrition advice."]
        }

        let summary = NutritionEngine.summarize(meals: meals)
        var notes: [String] = []

        if summary.averageProteinPerMeal < 25 {
            notes.append("Average protein is a bit low. Add more chicken, fish, tofu, eggs, or legumes to keep meals more filling.")
        }

        if summary.averageFiberPerMeal < 8 {
            notes.append("Fiber intake looks light. Bigger vegetable layers, fruit, beans, or whole grains would help.")
        }

        if summary.averageCaloriesPerMeal > 850 {
            notes.append("Meals are trending calorie-dense. Consider shrinking sauces/oils or carb portions a little.")
        }

        let vegetableCoverage = meals.filter { $0.layers.contains(where: { $0.category == .vegetables }) }.count
        if Double(vegetableCoverage) / Double(meals.count) < 0.8 {
            notes.append("Vegetables are missing in quite a few meals. Make the base layer veg more consistently.")
        }

        if notes.isEmpty {
            notes.append("Your meals look pretty balanced overall. Keep consistency high and watch variety across protein and vegetable sources.")
        }

        return notes
    }
}
