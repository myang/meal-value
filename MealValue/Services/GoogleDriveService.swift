import Foundation
import AuthenticationServices
import UIKit

/// Service for syncing meal data to Google Drive
/// Uses Google Drive REST API with OAuth 2.0
actor GoogleDriveService {
    private var accessToken: String?
    private let clientID: String
    private let redirectURI = "com.mealvalue.app:/oauth2redirect"
    private let driveAPIBase = "https://www.googleapis.com/drive/v3"
    private let uploadBase = "https://www.googleapis.com/upload/drive/v3"
    private let folderName = "MealValue Data"
    private var folderID: String?

    init(clientID: String) {
        self.clientID = clientID
    }

    // MARK: - Authentication

    /// Generate the OAuth URL for sign-in
    func authURL() -> URL {
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "token"),
            URLQueryItem(name: "scope", value: "https://www.googleapis.com/auth/drive.file"),
            URLQueryItem(name: "include_granted_scopes", value: "true")
        ]
        return components.url!
    }

    /// Set the access token after OAuth callback
    func setAccessToken(_ token: String) {
        self.accessToken = token
        // Store token securely in Keychain
        KeychainHelper.save(key: "google_drive_token", value: token)
    }

    /// Load saved token from Keychain
    func loadSavedToken() -> Bool {
        if let token = KeychainHelper.load(key: "google_drive_token") {
            self.accessToken = token
            return true
        }
        return false
    }

    /// Sign out and clear stored credentials
    func signOut() {
        self.accessToken = nil
        self.folderID = nil
        KeychainHelper.delete(key: "google_drive_token")
    }

    var isAuthenticated: Bool {
        accessToken != nil
    }

    // MARK: - Folder Management

    /// Get or create the MealValue folder in Google Drive
    private func ensureFolder() async throws -> String {
        if let folderID { return folderID }

        guard let token = accessToken else { throw DriveError.notAuthenticated }

        // Search for existing folder
        let query = "name='\(folderName)' and mimeType='application/vnd.google-apps.folder' and trashed=false"
        var searchURL = URLComponents(string: "\(driveAPIBase)/files")!
        searchURL.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fields", value: "files(id,name)")
        ]

        var request = URLRequest(url: searchURL.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let searchResult = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        if let files = searchResult?["files"] as? [[String: Any]],
           let firstFile = files.first,
           let id = firstFile["id"] as? String {
            self.folderID = id
            return id
        }

        // Create folder
        let folderMeta: [String: Any] = [
            "name": folderName,
            "mimeType": "application/vnd.google-apps.folder"
        ]
        let folderData = try JSONSerialization.data(withJSONObject: folderMeta)

        var createRequest = URLRequest(url: URL(string: "\(driveAPIBase)/files")!)
        createRequest.httpMethod = "POST"
        createRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        createRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        createRequest.httpBody = folderData

        let (createData, _) = try await URLSession.shared.data(for: createRequest)
        let createResult = try JSONSerialization.jsonObject(with: createData) as? [String: Any]

        guard let newID = createResult?["id"] as? String else {
            throw DriveError.folderCreationFailed
        }

        self.folderID = newID
        return newID
    }

    // MARK: - Data Sync

    /// Export all meals to Google Drive as a JSON file
    func exportMeals(_ meals: [MealExportData]) async throws {
        let parentID = try await ensureFolder()
        guard let token = accessToken else { throw DriveError.notAuthenticated }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(meals)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let fileName = "meals_\(dateFormatter.string(from: Date())).json"

        // Use multipart upload
        let boundary = UUID().uuidString
        var body = Data()

        // Metadata part
        let metadata: [String: Any] = [
            "name": fileName,
            "parents": [parentID]
        ]
        let metadataData = try JSONSerialization.data(withJSONObject: metadata)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(metadataData)
        body.append("\r\n".data(using: .utf8)!)

        // File content part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        body.append(jsonData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: URL(string: "\(uploadBase)/files?uploadType=multipart")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DriveError.uploadFailed
        }
    }

    /// Export a single meal's photo to Google Drive
    func exportPhoto(_ imageData: Data, mealName: String, layerName: String) async throws {
        let parentID = try await ensureFolder()
        guard let token = accessToken else { throw DriveError.notAuthenticated }

        let fileName = "\(mealName)_\(layerName).jpg"

        let boundary = UUID().uuidString
        var body = Data()

        let metadata: [String: Any] = [
            "name": fileName,
            "parents": [parentID]
        ]
        let metadataData = try JSONSerialization.data(withJSONObject: metadata)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(metadataData)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: URL(string: "\(uploadBase)/files?uploadType=multipart")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DriveError.uploadFailed
        }
    }

    /// List all backup files in the MealValue folder
    func listBackups() async throws -> [(id: String, name: String, date: Date)] {
        let parentID = try await ensureFolder()
        guard let token = accessToken else { throw DriveError.notAuthenticated }

        let query = "'\(parentID)' in parents and mimeType='application/json' and trashed=false"
        var searchURL = URLComponents(string: "\(driveAPIBase)/files")!
        searchURL.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fields", value: "files(id,name,createdTime)"),
            URLQueryItem(name: "orderBy", value: "createdTime desc")
        ]

        var request = URLRequest(url: searchURL.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let files = result?["files"] as? [[String: Any]] else {
            return []
        }

        let dateFormatter = ISO8601DateFormatter()

        return files.compactMap { file in
            guard let id = file["id"] as? String,
                  let name = file["name"] as? String,
                  let dateStr = file["createdTime"] as? String,
                  let date = dateFormatter.date(from: dateStr) else {
                return nil
            }
            return (id: id, name: name, date: date)
        }
    }

    /// Download a backup file from Google Drive
    func downloadBackup(fileID: String) async throws -> [MealExportData] {
        guard let token = accessToken else { throw DriveError.notAuthenticated }

        var request = URLRequest(url: URL(string: "\(driveAPIBase)/files/\(fileID)?alt=media")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([MealExportData].self, from: data)
    }
}

enum DriveError: LocalizedError {
    case notAuthenticated
    case folderCreationFailed
    case uploadFailed
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not signed in to Google Drive."
        case .folderCreationFailed: return "Failed to create MealValue folder in Google Drive."
        case .uploadFailed: return "Failed to upload data to Google Drive."
        case .downloadFailed: return "Failed to download data from Google Drive."
        }
    }
}

// MARK: - Keychain Helper

enum KeychainHelper {
    static func save(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
