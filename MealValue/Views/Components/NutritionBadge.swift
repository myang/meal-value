import SwiftUI

/// Displays a nutrition score as a colored badge
struct NutritionScoreBadge: View {
    let score: Int

    var color: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    var label: String {
        switch score {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        default: return "Needs Work"
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: Double(score) / 100.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: score)
                Text("\(score)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            .frame(width: 56, height: 56)

            Text(label)
                .font(.caption2)
                .foregroundColor(color)
                .fontWeight(.medium)
        }
    }
}

/// Compact macro nutrient display
struct MacroNutrientRow: View {
    let label: String
    let value: Double
    let unit: String
    let dailyTarget: Double
    let color: Color

    var percentage: Double {
        guard dailyTarget > 0 else { return 0 }
        return min(value / dailyTarget, 1.5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(value))\(unit)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.15))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * min(percentage, 1.0))
                }
            }
            .frame(height: 6)
        }
    }
}

/// Nutrition summary card showing key macros
struct NutritionSummaryCard: View {
    let nutrition: NutritionInfo

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack {
                    Text("\(Int(nutrition.calories))")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("kcal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 40)

                VStack {
                    Text("\(Int(nutrition.protein))g")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    Text("Protein")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 40)

                VStack {
                    Text("\(Int(nutrition.carbohydrates))g")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    Text("Carbs")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 40)

                VStack {
                    Text("\(Int(nutrition.fat))g")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.yellow)
                    Text("Fat")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            Divider()

            VStack(spacing: 8) {
                MacroNutrientRow(label: "Fiber", value: nutrition.fiber, unit: "g",
                                 dailyTarget: DailyRecommended.fiber, color: .green)
                MacroNutrientRow(label: "Sodium", value: nutrition.sodium, unit: "mg",
                                 dailyTarget: DailyRecommended.sodium, color: .orange)
                MacroNutrientRow(label: "Vitamin C", value: nutrition.vitaminC, unit: "mg",
                                 dailyTarget: DailyRecommended.vitaminC, color: .cyan)
                MacroNutrientRow(label: "Calcium", value: nutrition.calcium, unit: "mg",
                                 dailyTarget: DailyRecommended.calcium, color: .blue)
                MacroNutrientRow(label: "Iron", value: nutrition.iron, unit: "mg",
                                 dailyTarget: DailyRecommended.iron, color: .brown)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        NutritionScoreBadge(score: 85)
        NutritionScoreBadge(score: 62)
        NutritionScoreBadge(score: 35)
    }
    .padding()
}
