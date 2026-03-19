import SwiftUI

/// Card displaying a food layer with its photo and food items
struct LayerCard: View {
    let layer: FoodLayer
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Layer header
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text(layer.name)
                                .font(.headline)
                        }
                        Text("\(layer.foodItems.count) items - \(Int(layer.totalNutrition.calories)) kcal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Layer photo thumbnail
                    if let photoData = layer.photoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(isExpanded ? 0 : 12)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(spacing: 0) {
                    // Photo preview
                    if let photoData = layer.photoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(0)
                    }

                    // Food items list
                    VStack(spacing: 0) {
                        ForEach(layer.foodItems) { item in
                            FoodItemRow(item: item)
                                .padding(.horizontal)
                            if item.id != layer.foodItems.last?.id {
                                Divider().padding(.leading, 60)
                            }
                        }
                    }
                    .padding(.vertical, 8)

                    // Layer nutrition summary
                    HStack {
                        NutritionPill(label: "Calories", value: "\(Int(layer.totalNutrition.calories))", color: .orange)
                        NutritionPill(label: "Protein", value: "\(Int(layer.totalNutrition.protein))g", color: .red)
                        NutritionPill(label: "Carbs", value: "\(Int(layer.totalNutrition.carbohydrates))g", color: .blue)
                        NutritionPill(label: "Fat", value: "\(Int(layer.totalNutrition.fat))g", color: .yellow)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(12)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
}

struct NutritionPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
