import SwiftUI

/// Row display for a single food item
struct FoodItemRow: View {
    let item: FoodItem
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.category.icon)
                .font(.title3)
                .foregroundColor(categoryColor)
                .frame(width: 36, height: 36)
                .background(categoryColor.opacity(0.15))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(item.portionDescription.isEmpty ? "\(Int(item.portionGrams))g" : item.portionDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if item.confidence < 1.0 {
                        HStack(spacing: 2) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                            Text("\(Int(item.confidence * 100))%")
                                .font(.caption2)
                        }
                        .foregroundColor(.purple)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(item.nutrition.calories)) kcal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("P:\(Int(item.nutrition.protein))g C:\(Int(item.nutrition.carbohydrates))g F:\(Int(item.nutrition.fat))g")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        switch item.category {
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
