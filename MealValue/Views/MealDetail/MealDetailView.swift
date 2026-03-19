import SwiftUI
import SwiftData

/// Detailed view of a recorded meal showing all layers and nutrition breakdown
struct MealDetailView: View {
    let meal: Meal
    @Environment(\.modelContext) private var context
    @State private var expandedLayerID: UUID?
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Meal header
                headerSection

                // Score and nutrition overview
                scoreSection

                // Nutrition breakdown
                NutritionSummaryCard(nutrition: meal.totalNutrition)
                    .padding(.horizontal)

                // Layers
                layersSection

                // Macro distribution
                macroDistribution

                // Delete button
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Meal")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle(meal.name.isEmpty ? meal.mealType.rawValue : meal.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Meal", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                context.delete(meal)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this meal? This cannot be undone.")
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: meal.mealType.icon)
                        .foregroundColor(.blue)
                    Text(meal.mealType.rawValue)
                        .font(.headline)
                }
                Text(meal.date.formatted(date: .complete, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if !meal.notes.isEmpty {
                    Text(meal.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }

            Spacer()

            NutritionScoreBadge(score: meal.nutritionScore)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var scoreSection: some View {
        HStack(spacing: 0) {
            StatColumn(value: "\(Int(meal.totalNutrition.calories))", label: "Calories", color: .orange)
            Divider().frame(height: 40)
            StatColumn(value: "\(Int(meal.totalNutrition.protein))g", label: "Protein", color: .red)
            Divider().frame(height: 40)
            StatColumn(value: "\(Int(meal.totalNutrition.carbohydrates))g", label: "Carbs", color: .blue)
            Divider().frame(height: 40)
            StatColumn(value: "\(Int(meal.totalNutrition.fat))g", label: "Fat", color: .yellow)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var layersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Food Layers (\(meal.layers.count))")
                .font(.headline)
                .padding(.horizontal)

            ForEach(meal.sortedLayers) { layer in
                LayerCard(
                    layer: layer,
                    isExpanded: expandedLayerID == layer.id
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        expandedLayerID = expandedLayerID == layer.id ? nil : layer.id
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var macroDistribution: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Macro Distribution")
                .font(.headline)
                .padding(.horizontal)

            let totalCal = meal.totalNutrition.calories
            let proteinCal = meal.totalNutrition.protein * 4
            let carbCal = meal.totalNutrition.carbohydrates * 4
            let fatCal = meal.totalNutrition.fat * 9

            if totalCal > 0 {
                HStack(spacing: 0) {
                    let protPct = proteinCal / (proteinCal + carbCal + fatCal)
                    let carbPct = carbCal / (proteinCal + carbCal + fatCal)
                    let fatPct = fatCal / (proteinCal + carbCal + fatCal)

                    MacroBar(label: "Protein", percentage: protPct, color: .red)
                    MacroBar(label: "Carbs", percentage: carbPct, color: .blue)
                    MacroBar(label: "Fat", percentage: fatPct, color: .yellow)
                }
                .frame(height: 24)
                .cornerRadius(12)
                .padding(.horizontal)

                HStack {
                    MacroLegend(label: "Protein", pct: proteinCal / (proteinCal + carbCal + fatCal) * 100, color: .red)
                    Spacer()
                    MacroLegend(label: "Carbs", pct: carbCal / (proteinCal + carbCal + fatCal) * 100, color: .blue)
                    Spacer()
                    MacroLegend(label: "Fat", pct: fatCal / (proteinCal + carbCal + fatCal) * 100, color: .yellow)
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct MacroBar: View {
    let label: String
    let percentage: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(color)
                .frame(width: geo.size.width * percentage)
        }
    }
}

struct MacroLegend: View {
    let label: String
    let pct: Double
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(label) \(Int(pct))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
