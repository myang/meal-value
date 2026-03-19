import SwiftUI
import SwiftData

/// Settings view for API keys, Google Drive sync, and preferences
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = SettingsViewModel()
    @State private var showAPIKeyInfo = false

    var body: some View {
        NavigationStack {
            Form {
                // OpenAI API Configuration
                Section {
                    SecureField("OpenAI API Key", text: $viewModel.openAIApiKey)
                        .textContentType(.password)

                    Button {
                        showAPIKeyInfo = true
                    } label: {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("How to get an API key")
                        }
                        .font(.caption)
                    }
                } header: {
                    Label("ChatGPT Food Recognition", systemImage: "sparkles")
                } footer: {
                    Text("Your OpenAI API key is used to analyze food photos with GPT-4 Vision. The key is stored securely on your device.")
                }

                // Google Drive Sync
                Section {
                    TextField("Google Client ID", text: $viewModel.googleClientID)
                        .textContentType(.URL)
                        .onChange(of: viewModel.googleClientID) { _, _ in
                            viewModel.setupDriveService()
                        }

                    HStack {
                        Text("Status")
                        Spacer()
                        if viewModel.isGoogleDriveConnected {
                            Label("Connected", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Label("Not Connected", systemImage: "xmark.circle")
                                .foregroundColor(.secondary)
                        }
                    }

                    Toggle("Auto-sync after saving meals", isOn: $viewModel.autoSyncEnabled)

                    Button {
                        Task {
                            await viewModel.syncToGoogleDrive(context: context)
                        }
                    } label: {
                        HStack {
                            if viewModel.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(viewModel.isSyncing ? "Syncing..." : "Sync Now")
                        }
                    }
                    .disabled(viewModel.isSyncing || !viewModel.isGoogleDriveConnected)

                    if let error = viewModel.syncError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    if let lastSync = viewModel.lastSyncDate {
                        HStack {
                            Text("Last sync")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if viewModel.isGoogleDriveConnected {
                        Button(role: .destructive) {
                            Task { await viewModel.signOutGoogleDrive() }
                        } label: {
                            Text("Sign Out of Google Drive")
                        }
                    }
                } header: {
                    Label("Google Drive Storage", systemImage: "icloud")
                } footer: {
                    Text("All meal data and photos are synced to a \"MealValue Data\" folder in your Google Drive.")
                }

                // Nutrition Targets
                Section {
                    HStack {
                        Text("Daily Calories")
                        Spacer()
                        TextField("", value: $viewModel.dailyCalorieTarget, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kcal")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Label("Nutrition Targets", systemImage: "target")
                }

                // Data Management
                Section {
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        HStack {
                            Image(systemName: "externaldrive")
                            Text("Data Management")
                        }
                    }
                } header: {
                    Label("Data", systemImage: "cylinder.split.1x2")
                }

                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Label("About", systemImage: "info.circle")
                }
            }
            .navigationTitle("Settings")
            .alert("Getting an OpenAI API Key", isPresented: $showAPIKeyInfo) {
                Button("OK") {}
            } message: {
                Text("1. Go to platform.openai.com\n2. Sign in or create an account\n3. Go to API Keys section\n4. Create a new secret key\n5. Copy and paste it here\n\nNote: API usage incurs charges from OpenAI.")
            }
        }
    }
}

/// View for data management (export, clear data)
struct DataManagementView: View {
    @Environment(\.modelContext) private var context
    @State private var showClearConfirmation = false
    @State private var mealCount = 0

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Total Meals Recorded")
                    Spacer()
                    Text("\(mealCount)")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Clear All Data")
                    }
                    .foregroundColor(.red)
                }
            } footer: {
                Text("This will permanently delete all meal records from your device. Data synced to Google Drive will not be affected.")
            }
        }
        .navigationTitle("Data Management")
        .onAppear { countMeals() }
        .alert("Clear All Data", isPresented: $showClearConfirmation) {
            Button("Delete All", role: .destructive) {
                clearAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all \(mealCount) meal records. This cannot be undone.")
        }
    }

    private func countMeals() {
        let descriptor = FetchDescriptor<Meal>()
        mealCount = (try? context.fetchCount(descriptor)) ?? 0
    }

    private func clearAllData() {
        do {
            try context.delete(model: Meal.self)
            try context.save()
            mealCount = 0
        } catch {
            // Handle error silently
        }
    }
}
