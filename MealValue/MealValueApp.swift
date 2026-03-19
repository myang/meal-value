import SwiftUI

@main
struct MealValueApp: App {
    @StateObject private var store = MealStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
