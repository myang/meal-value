import SwiftUI

/// View for manually selecting food items from the built-in database
struct ManualFoodEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory?
    @State private var selectedFood: (name: String, ref: FoodReference)?
    @State private var portionGrams: Double = 100

    var onAdd: (String, FoodReference, Double) -> Void

    private var filteredFoods: [(name: String, ref: FoodReference)] {
        var results: [(name: String, ref: FoodReference)]

        if !searchText.isEmpty {
            results = NutritionDatabase.lookup(searchText)
        } else if let category = selectedCategory {
            results = NutritionDatabase.foods(in: category)
        } else {
            results = NutritionDatabase.foods.map { (name: $0.key, ref: $0.value) }
                .sorted { $0.name < $1.name }
        }

        return results
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search foods...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding()

                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryFilterChip(
                            label: "All",
                            icon: "square.grid.2x2",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }

                        ForEach(FoodCategory.allCases) { category in
                            CategoryFilterChip(
                                label: category.rawValue,
                                icon: category.icon,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Food list or portion selector
                if let food = selectedFood {
                    portionSelector(food: food)
                } else {
                    foodList
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var foodList: some View {
        List(filteredFoods, id: \.name) { food in
            Button {
                selectedFood = food
                portionGrams = food.ref.typicalPortionG
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: food.ref.category.icon)
                        .foregroundColor(categoryColor(food.ref.category))
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(food.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Text("\(Int(food.ref.caloriesPer100g)) kcal/100g - \(food.ref.typicalPortionDesc)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.plain)
    }

    private func portionSelector(food: (name: String, ref: FoodReference)) -> some View {
        VStack(spacing: 20) {
            Spacer()

            // Food info
            VStack(spacing: 8) {
                Image(systemName: food.ref.category.icon)
                    .font(.system(size: 40))
                    .foregroundColor(categoryColor(food.ref.category))

                Text(food.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(food.ref.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Portion slider
            VStack(spacing: 8) {
                Text("Portion Size")
                    .font(.headline)

                Text("\(Int(portionGrams))g")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)

                Slider(value: $portionGrams, in: 10...500, step: 5)
                    .tint(.blue)
                    .padding(.horizontal, 20)

                // Quick portion buttons
                HStack(spacing: 12) {
                    PortionButton(label: "½x", grams: food.ref.typicalPortionG * 0.5) {
                        portionGrams = food.ref.typicalPortionG * 0.5
                    }
                    PortionButton(label: "1x", grams: food.ref.typicalPortionG) {
                        portionGrams = food.ref.typicalPortionG
                    }
                    PortionButton(label: "1.5x", grams: food.ref.typicalPortionG * 1.5) {
                        portionGrams = food.ref.typicalPortionG * 1.5
                    }
                    PortionButton(label: "2x", grams: food.ref.typicalPortionG * 2) {
                        portionGrams = food.ref.typicalPortionG * 2
                    }
                }
            }

            // Preview nutrition for selected portion
            let nutrition = food.ref.nutritionFor(grams: portionGrams)
            VStack(spacing: 8) {
                Text("Nutrition for \(Int(portionGrams))g")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    NutritionPill(label: "Calories", value: "\(Int(nutrition.calories))", color: .orange)
                    NutritionPill(label: "Protein", value: "\(Int(nutrition.protein))g", color: .red)
                    NutritionPill(label: "Carbs", value: "\(Int(nutrition.carbohydrates))g", color: .blue)
                    NutritionPill(label: "Fat", value: "\(Int(nutrition.fat))g", color: .yellow)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    selectedFood = nil
                } label: {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }

                Button {
                    onAdd(food.name, food.ref, portionGrams)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func categoryColor(_ category: FoodCategory) -> Color {
        switch category {
        case .vegetable: return .green
        case .fruit: return .orange
        case .protein: return .red
        case .grain: return .brown
        case .dairy: return .blue
        case .fat: return .yellow
        case .sauce: return .purple
        case .beverage: return .cyan
        case .other: return .gray
        }
    }
}

struct CategoryFilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct PortionButton: View {
    let label: String
    let grams: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.bold)
                Text("\(Int(grams))g")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
