import SwiftUI

struct SummaryView: View {
    @EnvironmentObject private var store: MealStore

    var body: some View {
        List {
            summarySection(title: "Weekly", meals: store.weeklyMeals())
            summarySection(title: "Monthly", meals: store.monthlyMeals())
        }
        .navigationTitle("Summary")
    }

    @ViewBuilder
    private func summarySection(title: String, meals: [MealRecord]) -> some View {
        let summary = NutritionEngine.summarize(meals: meals)
        Section(title) {
            if meals.isEmpty {
                Text("No meals recorded yet.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Meals logged: \(meals.count)")
                        .font(.headline)
                    HStack(spacing: 18) {
                        NutritionBadge(title: "Avg kcal", value: summary.averageCaloriesPerMeal)
                        NutritionBadge(title: "Avg P", value: summary.averageProteinPerMeal, suffix: "g")
                        NutritionBadge(title: "Avg fiber", value: summary.averageFiberPerMeal, suffix: "g")
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Advice")
                            .font(.headline)
                        ForEach(AdviceEngine.advice(for: meals), id: \.self) { note in
                            Label(note, systemImage: "leaf")
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
