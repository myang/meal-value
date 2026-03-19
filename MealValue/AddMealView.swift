import PhotosUI
import SwiftUI

struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: MealStore

    @State private var mealName = ""
    @State private var notes = ""
    @State private var draftLayers: [LayerDraft] = [LayerDraft()]

    var body: some View {
        NavigationStack {
            Form {
                Section("Meal") {
                    TextField("Meal name", text: $mealName)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Food layers") {
                    ForEach($draftLayers) { $layer in
                        LayerDraftEditor(draft: $layer)
                    }
                    .onDelete { draftLayers.remove(atOffsets: $0) }

                    Button {
                        draftLayers.append(LayerDraft())
                    } label: {
                        Label("Add another layer", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("New Meal")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveMeal() }
                        .disabled(mealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || resolvedLayers.isEmpty)
                }
            }
        }
    }

    private var resolvedLayers: [LayerRecord] {
        draftLayers.compactMap { draft in
            guard let profile = draft.selectedProfile else { return nil }
            let weight = draft.manualWeight > 0 ? draft.manualWeight : profile.defaultWeightGrams * draft.portionSize.multiplier
            return LayerRecord(
                category: draft.category,
                foodName: profile.name,
                portionSize: draft.portionSize,
                estimatedWeightGrams: weight,
                nutrition: NutritionEngine.estimate(profile: profile, portion: draft.portionSize, manualWeight: weight),
                imageData: draft.imageData
            )
        }
    }

    private func saveMeal() {
        let meal = MealRecord(mealName: mealName, notes: notes, layers: resolvedLayers)
        store.addMeal(meal)
        dismiss()
    }
}

struct LayerDraft: Identifiable {
    let id = UUID()
    var category: FoodCategory = .vegetables
    var portionSize: PortionSize = .medium
    var selectedFoodName: String = ""
    var manualWeight: Double = 0
    var imageData: Data?
    var photoItem: PhotosPickerItem?

    var availableProfiles: [FoodProfile] { NutritionEngine.foods(for: category) }

    var selectedProfile: FoodProfile? {
        if let exact = availableProfiles.first(where: { $0.name == selectedFoodName }) {
            return exact
        }
        return availableProfiles.first
    }
}

struct LayerDraftEditor: View {
    @Binding var draft: LayerDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Layer")
                .font(.headline)

            Picker("Category", selection: $draft.category) {
                ForEach(FoodCategory.allCases) { category in
                    Text(category.title).tag(category)
                }
            }
            .onChange(of: draft.category) { _, newValue in
                draft.selectedFoodName = NutritionEngine.foods(for: newValue).first?.name ?? ""
            }

            Picker("Food", selection: $draft.selectedFoodName) {
                ForEach(draft.availableProfiles) { profile in
                    Text(profile.name).tag(profile.name)
                }
            }

            Picker("Portion", selection: $draft.portionSize) {
                ForEach(PortionSize.allCases) { portion in
                    Text(portion.rawValue.capitalized).tag(portion)
                }
            }

            HStack {
                Text("Estimated weight")
                Spacer()
                TextField("grams", value: $draft.manualWeight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                Text("g")
                    .foregroundStyle(.secondary)
            }

            PhotosPicker(selection: $draft.photoItem, matching: .images) {
                Label(draft.imageData == nil ? "Attach layer photo" : "Replace layer photo", systemImage: "camera")
            }
            .task(id: draft.photoItem) {
                guard let item = draft.photoItem,
                      let data = try? await item.loadTransferable(type: Data.self) else { return }
                draft.imageData = data
            }

            if let profile = draft.selectedProfile {
                let weight = draft.manualWeight > 0 ? draft.manualWeight : profile.defaultWeightGrams * draft.portionSize.multiplier
                let nutrition = NutritionEngine.estimate(profile: profile, portion: draft.portionSize, manualWeight: weight)
                HStack(spacing: 12) {
                    NutritionBadge(title: "kcal", value: nutrition.calories)
                    NutritionBadge(title: "P", value: nutrition.protein, suffix: "g")
                    NutritionBadge(title: "C", value: nutrition.carbs, suffix: "g")
                    NutritionBadge(title: "F", value: nutrition.fat, suffix: "g")
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            if draft.selectedFoodName.isEmpty {
                draft.selectedFoodName = draft.availableProfiles.first?.name ?? ""
            }
        }
    }
}
