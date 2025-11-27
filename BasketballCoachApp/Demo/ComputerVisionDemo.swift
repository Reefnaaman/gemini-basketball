import Foundation
import AVFoundation
import Vision
import CoreImage
import os.log

/// Demo class to test ComputerVisionService with real basketball video
class ComputerVisionDemo {
    
    private let logger = Logger(subsystem: "BasketballCoachApp", category: "Demo")
    private let cvService = ComputerVisionService()
    
    // Results storage
    private var detectedShots: [ShotAnalysis] = []
    private var performanceMetrics: [CVPerformanceMetrics] = []
    
    /// Run demo with the original basketball video
    func runDemo() async throws {
        logger.info("Starting Computer Vision Demo")
        
        // Load the original video
        guard let videoURL = getVideoURL() else {
            throw DemoError.videoNotFound
        }
        
        logger.info("Processing video: \(videoURL.lastPathComponent)")
        
        // Process video frames
        try await processVideo(at: videoURL)
        
        // Analyze results
        analyzeResults()
        
        // Generate report
        generateReport()
        
        logger.info("Demo completed successfully")
    }
    
    /// Process video frame by frame
    private func processVideo(at url: URL) async throws {
        let asset = AVAsset(url: url)
        let reader = try AVAssetReader(asset: asset)
        
        // Configure video output
        let videoTrack = try await asset.loadTracks(withMediaType: .video).first!
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
        reader.add(readerOutput)
        
        // Start reading
        guard reader.startReading() else {
            throw DemoError.failedToStartReading
        }
        
        var frameCount = 0
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Process frames
        while reader.status == .reading {
            guard let sampleBuffer = readerOutput.copyNextSampleBuffer() else {
                break
            }
            
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                continue
            }
            
            do {
                // Process frame with our CV service
                let result = try await cvService.processFrame(pixelBuffer)
                
                // Collect shot analysis if detected
                if let shotAnalysis = result.shotAnalysis {
                    detectedShots.append(shotAnalysis)
                    logger.info("Shot detected: \(shotAnalysis.shotType.description) - \(shotAnalysis.outcome.rawValue)")
                }
                
                // Collect performance metrics
                if let metrics = cvService.performanceMetrics {
                    performanceMetrics.append(metrics)
                }
                
                frameCount += 1
                
                // Log progress every 30 frames (1 second at 30fps)
                if frameCount % 30 == 0 {
                    let elapsed = CFAbsoluteTimeGetCurrent() - startTime
                    let fps = Double(frameCount) / elapsed
                    logger.info("Processed \(frameCount) frames, \(String(format: "%.1f", fps)) fps")
                }
                
            } catch {
                logger.error("Failed to process frame \(frameCount): \(error.localizedDescription)")
            }
        }
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("Finished processing \(frameCount) frames in \(String(format: "%.2f", totalTime)) seconds")
    }
    
    /// Analyze demo results
    private func analyzeResults() {
        logger.info("Analyzing results...")
        
        // Shot detection analysis
        let madeShots = detectedShots.filter { $0.outcome == .made }
        let missedShots = detectedShots.filter { $0.outcome == .missed }
        let accuracy = detectedShots.isEmpty ? 0.0 : Float(madeShots.count) / Float(detectedShots.count)
        
        logger.info("Shot Analysis:")
        logger.info("- Total shots detected: \(detectedShots.count)")
        logger.info("- Made shots: \(madeShots.count)")
        logger.info("- Missed shots: \(missedShots.count)")
        logger.info("- Accuracy: \(String(format: "%.1f%%", accuracy * 100))")
        
        // Shot type breakdown
        let shotTypeCounts = Dictionary(grouping: detectedShots) { $0.shotType }
            .mapValues { $0.count }
        
        logger.info("Shot Types:")
        for (shotType, count) in shotTypeCounts {
            logger.info("- \(shotType.description): \(count)")
        }
        
        // Performance analysis
        if !performanceMetrics.isEmpty {
            let avgProcessingTime = performanceMetrics.map { $0.processingTime }.reduce(0, +) / Double(performanceMetrics.count)
            let avgFrameRate = performanceMetrics.map { $0.frameRate }.reduce(0, +) / Double(performanceMetrics.count)
            let avgConfidence = performanceMetrics.map { $0.confidence }.reduce(0, +) / Float(performanceMetrics.count)
            
            logger.info("Performance Metrics:")
            logger.info("- Average processing time: \(String(format: "%.3f", avgProcessingTime))s")
            logger.info("- Average frame rate: \(String(format: "%.1f", avgFrameRate)) fps")
            logger.info("- Average confidence: \(String(format: "%.1f%%", avgConfidence * 100))")
            
            let withinTargets = performanceMetrics.filter { $0.isWithinPerformanceTargets }.count
            let targetPercentage = Float(withinTargets) / Float(performanceMetrics.count) * 100
            logger.info("- Frames meeting performance targets: \(String(format: "%.1f%%", targetPercentage))")
        }
    }
    
    /// Generate detailed report comparing with original data
    private func generateReport() {
        logger.info("Generating comparison report...")
        
        // Load original ball.json for comparison
        guard let originalData = loadOriginalShotData() else {
            logger.warning("Could not load original shot data for comparison")
            return
        }
        
        // Compare our detections with original data
        compareWithOriginalData(originalData)
        
        // Generate shooting form analysis
        generateShootingFormReport()
    }
    
    private func loadOriginalShotData() -> OriginalShotData? {
        // First try to load from bundle resources
        if let url = Bundle.main.url(forResource: "ball", withExtension: "json") {
            guard let data = try? Data(contentsOf: url),
                  let originalData = try? JSONDecoder().decode(OriginalShotData.self, from: data) else {
                return nil
            }
            return originalData
        }
        
        // Fallback: try alternative paths for development
        let possiblePaths = [
            "BasketballCoachApp/Resources/ball.json",
            "../BasketballCoachApp/Resources/ball.json",
            "../../ball.json",
            "ball.json"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                guard let data = FileManager.default.contents(atPath: path),
                      let originalData = try? JSONDecoder().decode(OriginalShotData.self, from: data) else {
                    continue
                }
                return originalData
            }
        }
        
        return nil
    }
    
    private func compareWithOriginalData(_ originalData: OriginalShotData) {
        logger.info("Comparing with original Gemini analysis...")
        
        let originalShots = originalData.shots
        logger.info("Original data has \(originalShots.count) shots")
        logger.info("Our detection found \(detectedShots.count) shots")
        
        // Compare accuracy
        let originalMade = originalShots.filter { $0.result == "made" }.count
        let originalMissed = originalShots.filter { $0.result == "missed" }.count
        let originalAccuracy = Float(originalMade) / Float(originalShots.count)
        
        let ourMade = detectedShots.filter { $0.outcome == .made }.count
        let ourMissed = detectedShots.filter { $0.outcome == .missed }.count
        let ourAccuracy = detectedShots.isEmpty ? 0.0 : Float(ourMade) / Float(detectedShots.count)
        
        logger.info("Accuracy Comparison:")
        logger.info("- Original: \(String(format: "%.1f%%", originalAccuracy * 100))")
        logger.info("- Our detection: \(String(format: "%.1f%%", ourAccuracy * 100))")
        logger.info("- Difference: \(String(format: "%.1f%%", abs(originalAccuracy - ourAccuracy) * 100))")
        
        // Compare shot types
        let originalShotTypes = Dictionary(grouping: originalShots) { $0.shotType }
            .mapValues { $0.count }
        let ourShotTypes = Dictionary(grouping: detectedShots) { $0.shotType.description }
            .mapValues { $0.count }
        
        logger.info("Shot Type Comparison:")
        for (shotType, count) in originalShotTypes {
            let ourCount = ourShotTypes[shotType] ?? 0
            logger.info("- \(shotType): Original=\(count), Ours=\(ourCount)")
        }
    }
    
    private func generateShootingFormReport() {
        logger.info("Generating shooting form analysis...")
        
        guard !detectedShots.isEmpty else {
            logger.warning("No shots detected for form analysis")
            return
        }
        
        // Average shooting form scores
        let avgElbowAlignment = detectedShots.map { $0.shootingForm.elbowAlignment }.reduce(0, +) / Float(detectedShots.count)
        let avgShoulderSquare = detectedShots.map { $0.shootingForm.shoulderSquare }.reduce(0, +) / Float(detectedShots.count)
        let avgBalance = detectedShots.map { $0.shootingForm.balance }.reduce(0, +) / Float(detectedShots.count)
        let avgFollowThrough = detectedShots.map { $0.shootingForm.followThrough }.reduce(0, +) / Float(detectedShots.count)
        let avgOverallScore = detectedShots.map { $0.shootingForm.overallScore }.reduce(0, +) / Float(detectedShots.count)
        
        logger.info("Average Shooting Form Scores:")
        logger.info("- Elbow Alignment: \(String(format: "%.1f%%", avgElbowAlignment * 100))")
        logger.info("- Shoulder Square: \(String(format: "%.1f%%", avgShoulderSquare * 100))")
        logger.info("- Balance: \(String(format: "%.1f%%", avgBalance * 100))")
        logger.info("- Follow Through: \(String(format: "%.1f%%", avgFollowThrough * 100))")
        logger.info("- Overall Score: \(String(format: "%.1f%%", avgOverallScore * 100))")
        
        // Feedback analysis
        let feedbackTypes = detectedShots.map { $0.feedback }
        let uniqueFeedback = Set(feedbackTypes)
        
        logger.info("Generated Feedback Types (\(uniqueFeedback.count) unique):")
        for feedback in uniqueFeedback.prefix(5) { // Show first 5
            logger.info("- \"\(feedback)\"")
        }
    }
    
    private func getVideoURL() -> URL? {
        // First try to load from bundle resources
        if let url = Bundle.main.url(forResource: "final_ball", withExtension: "mov") {
            return url
        }
        
        // Fallback: try alternative paths for development
        let possiblePaths = [
            "BasketballCoachApp/Resources/final_ball.mov",
            "../BasketballCoachApp/Resources/final_ball.mov", 
            "../../final_ball.mov",
            "final_ball.mov"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        
        return nil
    }
}

// MARK: - Supporting Types for Demo

struct OriginalShotData: Codable {
    let shots: [OriginalShot]
}

struct OriginalShot: Codable {
    let timestampOfOutcome: String
    let result: String
    let shotType: String
    let totalShotsMadeSoFar: Int
    let totalShotsMissedSoFar: Int
    let totalLayupsMadeSoFar: Int
    let feedback: String
    
    enum CodingKeys: String, CodingKey {
        case timestampOfOutcome = "timestamp_of_outcome"
        case result
        case shotType = "shot_type"
        case totalShotsMadeSoFar = "total_shots_made_so_far"
        case totalShotsMissedSoFar = "total_shots_missed_so_far"
        case totalLayupsMadeSoFar = "total_layups_made_so_far"
        case feedback
    }
}

enum DemoError: Error, LocalizedError {
    case videoNotFound
    case failedToStartReading
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .videoNotFound:
            return "Basketball video file not found"
        case .failedToStartReading:
            return "Failed to start reading video file"
        case .processingFailed:
            return "Failed to process video frames"
        }
    }
}

// MARK: - Demo Runner

/// Main demo runner function
func runComputerVisionDemo() async {
    let demo = ComputerVisionDemo()
    
    do {
        try await demo.runDemo()
    } catch {
        print("Demo failed: \(error.localizedDescription)")
    }
} 