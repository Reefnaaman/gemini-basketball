import SwiftUI
import AVFoundation
import os.log

/// Comprehensive test using the existing final_ball.mov basketball video
struct VideoAnalysisTest: View {
    
    @StateObject private var coachingService = BasketballCoachingService(
        geminiAPIKey: "AIzaSyA08Ar4gUbXv0aly_a4H3o7Z8u6UjO34KY"
    )
    
    @State private var isProcessing = false
    @State private var currentFrame: Int = 0
    @State private var totalFrames: Int = 0
    @State private var detectedShots: [ShotAnalysis] = []
    @State private var enhancedAnalyses: [EnhancedShotAnalysis] = []
    @State private var processingTime: TimeInterval = 0
    @State private var sessionSummary: SessionSummary?
    @State private var error: String?
    
    private let logger = Logger(subsystem: "BasketballCoachApp", category: "VideoAnalysisTest")
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Header
                    VStack(spacing: 8) {
                        Text("🏀 Basketball Video Analysis")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Testing with final_ball.mov")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Video Info
                    VideoInfoCard()
                    
                    // Processing Status
                    if isProcessing {
                        ProcessingView(currentFrame: currentFrame, totalFrames: totalFrames)
                    } else {
                        Button("🚀 Start Complete Analysis") {
                            startVideoAnalysis()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Performance Metrics
                    if processingTime > 0 {
                        PerformanceMetricsView(
                            processingTime: processingTime,
                            totalFrames: totalFrames,
                            detectedShots: detectedShots.count
                        )
                    }
                    
                    // Detected Shots
                    if !detectedShots.isEmpty {
                        DetectedShotsView(shots: detectedShots)
                    }
                    
                    // Enhanced AI Analysis
                    if !enhancedAnalyses.isEmpty {
                        EnhancedAnalysisView(analyses: enhancedAnalyses)
                    }
                    
                    // Session Summary
                    if let summary = sessionSummary {
                        SessionSummaryCard(summary: summary)
                    }
                    
                    // Error Display
                    if let error = error {
                        ErrorCard(error: error)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Video Analysis Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func startVideoAnalysis() {
        logger.info("Starting video analysis with final_ball.mov")
        
        isProcessing = true
        currentFrame = 0
        totalFrames = 0
        detectedShots.removeAll()
        enhancedAnalyses.removeAll()
        processingTime = 0
        sessionSummary = nil
        error = nil
        
        Task {
            let startTime = Date()
            
            do {
                // Load the video file
                guard let videoURL = Bundle.main.url(forResource: "final_ball", withExtension: "mov") else {
                    throw VideoAnalysisError.fileNotFound("final_ball.mov not found in bundle")
                }
                
                // Process video with computer vision
                let results = try await processVideoFile(videoURL)
                
                // Enhance with AI analysis
                let enhanced = try await enhanceWithAI(results)
                
                // Generate session summary
                let summary = try await generateSessionSummary(results)
                
                let endTime = Date()
                
                await MainActor.run {
                    self.detectedShots = results
                    self.enhancedAnalyses = enhanced
                    self.sessionSummary = summary
                    self.processingTime = endTime.timeIntervalSince(startTime)
                    self.isProcessing = false
                    
                    self.logger.info("Video analysis completed successfully")
                }
                
            } catch {
                await MainActor.run {
                    self.error = "Analysis failed: \(error.localizedDescription)"
                    self.isProcessing = false
                    
                    self.logger.error("Video analysis failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func processVideoFile(_ videoURL: URL) async throws -> [ShotAnalysis] {
        logger.info("Processing video file: \(videoURL.path)")
        
        let asset = AVAsset(url: videoURL)
        let duration = try await asset.load(.duration)
        let frameRate: Float64 = 30.0
        
        await MainActor.run {
            self.totalFrames = Int(duration.seconds * frameRate)
        }
        
        var detectedShots: [ShotAnalysis] = []
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let timeIncrement = CMTime(seconds: 1.0/frameRate, preferredTimescale: 600)
        var currentTime = CMTime.zero
        
        // Process frames
        while currentTime < duration {
            do {
                let cgImage = try imageGenerator.copyCGImage(at: currentTime, actualTime: nil)
                let uiImage = UIImage(cgImage: cgImage)
                
                // Analyze frame with computer vision
                let analysis = try await coachingService.computerVisionService.analyzeShootingForm(in: uiImage)
                
                // Only keep high-confidence detections
                if analysis.confidence > 0.7 {
                    detectedShots.append(analysis)
                    logger.info("Shot detected at \(currentTime.seconds)s with confidence \(analysis.confidence)")
                }
                
                await MainActor.run {
                    self.currentFrame += 1
                }
                
                currentTime = CMTimeAdd(currentTime, timeIncrement)
                
            } catch {
                logger.warning("Frame processing failed at \(currentTime.seconds)s: \(error.localizedDescription)")
                currentTime = CMTimeAdd(currentTime, timeIncrement)
            }
        }
        
        logger.info("Video processing completed. Found \(detectedShots.count) shots")
        return detectedShots
    }
    
    private func enhanceWithAI(_ shots: [ShotAnalysis]) async throws -> [EnhancedShotAnalysis] {
        logger.info("Enhancing \(shots.count) shots with AI analysis")
        
        var enhancedAnalyses: [EnhancedShotAnalysis] = []
        
        // Take top 3 shots for AI enhancement (to manage API usage)
        let topShots = Array(shots.prefix(3))
        
        for shot in topShots {
            do {
                let enhanced = try await coachingService.getDetailedAnalysis(for: shot)
                if let enhanced = enhanced {
                    enhancedAnalyses.append(enhanced)
                }
            } catch {
                logger.warning("Failed to enhance shot analysis: \(error.localizedDescription)")
            }
        }
        
        logger.info("AI enhancement completed for \(enhancedAnalyses.count) shots")
        return enhancedAnalyses
    }
    
    private func generateSessionSummary(_ shots: [ShotAnalysis]) async throws -> SessionSummary {
        logger.info("Generating session summary")
        
        let summary = try await coachingService.geminiService.generateSessionSummary(shots)
        
        logger.info("Session summary generated successfully")
        return summary
    }
}

// MARK: - Supporting Views

struct VideoInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("📹 Video Information")
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("File: final_ball.mov")
                    .font(.subheadline)
                
                Text("Size: ~16MB")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Source: Original basketball demo")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Content: Basketball shooting practice")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ProcessingView: View {
    let currentFrame: Int
    let totalFrames: Int
    
    var progress: Double {
        guard totalFrames > 0 else { return 0 }
        return Double(currentFrame) / Double(totalFrames)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("🔄 Processing Video...")
                .font(.headline)
                .foregroundColor(.orange)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(x: 1, y: 2)
            
            Text("Frame \(currentFrame) of \(totalFrames)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if progress > 0 {
                Text("\(Int(progress * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

struct PerformanceMetricsView: View {
    let processingTime: TimeInterval
    let totalFrames: Int
    let detectedShots: Int
    
    var framesPerSecond: Double {
        guard processingTime > 0 else { return 0 }
        return Double(totalFrames) / processingTime
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("⚡ Performance Metrics")
                .font(.headline)
                .foregroundColor(.green)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Processing Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", processingTime))s")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Processing Speed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", framesPerSecond)) FPS")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Frames")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalFrames)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Shots Detected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(detectedShots)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DetectedShotsView: View {
    let shots: [ShotAnalysis]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🎯 Detected Shots (\(shots.count))")
                .font(.headline)
                .foregroundColor(.purple)
            
            ForEach(Array(shots.enumerated()), id: \.offset) { index, shot in
                ShotRowView(shot: shot, index: index + 1)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ShotRowView: View {
    let shot: ShotAnalysis
    let index: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Shot #\(index)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\(shot.shotType.description) - \(shot.outcome.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Confidence: \(String(format: "%.1f%%", shot.confidence * 100))")
                    .font(.caption)
                
                Text("Form: \(String(format: "%.1f%%", shot.shootingForm.overallScore * 100))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.5))
        .cornerRadius(8)
    }
}

struct EnhancedAnalysisView: View {
    let analyses: [EnhancedShotAnalysis]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🤖 AI-Enhanced Analysis")
                .font(.headline)
                .foregroundColor(.indigo)
            
            ForEach(Array(analyses.enumerated()), id: \.offset) { index, analysis in
                EnhancedShotRowView(analysis: analysis, index: index + 1)
            }
        }
        .padding()
        .background(Color.indigo.opacity(0.1))
        .cornerRadius(12)
    }
}

struct EnhancedShotRowView: View {
    let analysis: EnhancedShotAnalysis
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Enhanced Shot #\(index)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("AI Confidence: \(analysis.confidence)/10")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.indigo.opacity(0.2))
                    .cornerRadius(6)
            }
            
            if !analysis.primaryFocus.isEmpty {
                Text("🎯 Focus: \(analysis.primaryFocus)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if !analysis.positiveAspects.isEmpty {
                Text("✅ Strengths: \(analysis.positiveAspects)")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            if !analysis.detailedFeedback.isEmpty {
                Text("💡 Feedback: \(analysis.detailedFeedback)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.5))
        .cornerRadius(8)
    }
}

struct SessionSummaryCard: View {
    let summary: SessionSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📊 Session Summary")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(summary.overallAssessment)
                .font(.subheadline)
                .padding(.bottom, 4)
            
            if !summary.keyStrengths.isEmpty {
                Text("💪 Key Strengths:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                ForEach(summary.keyStrengths, id: \.self) { strength in
                    Text("• \(strength)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            if !summary.improvementAreas.isEmpty {
                Text("🎯 Areas for Improvement:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .padding(.top, 4)
                
                ForEach(summary.improvementAreas, id: \.self) { area in
                    Text("• \(area)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            if !summary.recommendedDrills.isEmpty {
                Text("🏋️ Recommended Drills:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
                
                ForEach(summary.recommendedDrills, id: \.self) { drill in
                    Text("• \(drill)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ErrorCard: View {
    let error: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("⚠️ Error")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Types

enum VideoAnalysisError: Error, LocalizedError {
    case fileNotFound(String)
    case processingFailed(String)
    case enhancementFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let message):
            return "File not found: \(message)"
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        case .enhancementFailed(let message):
            return "Enhancement failed: \(message)"
        }
    }
}

// MARK: - Preview

struct VideoAnalysisTest_Previews: PreviewProvider {
    static var previews: some View {
        VideoAnalysisTest()
    }
} 