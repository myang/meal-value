import Foundation

/// Built-in nutrition reference database for common foods
/// Used as fallback when OpenAI API is unavailable and for manual food entry
struct NutritionDatabase {

    /// Reference nutrition data per 100g for common foods
    static let foods: [String: FoodReference] = [
        // PROTEINS
        "Chicken Breast": FoodReference(
            category: .protein, caloriesPer100g: 165, protein: 31, carbs: 0, fat: 3.6,
            fiber: 0, sugar: 0, sodium: 74, cholesterol: 85, satFat: 1.0,
            vitA: 6, vitC: 0, calcium: 15, iron: 1.0, potassium: 256,
            typicalPortionG: 150, typicalPortionDesc: "1 breast (150g)"
        ),
        "Salmon": FoodReference(
            category: .protein, caloriesPer100g: 208, protein: 20, carbs: 0, fat: 13,
            fiber: 0, sugar: 0, sodium: 59, cholesterol: 55, satFat: 3.1,
            vitA: 12, vitC: 0, calcium: 12, iron: 0.8, potassium: 363,
            typicalPortionG: 170, typicalPortionDesc: "1 fillet (170g)"
        ),
        "Ground Beef (85% lean)": FoodReference(
            category: .protein, caloriesPer100g: 215, protein: 26, carbs: 0, fat: 11.8,
            fiber: 0, sugar: 0, sodium: 75, cholesterol: 78, satFat: 4.6,
            vitA: 0, vitC: 0, calcium: 18, iron: 2.6, potassium: 318,
            typicalPortionG: 113, typicalPortionDesc: "1 patty (113g)"
        ),
        "Pork Loin": FoodReference(
            category: .protein, caloriesPer100g: 143, protein: 26, carbs: 0, fat: 3.5,
            fiber: 0, sugar: 0, sodium: 54, cholesterol: 66, satFat: 1.2,
            vitA: 0, vitC: 1, calcium: 5, iron: 0.9, potassium: 399,
            typicalPortionG: 140, typicalPortionDesc: "1 chop (140g)"
        ),
        "Shrimp": FoodReference(
            category: .protein, caloriesPer100g: 99, protein: 24, carbs: 0.2, fat: 0.3,
            fiber: 0, sugar: 0, sodium: 111, cholesterol: 189, satFat: 0.1,
            vitA: 54, vitC: 0, calcium: 70, iron: 0.5, potassium: 259,
            typicalPortionG: 120, typicalPortionDesc: "6 large (120g)"
        ),
        "Tofu (firm)": FoodReference(
            category: .protein, caloriesPer100g: 144, protein: 17, carbs: 3, fat: 8.7,
            fiber: 2.3, sugar: 0.7, sodium: 14, cholesterol: 0, satFat: 1.3,
            vitA: 0, vitC: 0, calcium: 683, iron: 2.7, potassium: 237,
            typicalPortionG: 126, typicalPortionDesc: "½ block (126g)"
        ),
        "Eggs": FoodReference(
            category: .protein, caloriesPer100g: 155, protein: 13, carbs: 1.1, fat: 11,
            fiber: 0, sugar: 1.1, sodium: 124, cholesterol: 373, satFat: 3.3,
            vitA: 160, vitC: 0, calcium: 56, iron: 1.8, potassium: 138,
            typicalPortionG: 50, typicalPortionDesc: "1 large egg (50g)"
        ),
        "Tuna": FoodReference(
            category: .protein, caloriesPer100g: 130, protein: 28, carbs: 0, fat: 1,
            fiber: 0, sugar: 0, sodium: 40, cholesterol: 45, satFat: 0.2,
            vitA: 18, vitC: 0, calcium: 4, iron: 1.0, potassium: 441,
            typicalPortionG: 140, typicalPortionDesc: "1 can (140g)"
        ),

        // VEGETABLES
        "Broccoli": FoodReference(
            category: .vegetable, caloriesPer100g: 34, protein: 2.8, carbs: 7, fat: 0.4,
            fiber: 2.6, sugar: 1.7, sodium: 33, cholesterol: 0, satFat: 0.04,
            vitA: 31, vitC: 89, calcium: 47, iron: 0.7, potassium: 316,
            typicalPortionG: 91, typicalPortionDesc: "1 cup chopped (91g)"
        ),
        "Spinach": FoodReference(
            category: .vegetable, caloriesPer100g: 23, protein: 2.9, carbs: 3.6, fat: 0.4,
            fiber: 2.2, sugar: 0.4, sodium: 79, cholesterol: 0, satFat: 0.1,
            vitA: 469, vitC: 28, calcium: 99, iron: 2.7, potassium: 558,
            typicalPortionG: 30, typicalPortionDesc: "1 cup raw (30g)"
        ),
        "Mixed Salad Greens": FoodReference(
            category: .vegetable, caloriesPer100g: 20, protein: 2, carbs: 3.5, fat: 0.3,
            fiber: 2, sugar: 0.5, sodium: 25, cholesterol: 0, satFat: 0.04,
            vitA: 300, vitC: 20, calcium: 50, iron: 1.5, potassium: 300,
            typicalPortionG: 85, typicalPortionDesc: "2 cups (85g)"
        ),
        "Bell Pepper": FoodReference(
            category: .vegetable, caloriesPer100g: 31, protein: 1, carbs: 6, fat: 0.3,
            fiber: 2.1, sugar: 4.2, sodium: 4, cholesterol: 0, satFat: 0.03,
            vitA: 157, vitC: 128, calcium: 7, iron: 0.4, potassium: 211,
            typicalPortionG: 119, typicalPortionDesc: "1 medium (119g)"
        ),
        "Carrots": FoodReference(
            category: .vegetable, caloriesPer100g: 41, protein: 0.9, carbs: 10, fat: 0.2,
            fiber: 2.8, sugar: 4.7, sodium: 69, cholesterol: 0, satFat: 0.04,
            vitA: 835, vitC: 6, calcium: 33, iron: 0.3, potassium: 320,
            typicalPortionG: 61, typicalPortionDesc: "1 medium (61g)"
        ),
        "Tomato": FoodReference(
            category: .vegetable, caloriesPer100g: 18, protein: 0.9, carbs: 3.9, fat: 0.2,
            fiber: 1.2, sugar: 2.6, sodium: 5, cholesterol: 0, satFat: 0.03,
            vitA: 42, vitC: 14, calcium: 10, iron: 0.3, potassium: 237,
            typicalPortionG: 123, typicalPortionDesc: "1 medium (123g)"
        ),
        "Sweet Potato": FoodReference(
            category: .vegetable, caloriesPer100g: 86, protein: 1.6, carbs: 20, fat: 0.1,
            fiber: 3, sugar: 4.2, sodium: 55, cholesterol: 0, satFat: 0.02,
            vitA: 709, vitC: 2.4, calcium: 30, iron: 0.6, potassium: 337,
            typicalPortionG: 130, typicalPortionDesc: "1 medium (130g)"
        ),
        "Cucumber": FoodReference(
            category: .vegetable, caloriesPer100g: 15, protein: 0.7, carbs: 3.6, fat: 0.1,
            fiber: 0.5, sugar: 1.7, sodium: 2, cholesterol: 0, satFat: 0.01,
            vitA: 5, vitC: 2.8, calcium: 16, iron: 0.3, potassium: 147,
            typicalPortionG: 52, typicalPortionDesc: "½ cup sliced (52g)"
        ),
        "Green Beans": FoodReference(
            category: .vegetable, caloriesPer100g: 31, protein: 1.8, carbs: 7, fat: 0.1,
            fiber: 3.4, sugar: 1.4, sodium: 6, cholesterol: 0, satFat: 0.02,
            vitA: 35, vitC: 12, calcium: 37, iron: 1.0, potassium: 211,
            typicalPortionG: 125, typicalPortionDesc: "1 cup (125g)"
        ),
        "Mushrooms": FoodReference(
            category: .vegetable, caloriesPer100g: 22, protein: 3.1, carbs: 3.3, fat: 0.3,
            fiber: 1, sugar: 2, sodium: 5, cholesterol: 0, satFat: 0.05,
            vitA: 0, vitC: 2.1, calcium: 3, iron: 0.5, potassium: 318,
            typicalPortionG: 70, typicalPortionDesc: "1 cup sliced (70g)"
        ),
        "Corn": FoodReference(
            category: .vegetable, caloriesPer100g: 86, protein: 3.2, carbs: 19, fat: 1.2,
            fiber: 2.7, sugar: 3.2, sodium: 15, cholesterol: 0, satFat: 0.16,
            vitA: 9, vitC: 7, calcium: 2, iron: 0.5, potassium: 270,
            typicalPortionG: 90, typicalPortionDesc: "1 ear (90g)"
        ),

        // GRAINS
        "White Rice (cooked)": FoodReference(
            category: .grain, caloriesPer100g: 130, protein: 2.7, carbs: 28, fat: 0.3,
            fiber: 0.4, sugar: 0, sodium: 1, cholesterol: 0, satFat: 0.08,
            vitA: 0, vitC: 0, calcium: 10, iron: 1.2, potassium: 35,
            typicalPortionG: 158, typicalPortionDesc: "1 cup (158g)"
        ),
        "Brown Rice (cooked)": FoodReference(
            category: .grain, caloriesPer100g: 112, protein: 2.3, carbs: 24, fat: 0.8,
            fiber: 1.8, sugar: 0, sodium: 1, cholesterol: 0, satFat: 0.17,
            vitA: 0, vitC: 0, calcium: 10, iron: 0.4, potassium: 79,
            typicalPortionG: 195, typicalPortionDesc: "1 cup (195g)"
        ),
        "Pasta (cooked)": FoodReference(
            category: .grain, caloriesPer100g: 131, protein: 5, carbs: 25, fat: 1.1,
            fiber: 1.8, sugar: 0.6, sodium: 1, cholesterol: 0, satFat: 0.15,
            vitA: 0, vitC: 0, calcium: 7, iron: 1.3, potassium: 44,
            typicalPortionG: 140, typicalPortionDesc: "1 cup (140g)"
        ),
        "Bread (whole wheat)": FoodReference(
            category: .grain, caloriesPer100g: 247, protein: 13, carbs: 41, fat: 3.4,
            fiber: 7, sugar: 6, sodium: 400, cholesterol: 0, satFat: 0.7,
            vitA: 0, vitC: 0, calcium: 107, iron: 2.5, potassium: 254,
            typicalPortionG: 33, typicalPortionDesc: "1 slice (33g)"
        ),
        "Quinoa (cooked)": FoodReference(
            category: .grain, caloriesPer100g: 120, protein: 4.4, carbs: 21, fat: 1.9,
            fiber: 2.8, sugar: 0.9, sodium: 7, cholesterol: 0, satFat: 0.23,
            vitA: 1, vitC: 0, calcium: 17, iron: 1.5, potassium: 172,
            typicalPortionG: 185, typicalPortionDesc: "1 cup (185g)"
        ),

        // FRUITS
        "Apple": FoodReference(
            category: .fruit, caloriesPer100g: 52, protein: 0.3, carbs: 14, fat: 0.2,
            fiber: 2.4, sugar: 10, sodium: 1, cholesterol: 0, satFat: 0.03,
            vitA: 3, vitC: 5, calcium: 6, iron: 0.1, potassium: 107,
            typicalPortionG: 182, typicalPortionDesc: "1 medium (182g)"
        ),
        "Banana": FoodReference(
            category: .fruit, caloriesPer100g: 89, protein: 1.1, carbs: 23, fat: 0.3,
            fiber: 2.6, sugar: 12, sodium: 1, cholesterol: 0, satFat: 0.11,
            vitA: 3, vitC: 9, calcium: 5, iron: 0.3, potassium: 358,
            typicalPortionG: 118, typicalPortionDesc: "1 medium (118g)"
        ),
        "Avocado": FoodReference(
            category: .fruit, caloriesPer100g: 160, protein: 2, carbs: 9, fat: 15,
            fiber: 7, sugar: 0.7, sodium: 7, cholesterol: 0, satFat: 2.1,
            vitA: 7, vitC: 10, calcium: 12, iron: 0.6, potassium: 485,
            typicalPortionG: 68, typicalPortionDesc: "⅓ medium (68g)"
        ),

        // DAIRY
        "Cheese (cheddar)": FoodReference(
            category: .dairy, caloriesPer100g: 403, protein: 25, carbs: 1.3, fat: 33,
            fiber: 0, sugar: 0.5, sodium: 621, cholesterol: 105, satFat: 21,
            vitA: 265, vitC: 0, calcium: 721, iron: 0.7, potassium: 98,
            typicalPortionG: 28, typicalPortionDesc: "1 oz slice (28g)"
        ),
        "Greek Yogurt": FoodReference(
            category: .dairy, caloriesPer100g: 59, protein: 10, carbs: 3.6, fat: 0.4,
            fiber: 0, sugar: 3.2, sodium: 36, cholesterol: 5, satFat: 0.1,
            vitA: 0, vitC: 0, calcium: 110, iron: 0.1, potassium: 141,
            typicalPortionG: 170, typicalPortionDesc: "1 container (170g)"
        ),

        // FATS & OILS
        "Olive Oil": FoodReference(
            category: .fat, caloriesPer100g: 884, protein: 0, carbs: 0, fat: 100,
            fiber: 0, sugar: 0, sodium: 2, cholesterol: 0, satFat: 14,
            vitA: 0, vitC: 0, calcium: 1, iron: 0.6, potassium: 1,
            typicalPortionG: 14, typicalPortionDesc: "1 tbsp (14g)"
        ),
        "Butter": FoodReference(
            category: .fat, caloriesPer100g: 717, protein: 0.9, carbs: 0.1, fat: 81,
            fiber: 0, sugar: 0.1, sodium: 11, cholesterol: 215, satFat: 51,
            vitA: 684, vitC: 0, calcium: 24, iron: 0.02, potassium: 24,
            typicalPortionG: 14, typicalPortionDesc: "1 tbsp (14g)"
        ),

        // SAUCES
        "Soy Sauce": FoodReference(
            category: .sauce, caloriesPer100g: 53, protein: 8.1, carbs: 4.9, fat: 0.6,
            fiber: 0.8, sugar: 0.4, sodium: 5493, cholesterol: 0, satFat: 0.1,
            vitA: 0, vitC: 0, calcium: 20, iron: 1.7, potassium: 212,
            typicalPortionG: 16, typicalPortionDesc: "1 tbsp (16g)"
        ),
        "Ketchup": FoodReference(
            category: .sauce, caloriesPer100g: 112, protein: 1.7, carbs: 27, fat: 0.1,
            fiber: 0.3, sugar: 22, sodium: 907, cholesterol: 0, satFat: 0.01,
            vitA: 26, vitC: 4, calcium: 14, iron: 0.4, potassium: 281,
            typicalPortionG: 17, typicalPortionDesc: "1 tbsp (17g)"
        ),
    ]

    /// Look up a food by name (case-insensitive partial match)
    static func lookup(_ name: String) -> [(name: String, ref: FoodReference)] {
        let lower = name.lowercased()
        return foods.compactMap { key, value in
            if key.lowercased().contains(lower) {
                return (name: key, ref: value)
            }
            return nil
        }.sorted { $0.name < $1.name }
    }

    /// Get all foods in a specific category
    static func foods(in category: FoodCategory) -> [(name: String, ref: FoodReference)] {
        foods.filter { $0.value.category == category }
            .map { (name: $0.key, ref: $0.value) }
            .sorted { $0.name < $1.name }
    }

    /// Get all food names
    static var allFoodNames: [String] {
        foods.keys.sorted()
    }
}

struct FoodReference {
    let category: FoodCategory
    let caloriesPer100g: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let cholesterol: Double
    let satFat: Double
    let vitA: Double
    let vitC: Double
    let calcium: Double
    let iron: Double
    let potassium: Double
    let typicalPortionG: Double
    let typicalPortionDesc: String

    /// Get NutritionInfo scaled to a specific portion in grams
    func nutritionFor(grams: Double) -> NutritionInfo {
        let scale = grams / 100.0
        return NutritionInfo(
            calories: caloriesPer100g * scale,
            protein: protein * scale,
            carbohydrates: carbs * scale,
            fat: fat * scale,
            fiber: fiber * scale,
            sugar: sugar * scale,
            sodium: sodium * scale,
            cholesterol: cholesterol * scale,
            saturatedFat: satFat * scale,
            vitaminA: vitA * scale,
            vitaminC: vitC * scale,
            calcium: calcium * scale,
            iron: iron * scale,
            potassium: potassium * scale
        )
    }
}
