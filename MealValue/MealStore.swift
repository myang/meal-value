import Foundation

@MainActor
final class MealStore: ObservableObject {
    @Published private(set) var meals: [MealRecord] = []

    private let saveURL: URL

    init() {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.saveURL = base.appendingPathComponent("meal-value-history.json")
        load()
    }

    func addMeal(_ meal: MealRecord) {
        meals.insert(meal, at: 0)
        save()
    }

    func meals(inLastDays days: Int) -> [MealRecord] {
        guard let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else { return meals }
        return meals.filter { $0.createdAt >= start }
    }

    func weeklyMeals() -> [MealRecord] { meals(inLastDays: 7) }
    func monthlyMeals() -> [MealRecord] { meals(inLastDays: 30) }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL) else { return }
        do {
            meals = try JSONDecoder().decode([MealRecord].self, from: data)
        } catch {
            print("Failed to decode meals: \(error)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(meals)
            try data.write(to: saveURL, options: [.atomic])
        } catch {
            print("Failed to save meals: \(error)")
        }
    }
}
