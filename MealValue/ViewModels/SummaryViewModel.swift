import Foundation
import SwiftData

/// ViewModel for weekly and monthly nutrition summaries
@Observable
final class SummaryViewModel {
    var selectedPeriod: SummaryPeriod = .week
    var meals: [Meal] = []
    var advice: [NutritionAdviceEngine.Advice] = []

    enum SummaryPeriod: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"

        var id: String { rawValue }
    }

    struct DailyNutritionSummary: Identifiable {
        let id = UUID()
        let date: Date
        let calories: Double
        let protein: Double
        let carbohydrates: Double
        let fat: Double
        let fiber: Double
        let mealCount: Int
        let avgScore: Int
    }

    /// Load meals for the selected period
    func loadMeals(from context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date

        switch selectedPeriod {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
        }

        let predicate = #Predicate<Meal> { meal in
            meal.date >= startDate && meal.isAnalyzed
        }

        let descriptor = FetchDescriptor<Meal>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            meals = try context.fetch(descriptor)
            advice = NutritionAdviceEngine.generateAdvice(
                for: meals,
                periodLabel: selectedPeriod.rawValue.lowercased()
            )
        } catch {
            meals = []
            advice = []
        }
    }

    /// Group meals by day for chart display
    var dailySummaries: [DailyNutritionSummary] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: meals) { meal in
            calendar.startOfDay(for: meal.date)
        }

        return grouped.map { date, dayMeals in
            let totalCal = dayMeals.reduce(0.0) { $0 + $1.totalNutrition.calories }
            let totalProt = dayMeals.reduce(0.0) { $0 + $1.totalNutrition.protein }
            let totalCarb = dayMeals.reduce(0.0) { $0 + $1.totalNutrition.carbohydrates }
            let totalFat = dayMeals.reduce(0.0) { $0 + $1.totalNutrition.fat }
            let totalFiber = dayMeals.reduce(0.0) { $0 + $1.totalNutrition.fiber }
            let avgScore = dayMeals.isEmpty ? 0 : dayMeals.reduce(0) { $0 + $1.nutritionScore } / dayMeals.count

            return DailyNutritionSummary(
                date: date,
                calories: totalCal,
                protein: totalProt,
                carbohydrates: totalCarb,
                fat: totalFat,
                fiber: totalFiber,
                mealCount: dayMeals.count,
                avgScore: avgScore
            )
        }.sorted { $0.date < $1.date }
    }

    /// Period aggregate stats
    var totalCalories: Double {
        meals.reduce(0) { $0 + $1.totalNutrition.calories }
    }

    var avgCaloriesPerDay: Double {
        guard !dailySummaries.isEmpty else { return 0 }
        return totalCalories / Double(dailySummaries.count)
    }

    var avgProteinPerDay: Double {
        guard !dailySummaries.isEmpty else { return 0 }
        return meals.reduce(0) { $0 + $1.totalNutrition.protein } / Double(dailySummaries.count)
    }

    var avgScore: Int {
        guard !meals.isEmpty else { return 0 }
        return meals.reduce(0) { $0 + $1.nutritionScore } / meals.count
    }

    var totalMeals: Int { meals.count }

    /// Macro breakdown percentages
    var macroBreakdown: (proteinPct: Double, carbPct: Double, fatPct: Double) {
        let totalProt = meals.reduce(0.0) { $0 + $1.totalNutrition.protein }
        let totalCarb = meals.reduce(0.0) { $0 + $1.totalNutrition.carbohydrates }
        let totalFat = meals.reduce(0.0) { $0 + $1.totalNutrition.fat }

        let totalCalFromMacros = (totalProt * 4) + (totalCarb * 4) + (totalFat * 9)
        guard totalCalFromMacros > 0 else { return (0, 0, 0) }

        return (
            proteinPct: (totalProt * 4) / totalCalFromMacros * 100,
            carbPct: (totalCarb * 4) / totalCalFromMacros * 100,
            fatPct: (totalFat * 9) / totalCalFromMacros * 100
        )
    }
}
