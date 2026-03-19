import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: MealStore
    @State private var showingAddMeal = false

    var body: some View {
        TabView {
            NavigationStack {
                List {
                    if store.meals.isEmpty {
                        ContentUnavailableView(
                            "No meals yet",
                            systemImage: "fork.knife.circle",
                            description: Text("Start by logging a meal layer-by-layer with photos.")
                        )
                    } else {
                        ForEach(store.meals) { meal in
                            NavigationLink {
                                MealDetailView(meal: meal)
                            } label: {
                                MealCardView(meal: meal)
                            }
                        }
                    }
                }
                .navigationTitle("MealValue")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAddMeal = true
                        } label: {
                            Label("Add Meal", systemImage: "plus")
                        }
                    }
                }
            }
            .tabItem {
                Label("Meals", systemImage: "fork.knife")
            }

            NavigationStack {
                SummaryView()
            }
            .tabItem {
                Label("Summary", systemImage: "chart.xyaxis.line")
            }
        }
        .sheet(isPresented: $showingAddMeal) {
            AddMealView()
                .environmentObject(store)
        }
    }
}

struct MealCardView: View {
    let meal: MealRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(meal.mealName)
                    .font(.headline)
                Spacer()
                Text("Score \(meal.nutritionScore)")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
            }

            Text(meal.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                NutritionBadge(title: "kcal", value: meal.totalNutrition.calories)
                NutritionBadge(title: "P", value: meal.totalNutrition.protein, suffix: "g")
                NutritionBadge(title: "C", value: meal.totalNutrition.carbs, suffix: "g")
                NutritionBadge(title: "F", value: meal.totalNutrition.fat, suffix: "g")
            }
        }
        .padding(.vertical, 6)
    }
}

struct MealDetailView: View {
    let meal: MealRecord

    var body: some View {
        List {
            Section("Overview") {
                MealCardView(meal: meal)
                if !meal.notes.isEmpty {
                    Text(meal.notes)
                }
            }

            Section("Layers") {
                ForEach(meal.layers) { layer in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(layer.foodName)
                                .font(.headline)
                            Spacer()
                            Text(layer.category.title)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(layer.category.color.opacity(0.2), in: Capsule())
                        }
                        Text("\(Int(layer.estimatedWeightGrams)) g · \(layer.portionSize.rawValue.capitalized)")
                            .foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            NutritionBadge(title: "kcal", value: layer.nutrition.calories)
                            NutritionBadge(title: "P", value: layer.nutrition.protein, suffix: "g")
                            NutritionBadge(title: "C", value: layer.nutrition.carbs, suffix: "g")
                            NutritionBadge(title: "F", value: layer.nutrition.fat, suffix: "g")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(meal.mealName)
    }
}

struct NutritionBadge: View {
    let title: String
    let value: Double
    var suffix: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(Int(value.rounded()))\(suffix)")
                .font(.subheadline.bold())
        }
    }
}
