import Foundation
import UIKit

/// Service for analyzing food photos using OpenAI's GPT-4 Vision API
actor OpenAIVisionService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    struct FoodAnalysisResult: Codable {
        let foods: [DetectedFood]

        struct DetectedFood: Codable {
            let name: String
            let category: String
            let estimatedPortionGrams: Double
            let portionDescription: String
            let confidence: Double
            let nutrition: NutritionEstimate
        }

        struct NutritionEstimate: Codable {
            let calories: Double
            let protein: Double
            let carbohydrates: Double
            let fat: Double
            let fiber: Double
            let sugar: Double
            let sodium: Double
            let cholesterol: Double
            let saturatedFat: Double
            let vitaminA: Double
            let vitaminC: Double
            let calcium: Double
            let iron: Double
            let potassium: Double
        }
    }

    /// Analyze a food photo and return detected food items with nutrition estimates
    func analyzeImage(_ image: UIImage, layerContext: String = "") async throws -> FoodAnalysisResult {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw OpenAIError.imageConversionFailed
        }

        let base64Image = imageData.base64EncodedString()

        let contextPrompt = layerContext.isEmpty
            ? "This is a photo of food on a plate."
            : "This is a photo of the \(layerContext) of food on a plate."

        let systemPrompt = """
        You are a nutrition analysis expert. Analyze the food photo and identify all visible food items.
        For each food item, estimate the portion size and provide detailed nutrition information.

        Respond ONLY with valid JSON in this exact format:
        {
          "foods": [
            {
              "name": "food name",
              "category": "one of: Vegetable, Fruit, Protein, Grain, Dairy, Fat & Oil, Sauce & Condiment, Beverage, Other",
              "estimatedPortionGrams": 150.0,
              "portionDescription": "1 cup or descriptive portion",
              "confidence": 0.85,
              "nutrition": {
                "calories": 200.0,
                "protein": 25.0,
                "carbohydrates": 10.0,
                "fat": 8.0,
                "fiber": 2.0,
                "sugar": 1.0,
                "sodium": 400.0,
                "cholesterol": 70.0,
                "saturatedFat": 2.5,
                "vitaminA": 50.0,
                "vitaminC": 5.0,
                "calcium": 20.0,
                "iron": 2.0,
                "potassium": 300.0
              }
            }
          ]
        }

        Be as accurate as possible with portion estimation based on visual cues.
        Use standard USDA nutrition data as reference.
        """

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "\(contextPrompt) Please identify all food items and provide nutrition analysis."
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)",
                                "detail": "high"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 2000,
            "temperature": 0.3
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        // Parse the OpenAI response to extract the JSON content
        let openAIResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = openAIResponse?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.parsingFailed
        }

        // Extract JSON from the content (may be wrapped in markdown code blocks)
        let jsonString = extractJSON(from: content)

        guard let analysisData = jsonString.data(using: .utf8) else {
            throw OpenAIError.parsingFailed
        }

        let result = try JSONDecoder().decode(FoodAnalysisResult.self, from: analysisData)
        return result
    }

    /// Extract JSON from a string that may contain markdown code blocks
    private func extractJSON(from text: String) -> String {
        // Try to extract from ```json ... ``` blocks
        if let range = text.range(of: "```json\n"),
           let endRange = text.range(of: "\n```", range: range.upperBound..<text.endIndex) {
            return String(text[range.upperBound..<endRange.lowerBound])
        }
        // Try to extract from ``` ... ``` blocks
        if let range = text.range(of: "```\n"),
           let endRange = text.range(of: "\n```", range: range.upperBound..<text.endIndex) {
            return String(text[range.upperBound..<endRange.lowerBound])
        }
        // Assume the whole content is JSON
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum OpenAIError: LocalizedError {
    case imageConversionFailed
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image for analysis."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .parsingFailed:
            return "Failed to parse the food analysis results."
        }
    }
}
