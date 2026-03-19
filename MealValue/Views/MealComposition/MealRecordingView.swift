import SwiftUI
import SwiftData

/// Main view for recording a meal layer by layer
struct MealRecordingView: View {
    let mealType: MealType
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MealViewModel()
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showManualEntry = false
    @State private var capturedImage: UIImage?
    @State private var layerName = ""
    @State private var showAddLayerAlert = false
    @State private var showSaveConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Meal info header
                mealHeader

                // Current layers
                if let meal = viewModel.currentMeal, !meal.layers.isEmpty {
                    layersSection(meal: meal)
                }

                // Add layer section
                addLayerSection

                // Analysis status
                if viewModel.isAnalyzing {
                    analysisProgressView
                }

                if let error = viewModel.analysisError {
                    errorView(error)
                }

                // Save button
                if let meal = viewModel.currentMeal, !meal.layers.isEmpty {
                    saveButton(meal: meal)
                }
            }
            .padding()
        }
        .navigationTitle("Record \(mealType.rawValue)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startNewMeal(type: mealType)
        }
        .sheet(isPresented: $showCamera) {
            CameraView(image: $capturedImage, isPresented: $showCamera, sourceType: .camera)
        }
        .sheet(isPresented: $showPhotoLibrary) {
            CameraView(image: $capturedImage, isPresented: $showPhotoLibrary, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showManualEntry) {
            ManualFoodEntryView { name, ref, grams in
                viewModel.addManualFoodItem(name: name, ref: ref, grams: grams)
            }
        }
        .onChange(of: capturedImage) { _, newImage in
            if let image = newImage {
                viewModel.setPhotoForCurrentLayer(image)
                Task {
                    await viewModel.analyzeCurrentLayer()
                }
                capturedImage = nil
            }
        }
        .alert("Add Layer", isPresented: $showAddLayerAlert) {
            TextField("Layer name (e.g., Base - Vegetables)", text: $layerName)
            Button("Add") {
                let name = layerName.isEmpty ? "Layer \(( viewModel.currentMeal?.layers.count ?? 0) + 1)" : layerName
                viewModel.addLayer(name: name)
                layerName = ""
            }
            Button("Cancel", role: .cancel) { layerName = "" }
        } message: {
            Text("Give this layer a descriptive name")
        }
    }

    private var mealHeader: some View {
        HStack {
            Image(systemName: mealType.icon)
                .font(.title)
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(mealType.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(Date().formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()

            if let meal = viewModel.currentMeal {
                NutritionScoreBadge(score: meal.nutritionScore)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func layersSection(meal: Meal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Layers (\(meal.layers.count))")
                .font(.headline)

            ForEach(Array(meal.sortedLayers.enumerated()), id: \.element.id) { index, layer in
                LayerRecordingCard(
                    layer: layer,
                    isCurrentLayer: index == viewModel.currentLayerIndex,
                    onSelectLayer: {
                        viewModel.currentLayerIndex = index
                    },
                    onTakePhoto: {
                        viewModel.currentLayerIndex = index
                        showCamera = true
                    },
                    onPickPhoto: {
                        viewModel.currentLayerIndex = index
                        showPhotoLibrary = true
                    },
                    onAddManual: {
                        viewModel.currentLayerIndex = index
                        showManualEntry = true
                    },
                    onRemoveItem: { item in
                        viewModel.removeFoodItem(item, from: layer)
                    }
                )
            }

            // Total nutrition
            if meal.totalNutrition.calories > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meal Total")
                        .font(.headline)
                    NutritionSummaryCard(nutrition: meal.totalNutrition)
                }
            }
        }
    }

    private var addLayerSection: some View {
        VStack(spacing: 12) {
            Button {
                showAddLayerAlert = true
            } label: {
                HStack {
                    Image(systemName: "plus.square.on.square")
                    Text("Add Food Layer")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                )
            }

            // Quick add suggestions
            if viewModel.currentMeal?.layers.isEmpty ?? true {
                VStack(spacing: 8) {
                    Text("Suggested layer order:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        SuggestionChip(text: "Base - Vegetables") {
                            viewModel.addLayer(name: "Base - Vegetables")
                        }
                        SuggestionChip(text: "Middle - Grains") {
                            viewModel.addLayer(name: "Middle - Grains")
                        }
                        SuggestionChip(text: "Top - Protein") {
                            viewModel.addLayer(name: "Top - Protein")
                        }
                    }
                }
            }
        }
    }

    private var analysisProgressView: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Analyzing food with AI...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    private func errorView(_ error: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button("Manual Entry") {
                showManualEntry = true
            }
            .font(.caption)
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    private func saveButton(meal: Meal) -> some View {
        Button {
            viewModel.finalizeMeal(context: context)
            dismiss()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save Meal")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
    }
}

/// Card for a layer during recording, with photo capture and food management
struct LayerRecordingCard: View {
    let layer: FoodLayer
    let isCurrentLayer: Bool
    let onSelectLayer: () -> Void
    let onTakePhoto: () -> Void
    let onPickPhoto: () -> Void
    let onAddManual: () -> Void
    let onRemoveItem: (FoodItem) -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "square.stack.3d.up.fill")
                        .foregroundColor(isCurrentLayer ? .blue : .secondary)
                    Text(layer.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    if !layer.foodItems.isEmpty {
                        Text("\(Int(layer.totalNutrition.calories)) kcal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(isCurrentLayer ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 12) {
                    // Photo section
                    if let photoData = layer.photoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .cornerRadius(8)
                            .padding(.horizontal)
                    } else {
                        // Photo capture buttons
                        PhotoSourcePicker(
                            showCamera: .init(
                                get: { false },
                                set: { if $0 { onTakePhoto() } }
                            ),
                            showPhotoLibrary: .init(
                                get: { false },
                                set: { if $0 { onPickPhoto() } }
                            )
                        )
                    }

                    // Food items
                    if !layer.foodItems.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(layer.foodItems) { item in
                                FoodItemRow(item: item) {
                                    onRemoveItem(item)
                                }
                                .padding(.horizontal)
                                if item.id != layer.foodItems.last?.id {
                                    Divider().padding(.leading, 60)
                                }
                            }
                        }
                    }

                    // Manual add button
                    Button(action: {
                        onSelectLayer()
                        onAddManual()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Food Manually")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    .padding(.bottom, 12)
                }
            }
        }
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentLayer ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

struct SuggestionChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(20)
        }
    }
}
