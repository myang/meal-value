import Foundation

/// Engine that analyzes eating patterns and generates personalized nutrition advice
struct NutritionAdviceEngine {

    struct Advice: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let category: AdviceCategory
        let priority: Priority
    }

    enum AdviceCategory: String {
        case protein = "Protein"
        case vegetables = "Vegetables"
        case fiber = "Fiber"
        case hydration = "Hydration"
        case balance = "Balance"
        case calories = "Calories"
        case vitamins = "Vitamins"
        case sodium = "Sodium"
        case fat = "Fat"
        case general = "General"

        var icon: String {
            switch self {
            case .protein: return "fish.fill"
            case .vegetables: return "leaf.fill"
            case .fiber: return "circle.grid.3x3.fill"
            case .hydration: return "drop.fill"
            case .balance: return "scale.3d"
            case .calories: return "flame.fill"
            case .vitamins: return "pill.fill"
            case .sodium: return "exclamationmark.triangle.fill"
            case .fat: return "drop.triangle.fill"
            case .general: return "heart.fill"
            }
        }
    }

    enum Priority: Int, Comparable {
        case low = 0
        case medium = 1
        case high = 2

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Generate advice based on a collection of meals over a time period
    static func generateAdvice(for meals: [Meal], periodLabel: String = "this period") -> [Advice] {
        guard !meals.isEmpty else {
            return [Advice(
                title: "Start Recording",
                message: "Begin logging your meals to receive personalized nutrition advice!",
                category: .general,
                priority: .medium
            )]
        }

        var adviceList: [Advice] = []
        let mealCount = Double(meals.count)

        // Aggregate totals
        let totalCalories = meals.reduce(0.0) { $0 + $1.totalNutrition.calories }
        let totalProtein = meals.reduce(0.0) { $0 + $1.totalNutrition.protein }
        let totalFiber = meals.reduce(0.0) { $0 + $1.totalNutrition.fiber }
        let totalSodium = meals.reduce(0.0) { $0 + $1.totalNutrition.sodium }
        let totalSatFat = meals.reduce(0.0) { $0 + $1.totalNutrition.saturatedFat }
        let totalVitC = meals.reduce(0.0) { $0 + $1.totalNutrition.vitaminC }
        let totalCalcium = meals.reduce(0.0) { $0 + $1.totalNutrition.calcium }
        let totalIron = meals.reduce(0.0) { $0 + $1.totalNutrition.iron }

        // Averages per meal
        let avgCalories = totalCalories / mealCount
        let avgProtein = totalProtein / mealCount
        let avgFiber = totalFiber / mealCount
        let avgSodium = totalSodium / mealCount
        let avgSatFat = totalSatFat / mealCount

        // Count meals with vegetables
        let mealsWithVeggies = meals.filter { meal in
            meal.layers.flatMap(\.foodItems).contains { $0.category == .vegetable }
        }.count
        let veggieRatio = Double(mealsWithVeggies) / mealCount

        // Target per meal (assuming 3 meals/day)
        let targetCalPerMeal = DailyRecommended.calories / 3
        let targetProtPerMeal = DailyRecommended.protein / 3
        let targetFiberPerMeal = DailyRecommended.fiber / 3
        let targetSodiumPerMeal = DailyRecommended.sodium / 3

        // Protein advice
        if avgProtein < targetProtPerMeal * 0.7 {
            adviceList.append(Advice(
                title: "Increase Protein Intake",
                message: "Your average protein per meal is \(Int(avgProtein))g, below the recommended ~\(Int(targetProtPerMeal))g. Consider adding lean meats, fish, eggs, beans, or tofu to your meals.",
                category: .protein,
                priority: .high
            ))
        } else if avgProtein >= targetProtPerMeal {
            adviceList.append(Advice(
                title: "Great Protein Intake!",
                message: "You're averaging \(Int(avgProtein))g of protein per meal — keep it up!",
                category: .protein,
                priority: .low
            ))
        }

        // Vegetable advice
        if veggieRatio < 0.5 {
            adviceList.append(Advice(
                title: "Add More Vegetables",
                message: "Only \(Int(veggieRatio * 100))% of your meals include vegetables. Aim to include a vegetable base layer in every meal for better fiber, vitamins, and minerals.",
                category: .vegetables,
                priority: .high
            ))
        } else if veggieRatio >= 0.8 {
            adviceList.append(Advice(
                title: "Excellent Vegetable Intake!",
                message: "\(Int(veggieRatio * 100))% of your meals include vegetables. Outstanding habit!",
                category: .vegetables,
                priority: .low
            ))
        }

        // Fiber advice
        if avgFiber < targetFiberPerMeal * 0.6 {
            adviceList.append(Advice(
                title: "Boost Your Fiber",
                message: "You're averaging \(String(format: "%.1f", avgFiber))g of fiber per meal. Target ~\(Int(targetFiberPerMeal))g by adding whole grains, legumes, vegetables, and fruits.",
                category: .fiber,
                priority: .medium
            ))
        }

        // Sodium warning
        if avgSodium > targetSodiumPerMeal * 1.3 {
            adviceList.append(Advice(
                title: "Watch Your Sodium",
                message: "Your average sodium intake is \(Int(avgSodium))mg per meal, which is above recommended levels. Reduce sauces, processed meats, and salty condiments.",
                category: .sodium,
                priority: .high
            ))
        }

        // Saturated fat warning
        let satFatTargetPerMeal = DailyRecommended.saturatedFat / 3
        if avgSatFat > satFatTargetPerMeal * 1.2 {
            adviceList.append(Advice(
                title: "Reduce Saturated Fat",
                message: "Your saturated fat averages \(String(format: "%.1f", avgSatFat))g per meal. Choose lean proteins, use olive oil instead of butter, and limit cheese.",
                category: .fat,
                priority: .medium
            ))
        }

        // Calorie balance
        if avgCalories > targetCalPerMeal * 1.3 {
            adviceList.append(Advice(
                title: "Calorie Awareness",
                message: "Your meals average \(Int(avgCalories)) calories — above the typical \(Int(targetCalPerMeal)) target. Consider reducing portion sizes or choosing lower-calorie ingredients.",
                category: .calories,
                priority: .medium
            ))
        } else if avgCalories < targetCalPerMeal * 0.6 {
            adviceList.append(Advice(
                title: "Ensure Adequate Calories",
                message: "Your meals average only \(Int(avgCalories)) calories. Make sure you're eating enough to fuel your body properly.",
                category: .calories,
                priority: .medium
            ))
        }

        // Vitamin C
        let vitCPerMeal = totalVitC / mealCount
        if vitCPerMeal < DailyRecommended.vitaminC / 3 * 0.5 {
            adviceList.append(Advice(
                title: "Get More Vitamin C",
                message: "Add citrus fruits, bell peppers, broccoli, or strawberries to boost your vitamin C intake.",
                category: .vitamins,
                priority: .low
            ))
        }

        // Calcium
        let calciumPerMeal = totalCalcium / mealCount
        if calciumPerMeal < DailyRecommended.calcium / 3 * 0.5 {
            adviceList.append(Advice(
                title: "Consider Calcium Sources",
                message: "Include dairy, fortified plant milks, leafy greens, or tofu to meet your calcium needs.",
                category: .vitamins,
                priority: .low
            ))
        }

        // Iron
        let ironPerMeal = totalIron / mealCount
        if ironPerMeal < DailyRecommended.iron / 3 * 0.5 {
            adviceList.append(Advice(
                title: "Boost Iron Intake",
                message: "Red meat, spinach, lentils, and fortified cereals are great iron sources. Pair with vitamin C for better absorption.",
                category: .vitamins,
                priority: .low
            ))
        }

        // Meal variety
        let allCategories = Set(meals.flatMap { $0.layers.flatMap(\.foodItems).map(\.category) })
        if allCategories.count < 4 {
            adviceList.append(Advice(
                title: "Diversify Your Diet",
                message: "You're eating from only \(allCategories.count) food categories. Aim for at least 4 categories (protein, vegetables, grains, fruits) for a balanced diet.",
                category: .balance,
                priority: .medium
            ))
        }

        // Meal score trend
        let avgScore = meals.reduce(0) { $0 + $1.nutritionScore } / meals.count
        if avgScore >= 75 {
            adviceList.append(Advice(
                title: "Excellent Eating Habits!",
                message: "Your average meal score is \(avgScore)/100. You're making great nutrition choices!",
                category: .general,
                priority: .low
            ))
        } else if avgScore < 50 {
            adviceList.append(Advice(
                title: "Room for Improvement",
                message: "Your average meal score is \(avgScore)/100. Focus on adding vegetables, lean proteins, and reducing processed foods.",
                category: .general,
                priority: .high
            ))
        }

        return adviceList.sorted { $0.priority > $1.priority }
    }
}
