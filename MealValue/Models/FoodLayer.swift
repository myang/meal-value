import Foundation
import SwiftData

/// Represents a single layer of food on the plate (e.g., base vegetables, top protein)
@Model
final class FoodLayer {
    var id: UUID
    var name: String              // e.g., "Base Layer", "Top Layer"
    var orderIndex: Int           // 0 = bottom, increasing = higher
    var photoData: Data?          // JPEG photo of this layer
    var aiAnalysisRaw: String?    // Raw JSON response from OpenAI

    @Relationship(deleteRule: .cascade)
    var foodItems: [FoodItem]

    @Relationship(inverse: \Meal.layers)
    var meal: Meal?

    init(
        name: String,
        orderIndex: Int,
        photoData: Data? = nil,
        foodItems: [FoodItem] = []
    ) {
        self.id = UUID()
        self.name = name
        self.orderIndex = orderIndex
        self.photoData = photoData
        self.foodItems = foodItems
    }

    /// Total nutrition for all food items in this layer
    var totalNutrition: NutritionInfo {
        foodItems.reduce(NutritionInfo.zero) { result, item in
            result.adding(item.nutrition)
        }
    }
}
