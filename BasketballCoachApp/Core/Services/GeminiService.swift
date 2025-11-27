import Foundation
import UIKit
import os.log

/// Service for integrating with Google Gemini API for advanced basketball analysis
class GeminiService: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "BasketballCoachApp", category: "GeminiService")
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private let session: URLSession
    
    // Configuration
    private let maxRetries = 3
    private let timeoutInterval: TimeInterval = 30.0
    
    // State management
    @Published var isAnalyzing = false
    @Published var lastAnalysisTime: Date?
    @Published var analysisCount = 0
    
    // MARK: - Initialization
    
    init(apiKey: String) {
        self.apiKey = apiKey
        
        // Configure URL session for API requests
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval * 2
        self.session = URLSession(configuration: config)
        
        logger.info("GeminiService initialized")
    }
    
    // MARK: - Public API
    
    /// Analyze shooting form and provide advanced feedback
    /// - Parameter shotAnalysis: Basic shot analysis from ComputerVisionService
    /// - Returns: Enhanced analysis with detailed coaching feedback
    func enhanceShotAnalysis(_ shotAnalysis: ShotAnalysis) async throws -> EnhancedShotAnalysis {
        logger.info("Starting enhanced shot analysis for \(shotAnalysis.shotType.description)")
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            // Create prompt for shot analysis
            let prompt = createShotAnalysisPrompt(from: shotAnalysis)
            
            // Send to Gemini API
            let response = try await sendToGemini(prompt: prompt, type: .shotAnalysis)
            
            // Parse response
            let enhancedAnalysis = try parseEnhancedAnalysis(response, originalAnalysis: shotAnalysis)
            
            // Update state
            lastAnalysisTime = Date()
            analysisCount += 1
            
            logger.info("Enhanced shot analysis completed successfully")
            return enhancedAnalysis
            
        } catch {
            logger.error("Enhanced shot analysis failed: \(error.localizedDescription)")
            throw GeminiError.analysisFailure(error.localizedDescription)
        }
    }
    
    /// Generate session summary with insights and recommendations
    /// - Parameter shots: All shots from the session
    /// - Returns: Comprehensive session analysis
    func generateSessionSummary(_ shots: [ShotAnalysis]) async throws -> SessionSummary {
        logger.info("Generating session summary for \(shots.count) shots")
        
        guard !shots.isEmpty else {
            throw GeminiError.insufficientData("No shots to analyze")
        }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            let prompt = createSessionSummaryPrompt(from: shots)
            let response = try await sendToGemini(prompt: prompt, type: .sessionSummary)
            let summary = try parseSessionSummary(response, shots: shots)
            
            lastAnalysisTime = Date()
            analysisCount += 1
            
            logger.info("Session summary generated successfully")
            return summary
            
        } catch {
            logger.error("Session summary generation failed: \(error.localizedDescription)")
            throw GeminiError.analysisFailure(error.localizedDescription)
        }
    }
    
    /// Analyze video frames for advanced basketball insights
    /// - Parameter frames: Array of video frames to analyze
    /// - Returns: Advanced video analysis results
    func analyzeVideoFrames(_ frames: [UIImage]) async throws -> VideoAnalysisResult {
        logger.info("Analyzing \(frames.count) video frames")
        
        guard !frames.isEmpty && frames.count <= 10 else {
            throw GeminiError.invalidInput("Frame count must be between 1-10")
        }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            let prompt = createVideoAnalysisPrompt()
            let response = try await sendToGeminiWithImages(
                prompt: prompt, 
                images: frames, 
                type: .videoAnalysis
            )
            
            let analysis = try parseVideoAnalysis(response)
            
            lastAnalysisTime = Date()
            analysisCount += 1
            
            logger.info("Video analysis completed successfully")
            return analysis
            
        } catch {
            logger.error("Video analysis failed: \(error.localizedDescription)")
            throw GeminiError.analysisFailure(error.localizedDescription)
        }
    }
    
    // MARK: - Prompt Generation
    
    private func createShotAnalysisPrompt(from shotAnalysis: ShotAnalysis) -> String {
        return """
        You are an expert basketball shooting coach. Analyze this shot data and provide detailed coaching feedback.
        
        Shot Details:
        - Type: \(shotAnalysis.shotType.description)
        - Outcome: \(shotAnalysis.outcome.rawValue)
        - Confidence: \(String(format: "%.1f%%", shotAnalysis.confidence * 100))
        - Shot Arc: \(String(format: "%.1f°", shotAnalysis.shotArc))
        
        Shooting Form Analysis:
        - Elbow Alignment: \(String(format: "%.1f%%", shotAnalysis.shootingForm.elbowAlignment * 100))
        - Shoulder Square: \(String(format: "%.1f%%", shotAnalysis.shootingForm.shoulderSquare * 100))
        - Balance: \(String(format: "%.1f%%", shotAnalysis.shootingForm.balance * 100))
        - Follow Through: \(String(format: "%.1f%%", shotAnalysis.shootingForm.followThrough * 100))
        - Overall Form Score: \(String(format: "%.1f%%", shotAnalysis.shootingForm.overallScore * 100))
        
        Provide:
        1. Detailed technical feedback (2-3 specific improvements)
        2. What they did well (positive reinforcement)
        3. One primary focus area for next shot
        4. Confidence level in your assessment (1-10)
        
        Keep feedback concise, actionable, and encouraging. Focus on the most impactful improvements.
        
        Format your response as JSON:
        {
            "detailed_feedback": "...",
            "positive_aspects": "...",
            "primary_focus": "...",
            "confidence": 8,
            "technical_notes": "..."
        }
        """
    }
    
    private func createSessionSummaryPrompt(from shots: [ShotAnalysis]) -> String {
        let totalShots = shots.count
        let madeShots = shots.filter { $0.outcome == .made }.count
        let accuracy = Float(madeShots) / Float(totalShots) * 100
        
        let shotTypeBreakdown = Dictionary(grouping: shots) { $0.shotType }
            .mapValues { $0.count }
            .map { "\($0.key.description): \($0.value)" }
            .joined(separator: ", ")
        
        let avgFormScore = shots.map { $0.shootingForm.overallScore }.reduce(0, +) / Float(shots.count) * 100
        
        return """
        You are an expert basketball coach analyzing a complete shooting session. Provide comprehensive insights and recommendations.
        
        Session Statistics:
        - Total Shots: \(totalShots)
        - Made Shots: \(madeShots)
        - Accuracy: \(String(format: "%.1f%%", accuracy))
        - Average Form Score: \(String(format: "%.1f%%", avgFormScore))
        - Shot Types: \(shotTypeBreakdown)
        
        Detailed Shot Data:
        \(shots.enumerated().map { index, shot in
            "Shot \(index + 1): \(shot.shotType.description) - \(shot.outcome.rawValue) (Form: \(String(format: "%.0f%%", shot.shootingForm.overallScore * 100)))"
        }.joined(separator: "\n"))
        
        Provide:
        1. Overall performance assessment
        2. Key strengths identified
        3. Main areas for improvement (prioritized)
        4. Specific drills or exercises to recommend
        5. Goals for next session
        6. Progression indicators to track
        
        Format as JSON:
        {
            "overall_assessment": "...",
            "key_strengths": ["...", "..."],
            "improvement_areas": ["...", "..."],
            "recommended_drills": ["...", "..."],
            "next_session_goals": ["...", "..."],
            "tracking_metrics": ["...", "..."]
        }
        """
    }
    
    private func createVideoAnalysisPrompt() -> String {
        return """
        You are an expert basketball analyst. Analyze these video frames showing basketball shooting motion.
        
        Look for:
        1. Player positioning and stance
        2. Ball handling and release technique
        3. Body mechanics during shot
        4. Follow-through and balance
        5. Any technical issues or strengths
        
        Provide detailed analysis focusing on:
        - Pre-shot setup
        - Shooting mechanics
        - Post-release form
        - Recommended improvements
        
        Format as JSON:
        {
            "pre_shot_analysis": "...",
            "shooting_mechanics": "...",
            "post_release_form": "...",
            "key_recommendations": ["...", "..."],
            "overall_rating": 8.5
        }
        """
    }
    
    // MARK: - API Communication
    
    private func sendToGemini(prompt: String, type: AnalysisType) async throws -> GeminiResponse {
        let url = URL(string: "\(baseURL)/models/gemini-1.5-flash:generateContent?key=\(apiKey)")!
        
        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [GeminiPart.text(prompt)]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.7,
                maxOutputTokens: 1000,
                topP: 0.8
            )
        )
        
        return try await executeRequest(url: url, body: requestBody)
    }
    
    private func sendToGeminiWithImages(prompt: String, images: [UIImage], type: AnalysisType) async throws -> GeminiResponse {
        let url = URL(string: "\(baseURL)/models/gemini-1.5-flash:generateContent?key=\(apiKey)")!
        
        // Convert images to base64
        var parts: [GeminiPart] = [.text(prompt)]
        
        for (index, image) in images.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                logger.warning("Failed to convert image \(index) to JPEG data")
                continue
            }
            
            let base64String = imageData.base64EncodedString()
            parts.append(.image(GeminiImagePart(
                inlineData: GeminiInlineData(
                    mimeType: "image/jpeg",
                    data: base64String
                )
            )))
        }
        
        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(parts: parts)
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.7,
                maxOutputTokens: 1500,
                topP: 0.8
            )
        )
        
        return try await executeRequest(url: url, body: requestBody)
    }
    
    private func executeRequest(url: URL, body: GeminiRequest) async throws -> GeminiResponse {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw GeminiError.encodingFailure("Failed to encode request: \(error.localizedDescription)")
        }
        
        for attempt in 1...maxRetries {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw GeminiError.networkError("Invalid response type")
                }
                
                guard httpResponse.statusCode == 200 else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw GeminiError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
                }
                
                do {
                    let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                    return geminiResponse
                } catch {
                    throw GeminiError.decodingFailure("Failed to decode response: \(error.localizedDescription)")
                }
                
            } catch {
                logger.warning("Request attempt \(attempt) failed: \(error.localizedDescription)")
                
                if attempt == maxRetries {
                    throw error
                }
                
                // Exponential backoff
                let delay = pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw GeminiError.networkError("All retry attempts failed")
    }
    
    // MARK: - Response Parsing
    
    private func parseEnhancedAnalysis(_ response: GeminiResponse, originalAnalysis: ShotAnalysis) throws -> EnhancedShotAnalysis {
        guard let candidate = response.candidates.first,
              let content = candidate.content.parts.first else {
            throw GeminiError.decodingFailure("No content in response")
        }
        
        let text: String
        switch content {
        case .text(let responseText):
            text = responseText
        case .image(_):
            throw GeminiError.decodingFailure("Expected text response, got image")
        }
        
        // Parse JSON response
        guard let jsonData = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw GeminiError.decodingFailure("Invalid JSON in response")
        }
        
        return EnhancedShotAnalysis(
            originalAnalysis: originalAnalysis,
            detailedFeedback: json["detailed_feedback"] as? String ?? "No detailed feedback available",
            positiveAspects: json["positive_aspects"] as? String ?? "Good shooting form overall",
            primaryFocus: json["primary_focus"] as? String ?? "Continue practicing consistent form",
            confidence: json["confidence"] as? Int ?? 7,
            technicalNotes: json["technical_notes"] as? String ?? ""
        )
    }
    
    private func parseSessionSummary(_ response: GeminiResponse, shots: [ShotAnalysis]) throws -> SessionSummary {
        guard let candidate = response.candidates.first,
              let content = candidate.content.parts.first else {
            throw GeminiError.decodingFailure("No content in response")
        }
        
        let text: String
        switch content {
        case .text(let responseText):
            text = responseText
        case .image(_):
            throw GeminiError.decodingFailure("Expected text response, got image")
        }
        
        guard let jsonData = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw GeminiError.decodingFailure("Invalid JSON in response")
        }
        
        return SessionSummary(
            totalShots: shots.count,
            accuracy: Float(shots.filter { $0.outcome == .made }.count) / Float(shots.count),
            overallAssessment: json["overall_assessment"] as? String ?? "Session completed",
            keyStrengths: json["key_strengths"] as? [String] ?? [],
            improvementAreas: json["improvement_areas"] as? [String] ?? [],
            recommendedDrills: json["recommended_drills"] as? [String] ?? [],
            nextSessionGoals: json["next_session_goals"] as? [String] ?? [],
            trackingMetrics: json["tracking_metrics"] as? [String] ?? []
        )
    }
    
    private func parseVideoAnalysis(_ response: GeminiResponse) throws -> VideoAnalysisResult {
        guard let candidate = response.candidates.first,
              let content = candidate.content.parts.first else {
            throw GeminiError.decodingFailure("No content in response")
        }
        
        let text: String
        switch content {
        case .text(let responseText):
            text = responseText
        case .image(_):
            throw GeminiError.decodingFailure("Expected text response, got image")
        }
        
        guard let jsonData = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw GeminiError.decodingFailure("Invalid JSON in response")
        }
        
        return VideoAnalysisResult(
            preShotAnalysis: json["pre_shot_analysis"] as? String ?? "",
            shootingMechanics: json["shooting_mechanics"] as? String ?? "",
            postReleaseForm: json["post_release_form"] as? String ?? "",
            keyRecommendations: json["key_recommendations"] as? [String] ?? [],
            overallRating: json["overall_rating"] as? Float ?? 0.0
        )
    }
}

// MARK: - Supporting Types

enum AnalysisType {
    case shotAnalysis
    case sessionSummary
    case videoAnalysis
}

enum GeminiError: Error, LocalizedError {
    case invalidInput(String)
    case networkError(String)
    case apiError(String)
    case encodingFailure(String)
    case decodingFailure(String)
    case analysisFailure(String)
    case insufficientData(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .encodingFailure(let message):
            return "Encoding error: \(message)"
        case .decodingFailure(let message):
            return "Decoding error: \(message)"
        case .analysisFailure(let message):
            return "Analysis failed: \(message)"
        case .insufficientData(let message):
            return "Insufficient data: \(message)"
        }
    }
}

// MARK: - Data Models for Enhanced Analysis

struct EnhancedShotAnalysis {
    let originalAnalysis: ShotAnalysis
    let detailedFeedback: String
    let positiveAspects: String
    let primaryFocus: String
    let confidence: Int // 1-10
    let technicalNotes: String
}

struct SessionSummary {
    let totalShots: Int
    let accuracy: Float
    let overallAssessment: String
    let keyStrengths: [String]
    let improvementAreas: [String]
    let recommendedDrills: [String]
    let nextSessionGoals: [String]
    let trackingMetrics: [String]
}

struct VideoAnalysisResult {
    let preShotAnalysis: String
    let shootingMechanics: String
    let postReleaseForm: String
    let keyRecommendations: [String]
    let overallRating: Float
} 