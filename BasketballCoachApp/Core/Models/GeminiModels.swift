import Foundation

// MARK: - Gemini API Request Models

struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

enum GeminiPart: Codable {
    case text(String)
    case image(GeminiImagePart)
    
    enum CodingKeys: String, CodingKey {
        case text
        case inlineData
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .text(let text):
            try container.encode(text, forKey: .text)
        case .image(let imagePart):
            try container.encode(imagePart.inlineData, forKey: .inlineData)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let text = try? container.decode(String.self, forKey: .text) {
            self = .text(text)
        } else if let inlineData = try? container.decode(GeminiInlineData.self, forKey: .inlineData) {
            self = .image(GeminiImagePart(inlineData: inlineData))
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid GeminiPart data"
                )
            )
        }
    }
}

struct GeminiImagePart: Codable {
    let inlineData: GeminiInlineData
}

struct GeminiInlineData: Codable {
    let mimeType: String
    let data: String
}

struct GeminiGenerationConfig: Codable {
    let temperature: Double
    let maxOutputTokens: Int
    let topP: Double
}

// MARK: - Gemini API Response Models

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
    let usageMetadata: GeminiUsageMetadata?
    let promptFeedback: GeminiPromptFeedback?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
    let finishReason: String?
    let safetyRatings: [GeminiSafetyRating]?
    let citationMetadata: GeminiCitationMetadata?
}

struct GeminiUsageMetadata: Codable {
    let promptTokenCount: Int
    let candidatesTokenCount: Int
    let totalTokenCount: Int
}

struct GeminiPromptFeedback: Codable {
    let safetyRatings: [GeminiSafetyRating]
    let blockReason: String?
}

struct GeminiSafetyRating: Codable {
    let category: String
    let probability: String
    let blocked: Bool?
}

struct GeminiCitationMetadata: Codable {
    let citationSources: [GeminiCitationSource]
}

struct GeminiCitationSource: Codable {
    let startIndex: Int?
    let endIndex: Int?
    let uri: String?
    let license: String?
} 