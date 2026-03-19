import SwiftUI
import SwiftData
import Charts

/// Weekly and monthly nutrition summary with charts and advice
struct SummaryView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = SummaryViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period picker
                    Picker("Period", selection: $viewModel.selectedPeriod) {
                        ForEach(SummaryViewModel.SummaryPeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: viewModel.selectedPeriod) { _, _ in
                        viewModel.loadMeals(from: context)
                    }

                    if viewModel.meals.isEmpty {
                        emptyState
                    } else {
                        // Overview stats
                        overviewStats

                        // Calorie chart
                        calorieChart

                        // Macro breakdown chart
                        macroBreakdownChart

                        // Score trend chart
                        scoreTrendChart

                        // Nutrition advice
                        adviceSection
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Summary")
            .onAppear {
                viewModel.loadMeals(from: context)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Data Yet")
                .font(.title3)
                .fontWeight(.medium)
            Text("Record meals to see your nutrition summaries and trends here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }

    private var overviewStats: some View {
        VStack(spacing: 12) {
            Text("\(viewModel.selectedPeriod.rawValue)ly Overview")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                OverviewStatCard(
                    title: "Total Meals",
                    value: "\(viewModel.totalMeals)",
                    icon: "fork.knife",
                    color: .blue
                )
                OverviewStatCard(
                    title: "Avg Calories/Day",
                    value: "\(Int(viewModel.avgCaloriesPerDay))",
                    icon: "flame.fill",
                    color: .orange
                )
                OverviewStatCard(
                    title: "Avg Protein/Day",
                    value: "\(Int(viewModel.avgProteinPerDay))g",
                    icon: "fish.fill",
                    color: .red
                )
                OverviewStatCard(
                    title: "Avg Score",
                    value: "\(viewModel.avgScore)/100",
                    icon: "star.fill",
                    color: scoreColor(viewModel.avgScore)
                )
            }
            .padding(.horizontal)
        }
    }

    private var calorieChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Calories")
                .font(.headline)
                .padding(.horizontal)

            Chart(viewModel.dailySummaries) { day in
                BarMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Calories", day.calories)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)

                // Target line
                RuleMark(y: .value("Target", DailyRecommended.calories))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(.green.opacity(0.7))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Target")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
            }
            .chartYAxisLabel("kcal")
            .frame(height: 200)
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var macroBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Macro Distribution")
                .font(.headline)
                .padding(.horizontal)

            let macros = viewModel.macroBreakdown

            HStack(spacing: 20) {
                // Pie-like display using concentric arcs
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 20)

                    Circle()
                        .trim(from: 0, to: macros.proteinPct / 100)
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .trim(from: macros.proteinPct / 100, to: (macros.proteinPct + macros.carbPct) / 100)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .trim(from: (macros.proteinPct + macros.carbPct) / 100, to: 1.0)
                        .stroke(Color.yellow, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 12) {
                    MacroLegend(label: "Protein", pct: macros.proteinPct, color: .red)
                    MacroLegend(label: "Carbs", pct: macros.carbPct, color: .blue)
                    MacroLegend(label: "Fat", pct: macros.fatPct, color: .yellow)
                }
            }
            .frame(maxWidth: .infinity)

            // Stacked bar chart by day
            Chart(viewModel.dailySummaries) { day in
                BarMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Protein", day.protein * 4)
                )
                .foregroundStyle(by: .value("Macro", "Protein"))

                BarMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Carbs", day.carbohydrates * 4)
                )
                .foregroundStyle(by: .value("Macro", "Carbs"))

                BarMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Fat", day.fat * 9)
                )
                .foregroundStyle(by: .value("Macro", "Fat"))
            }
            .chartForegroundStyleScale([
                "Protein": Color.red,
                "Carbs": Color.blue,
                "Fat": Color.yellow
            ])
            .chartYAxisLabel("kcal from macros")
            .frame(height: 180)
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var scoreTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Score Trend")
                .font(.headline)
                .padding(.horizontal)

            Chart(viewModel.dailySummaries) { day in
                LineMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Score", day.avgScore)
                )
                .foregroundStyle(.green)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Score", day.avgScore)
                )
                .foregroundStyle(.green)

                AreaMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Score", day.avgScore)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green.opacity(0.3), .green.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartYScale(domain: 0...100)
            .chartYAxisLabel("Score")
            .frame(height: 160)
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var adviceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Nutrition Advice")
                    .font(.headline)
            }
            .padding(.horizontal)

            ForEach(viewModel.advice) { advice in
                AdviceCard(advice: advice)
                    .padding(.horizontal)
            }
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

struct OverviewStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            HStack {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct AdviceCard: View {
    let advice: NutritionAdviceEngine.Advice

    var priorityColor: Color {
        switch advice.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: advice.category.icon)
                .font(.title2)
                .foregroundColor(priorityColor)
                .frame(width: 40, height: 40)
                .background(priorityColor.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(advice.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(advice.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
