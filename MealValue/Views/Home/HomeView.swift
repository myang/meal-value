import SwiftUI
import SwiftData

/// Main home screen showing today's meals and quick actions
struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(
        filter: #Predicate<Meal> { $0.isAnalyzed },
        sort: \Meal.date,
        order: .reverse
    )
    private var allMeals: [Meal]

    @State private var showNewMealSheet = false
    @State private var selectedMealType: MealType = .lunch

    private var todaysMeals: [Meal] {
        let calendar = Calendar.current
        return allMeals.filter { calendar.isDateInToday($0.date) }
    }

    private var todayCalories: Double {
        todaysMeals.reduce(0) { $0 + $1.totalNutrition.calories }
    }

    private var todayProtein: Double {
        todaysMeals.reduce(0) { $0 + $1.totalNutrition.protein }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's summary header
                    todaySummaryCard

                    // Quick add button
                    Button {
                        showNewMealSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Record New Meal")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)

                    // Today's meals
                    if !todaysMeals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today's Meals")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            ForEach(todaysMeals) { meal in
                                NavigationLink(value: meal) {
                                    MealListRow(meal: meal)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Recent meals
                    if allMeals.count > todaysMeals.count {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Meals")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            ForEach(allMeals.prefix(10).filter { meal in
                                !Calendar.current.isDateInToday(meal.date)
                            }) { meal in
                                NavigationLink(value: meal) {
                                    MealListRow(meal: meal)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }
                    }

                    if allMeals.isEmpty {
                        emptyStateView
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("MealValue")
            .navigationDestination(for: Meal.self) { meal in
                MealDetailView(meal: meal)
            }
            .sheet(isPresented: $showNewMealSheet) {
                NewMealSheet(selectedType: $selectedMealType)
            }
        }
    }

    private var todaySummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 0) {
                StatColumn(value: "\(Int(todayCalories))", label: "Calories", color: .orange)
                Divider().frame(height: 40)
                StatColumn(value: "\(Int(todayProtein))g", label: "Protein", color: .red)
                Divider().frame(height: 40)
                StatColumn(value: "\(todaysMeals.count)", label: "Meals", color: .blue)
                Divider().frame(height: 40)

                let avgScore = todaysMeals.isEmpty ? 0 : todaysMeals.reduce(0) { $0 + $1.nutritionScore } / todaysMeals.count
                StatColumn(value: "\(avgScore)", label: "Avg Score", color: scoreColor(avgScore))
            }

            // Calorie progress bar
            let target = UserDefaults.standard.double(forKey: "daily_calorie_target")
            let calorieTarget = target > 0 ? target : DailyRecommended.calories
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Daily Calorie Target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(todayCalories)) / \(Int(calorieTarget))")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(todayCalories > calorieTarget ? Color.red : Color.green)
                            .frame(width: geo.size.width * min(todayCalories / calorieTarget, 1.0))
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Meals Recorded Yet")
                .font(.title3)
                .fontWeight(.medium)
            Text("Tap \"Record New Meal\" to photograph your plate layer by layer and get nutrition analysis.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
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

struct StatColumn: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MealListRow: View {
    let meal: Meal

    var body: some View {
        HStack(spacing: 12) {
            // Meal type icon
            Image(systemName: meal.mealType.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name.isEmpty ? meal.mealType.rawValue : meal.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 8) {
                    Text(meal.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(meal.layers.count) layers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(meal.totalNutrition.calories)) kcal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                NutritionScoreBadge(score: meal.nutritionScore)
                    .scaleEffect(0.5)
                    .frame(width: 30, height: 40)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

/// Sheet for choosing meal type before recording
struct NewMealSheet: View {
    @Binding var selectedType: MealType
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToRecording = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("What meal are you recording?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(MealType.allCases) { type in
                        Button {
                            selectedType = type
                            navigateToRecording = true
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 36))
                                Text(type.rawValue)
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("New Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $navigateToRecording) {
                MealRecordingView(mealType: selectedType)
            }
        }
    }
}
