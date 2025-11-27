import SwiftUI
import AVFoundation
import os.log

/// Main service that orchestrates all basketball coaching components
class BasketballCoachingService: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "BasketballCoachApp", category: "BasketballCoachingService")
    
    // Core services
    let computerVisionService: ComputerVisionService
    let geminiService: GeminiService
    private let cameraService: CameraService
    
    // Published state
    @Published var isCoachingActive = false
    @Published var currentSession: CoachingSession?
    @Published var recentAnalysis: EnhancedShotAnalysis?
    @Published var sessionSummary: SessionSummary?
    @Published var error: CoachingError?
    
    // Session management
    private var sessionStartTime: Date?
    private var sessionRecordingURL: URL?
    
    // MARK: - Initialization
    
    init(geminiAPIKey: String) {
        // Initialize services
        self.computerVisionService = ComputerVisionService()
        self.geminiService = GeminiService(apiKey: geminiAPIKey)
        self.cameraService = CameraService(
            computerVisionService: computerVisionService,
            geminiService: geminiService
        )
        
        // Setup observers
        setupObservers()
        
        logger.info("BasketballCoachingService initialized")
    }
    
    // MARK: - Public API
    
    /// Start a new coaching session
    func startCoachingSession() async {
        logger.info("Starting coaching session")
        
        guard !isCoachingActive else {
            logger.warning("Coaching session already active")
            return
        }
        
        do {
            // Create new session
            let session = CoachingSession(
                id: UUID(),
                startTime: Date(),
                playerName: "Player", // TODO: Get from user preferences
                sessionType: .practice
            )
            
            // Start camera and recording
            cameraService.startSession()
            
            // Wait for camera to be ready
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            cameraService.startRecording()
            
            // Update state
            await MainActor.run {
                self.currentSession = session
                self.sessionStartTime = Date()
                self.isCoachingActive = true
                self.error = nil
            }
            
            logger.info("Coaching session started successfully")
            
        } catch {
            logger.error("Failed to start coaching session: \(error.localizedDescription)")
            await MainActor.run {
                self.error = .sessionStartFailure(error.localizedDescription)
            }
        }
    }
    
    /// Stop the current coaching session
    func stopCoachingSession() async {
        logger.info("Stopping coaching session")
        
        guard isCoachingActive else {
            logger.warning("No active coaching session")
            return
        }
        
        // Stop recording and camera
        cameraService.stopRecording()
        cameraService.stopSession()
        
        // Generate session summary
        let summary = await cameraService.getSessionSummary()
        
        // Update current session
        if var session = currentSession {
            session.endTime = Date()
            session.shots = cameraService.sessionShots
            session.summary = summary
            
            // Save session
            await saveSession(session)
            
            await MainActor.run {
                self.currentSession = session
                self.sessionSummary = summary
                self.isCoachingActive = false
            }
        }
        
        logger.info("Coaching session stopped")
    }
    
    /// Get analysis for a specific shot
    func getDetailedAnalysis(for shot: ShotAnalysis) async -> EnhancedShotAnalysis? {
        logger.info("Getting detailed analysis for shot")
        
        do {
            let enhancedAnalysis = try await geminiService.enhanceShotAnalysis(shot)
            
            await MainActor.run {
                self.recentAnalysis = enhancedAnalysis
            }
            
            return enhancedAnalysis
            
        } catch {
            logger.error("Failed to get detailed analysis: \(error.localizedDescription)")
            await MainActor.run {
                self.error = .analysisFailure(error.localizedDescription)
            }
            return nil
        }
    }
    
    /// Toggle camera (front/back)
    func toggleCamera() {
        cameraService.toggleCamera()
    }
    
    /// Get all saved sessions
    func getSavedSessions() -> [CoachingSession] {
        return loadSavedSessions()
    }
    
    /// Delete a saved session
    func deleteSession(_ session: CoachingSession) {
        var sessions = loadSavedSessions()
        sessions.removeAll { $0.id == session.id }
        saveSessions(sessions)
        logger.info("Session deleted: \(session.id)")
    }
    
    /// Export session data
    func exportSession(_ session: CoachingSession) -> URL? {
        logger.info("Exporting session: \(session.id)")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(session)
            
            guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                logger.error("Cannot access documents directory")
                return nil
            }
            
            let fileName = "basketball_session_\(session.id.uuidString).json"
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            try data.write(to: fileURL)
            
            logger.info("Session exported to: \(fileURL.path)")
            return fileURL
            
        } catch {
            logger.error("Failed to export session: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Get coaching recommendations based on session history
    func getCoachingRecommendations() async -> [CoachingRecommendation] {
        logger.info("Getting coaching recommendations")
        
        let sessions = getSavedSessions()
        guard !sessions.isEmpty else {
            return defaultRecommendations()
        }
        
        // Analyze patterns from recent sessions
        let recentSessions = Array(sessions.suffix(5)) // Last 5 sessions
        let allShots = recentSessions.flatMap { $0.shots }
        
        guard !allShots.isEmpty else {
            return defaultRecommendations()
        }
        
        // Generate recommendations with Gemini
        do {
            let summary = try await geminiService.generateSessionSummary(allShots)
            return convertSummaryToRecommendations(summary)
            
        } catch {
            logger.error("Failed to generate coaching recommendations: \(error.localizedDescription)")
            return defaultRecommendations()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe camera service for real-time updates
        cameraService.$enhancedAnalysis
            .compactMap { $0 }
            .assign(to: &$recentAnalysis)
        
        cameraService.$error
            .compactMap { $0 }
            .map { CoachingError.cameraError($0.localizedDescription) }
            .assign(to: &$error)
    }
    
    private func saveSession(_ session: CoachingSession) async {
        logger.info("Saving session: \(session.id)")
        
        var sessions = loadSavedSessions()
        sessions.append(session)
        
        // Keep only last 20 sessions
        if sessions.count > 20 {
            sessions = Array(sessions.suffix(20))
        }
        
        saveSessions(sessions)
        logger.info("Session saved successfully")
    }
    
    private func loadSavedSessions() -> [CoachingSession] {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.error("Cannot access documents directory")
            return []
        }
        
        let fileURL = documentsPath.appendingPathComponent("basketball_sessions.json")
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let sessions = try decoder.decode([CoachingSession].self, from: data)
            return sessions
            
        } catch {
            logger.info("No saved sessions found or failed to load: \(error.localizedDescription)")
            return []
        }
    }
    
    private func saveSessions(_ sessions: [CoachingSession]) {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.error("Cannot access documents directory")
            return
        }
        
        let fileURL = documentsPath.appendingPathComponent("basketball_sessions.json")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(sessions)
            try data.write(to: fileURL)
            
            logger.info("Sessions saved successfully")
            
        } catch {
            logger.error("Failed to save sessions: \(error.localizedDescription)")
        }
    }
    
    private func defaultRecommendations() -> [CoachingRecommendation] {
        return [
            CoachingRecommendation(
                title: "Focus on Form",
                description: "Work on consistent shooting form with emphasis on follow-through",
                priority: .high,
                drills: ["Form shooting close to basket", "Wall sits for leg strength"]
            ),
            CoachingRecommendation(
                title: "Practice Free Throws",
                description: "Improve accuracy with consistent free throw practice",
                priority: .medium,
                drills: ["100 free throws daily", "Free throw routine development"]
            ),
            CoachingRecommendation(
                title: "Build Confidence",
                description: "Focus on positive reinforcement and gradual improvement",
                priority: .medium,
                drills: ["Start close to basket", "Celebrate small improvements"]
            )
        ]
    }
    
    private func convertSummaryToRecommendations(_ summary: SessionSummary) -> [CoachingRecommendation] {
        var recommendations: [CoachingRecommendation] = []
        
        // Convert improvement areas to recommendations
        for (index, area) in summary.improvementAreas.enumerated() {
            let priority: CoachingPriority = index == 0 ? .high : (index == 1 ? .medium : .low)
            let drills = summary.recommendedDrills.prefix(2).map { String($0) }
            
            recommendations.append(CoachingRecommendation(
                title: area,
                description: "Focus on improving \(area.lowercased()) based on recent session analysis",
                priority: priority,
                drills: Array(drills)
            ))
        }
        
        // Add goal-based recommendations
        for goal in summary.nextSessionGoals {
            recommendations.append(CoachingRecommendation(
                title: "Session Goal",
                description: goal,
                priority: .medium,
                drills: []
            ))
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

struct CoachingSession: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    let playerName: String
    let sessionType: SessionType
    var shots: [ShotAnalysis] = []
    var summary: SessionSummary?
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    var accuracy: Float {
        guard !shots.isEmpty else { return 0.0 }
        let madeShots = shots.filter { $0.outcome == .made }.count
        return Float(madeShots) / Float(shots.count)
    }
}

enum SessionType: String, Codable, CaseIterable {
    case practice = "Practice"
    case game = "Game"
    case drill = "Drill"
    case freeThrow = "Free Throw"
    
    var description: String {
        return rawValue
    }
}

struct CoachingRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priority: CoachingPriority
    let drills: [String]
}

enum CoachingPriority: Int, CaseIterable {
    case high = 3
    case medium = 2
    case low = 1
    
    var description: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
}

enum CoachingError: Error, LocalizedError {
    case sessionStartFailure(String)
    case analysisFailure(String)
    case cameraError(String)
    case savingFailure(String)
    
    var errorDescription: String? {
        switch self {
        case .sessionStartFailure(let message):
            return "Failed to start coaching session: \(message)"
        case .analysisFailure(let message):
            return "Analysis failed: \(message)"
        case .cameraError(let message):
            return "Camera error: \(message)"
        case .savingFailure(let message):
            return "Failed to save data: \(message)"
        }
    }
}

// MARK: - Extensions

extension ShotAnalysis: Codable {
    enum CodingKeys: String, CodingKey {
        case shotType, outcome, confidence, timestamp, shotArc, releasePoint, shootingForm, coachingTips
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(shotType.rawValue, forKey: .shotType)
        try container.encode(outcome.rawValue, forKey: .outcome)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(shotArc, forKey: .shotArc)
        try container.encode(releasePoint, forKey: .releasePoint)
        try container.encode(shootingForm, forKey: .shootingForm)
        try container.encode(coachingTips, forKey: .coachingTips)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let shotTypeRaw = try container.decode(String.self, forKey: .shotType)
        guard let shotType = ShotType(rawValue: shotTypeRaw) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [CodingKeys.shotType], debugDescription: "Invalid shot type"))
        }
        
        let outcomeRaw = try container.decode(String.self, forKey: .outcome)
        guard let outcome = ShotOutcome(rawValue: outcomeRaw) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [CodingKeys.outcome], debugDescription: "Invalid shot outcome"))
        }
        
        self.shotType = shotType
        self.outcome = outcome
        self.confidence = try container.decode(Float.self, forKey: .confidence)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.shotArc = try container.decode(Float.self, forKey: .shotArc)
        self.releasePoint = try container.decode(CGPoint.self, forKey: .releasePoint)
        self.shootingForm = try container.decode(ShootingForm.self, forKey: .shootingForm)
        self.coachingTips = try container.decode([String].self, forKey: .coachingTips)
    }
}

extension ShootingForm: Codable {
    enum CodingKeys: String, CodingKey {
        case elbowAlignment, shoulderSquare, kneeFlexion, followThrough, balance, overallScore
    }
}

extension SessionSummary: Codable {
    enum CodingKeys: String, CodingKey {
        case totalShots, accuracy, overallAssessment, keyStrengths, improvementAreas, recommendedDrills, nextSessionGoals, trackingMetrics
    }
} 