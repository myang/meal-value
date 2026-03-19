import Foundation
import SwiftData

/// ViewModel for app settings
@Observable
final class SettingsViewModel {
    var openAIApiKey: String {
        didSet { UserDefaults.standard.set(openAIApiKey, forKey: "openai_api_key") }
    }
    var googleClientID: String {
        didSet { UserDefaults.standard.set(googleClientID, forKey: "google_client_id") }
    }
    var isGoogleDriveConnected: Bool = false
    var autoSyncEnabled: Bool {
        didSet { UserDefaults.standard.set(autoSyncEnabled, forKey: "auto_sync_enabled") }
    }
    var dailyCalorieTarget: Double {
        didSet { UserDefaults.standard.set(dailyCalorieTarget, forKey: "daily_calorie_target") }
    }
    var isSyncing: Bool = false
    var syncError: String?
    var lastSyncDate: Date?

    private var driveService: GoogleDriveService?

    init() {
        self.openAIApiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
        self.googleClientID = UserDefaults.standard.string(forKey: "google_client_id") ?? ""
        self.autoSyncEnabled = UserDefaults.standard.bool(forKey: "auto_sync_enabled")
        self.dailyCalorieTarget = UserDefaults.standard.double(forKey: "daily_calorie_target")
        if dailyCalorieTarget == 0 { dailyCalorieTarget = 2000 }

        if !googleClientID.isEmpty {
            driveService = GoogleDriveService(clientID: googleClientID)
        }
    }

    /// Initialize Google Drive service
    func setupDriveService() {
        guard !googleClientID.isEmpty else { return }
        driveService = GoogleDriveService(clientID: googleClientID)
        Task {
            if let service = driveService {
                isGoogleDriveConnected = await service.loadSavedToken()
            }
        }
    }

    /// Export all meals to Google Drive
    func syncToGoogleDrive(context: ModelContext) async {
        guard let service = driveService else {
            syncError = "Google Drive not configured."
            return
        }

        isSyncing = true
        syncError = nil

        do {
            let descriptor = FetchDescriptor<Meal>(
                predicate: #Predicate { $0.isAnalyzed },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let meals = try context.fetch(descriptor)
            let exportData = meals.map { MealExportData(from: $0) }

            try await service.exportMeals(exportData)

            // Also export photos
            for meal in meals {
                for layer in meal.sortedLayers {
                    if let photoData = layer.photoData {
                        try await service.exportPhoto(
                            photoData,
                            mealName: "\(meal.mealType.rawValue)_\(meal.date.formatted(date: .numeric, time: .omitted))",
                            layerName: layer.name
                        )
                    }
                }
            }

            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "last_sync_date")
        } catch {
            syncError = error.localizedDescription
        }

        isSyncing = false
    }

    /// Sign out of Google Drive
    func signOutGoogleDrive() async {
        guard let service = driveService else { return }
        await service.signOut()
        isGoogleDriveConnected = false
    }
}
