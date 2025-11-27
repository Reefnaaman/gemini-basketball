import SwiftUI
import AVFoundation
import os.log

/// Comprehensive demo showcasing the complete basketball coaching system
struct FullSystemDemo: View {
    
    // MARK: - Properties
    
    @StateObject private var coachingService = BasketballCoachingService(
        geminiAPIKey: "AIzaSyA08Ar4gUbXv0aly_a4H3o7Z8u6UjO34KY"
    )
    
    @State private var showingCamera = false
    @State private var showingSessionHistory = false
    @State private var showingRecommendations = false
    @State private var selectedSession: CoachingSession?
    @State private var recommendations: [CoachingRecommendation] = []
    
    private let logger = Logger(subsystem: "BasketballCoachApp", category: "FullSystemDemo")
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // Header
                VStack(spacing: 8) {
                    Text("🏀 Basketball Coach")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("AI-Powered Shot Analysis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Current Session Status
                if let currentSession = coachingService.currentSession {
                    CurrentSessionView(session: currentSession, coachingService: coachingService)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                } else {
                    NoSessionView()
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
                
                // Real-time Analysis
                if let analysis = coachingService.recentAnalysis {
                    RealtimeAnalysisView(analysis: analysis)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    
                    // Main Action Button
                    Button(action: {
                        if coachingService.isCoachingActive {
                            Task {
                                await coachingService.stopCoachingSession()
                            }
                        } else {
                            Task {
                                await coachingService.startCoachingSession()
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: coachingService.isCoachingActive ? "stop.circle.fill" : "play.circle.fill")
                                .font(.title2)
                            
                            Text(coachingService.isCoachingActive ? "Stop Session" : "Start Session")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(coachingService.isCoachingActive ? Color.red : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(coachingService.isCoachingActive && coachingService.currentSession == nil)
                    
                    // Secondary Actions
                    HStack(spacing: 12) {
                        
                        // Camera Toggle
                        Button(action: {
                            coachingService.toggleCamera()
                        }) {
                            Image(systemName: "camera.rotate")
                                .font(.title2)
                        }
                        .frame(width: 50, height: 50)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                        .disabled(!coachingService.isCoachingActive)
                        
                        // Session History
                        Button(action: {
                            showingSessionHistory = true
                        }) {
                            Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                                .font(.title2)
                        }
                        .frame(width: 50, height: 50)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                        
                        // Recommendations
                        Button(action: {
                            Task {
                                recommendations = await coachingService.getCoachingRecommendations()
                                showingRecommendations = true
                            }
                        }) {
                            Image(systemName: "lightbulb")
                                .font(.title2)
                        }
                        .frame(width: 50, height: 50)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
                
                // Session Summary
                if let summary = coachingService.sessionSummary {
                    SessionSummaryView(summary: summary)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                }
                
                // Error Display
                if let error = coachingService.error {
                    ErrorView(error: error)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Basketball Coach")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSessionHistory) {
                SessionHistoryView(
                    sessions: coachingService.getSavedSessions(),
                    coachingService: coachingService
                )
            }
            .sheet(isPresented: $showingRecommendations) {
                RecommendationsView(recommendations: recommendations)
            }
        }
        .onAppear {
            logger.info("Full system demo loaded")
        }
    }
}

// MARK: - Supporting Views

struct CurrentSessionView: View {
    let session: CoachingSession
    let coachingService: BasketballCoachingService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Current Session")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                if coachingService.isCoachingActive {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.5)
                            .animation(.easeInOut(duration: 1).repeatForever(), value: coachingService.isCoachingActive)
                        
                        Text("LIVE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Player: \(session.playerName)")
                        .font(.subheadline)
                    
                    Text("Type: \(session.sessionType.description)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Duration: \(formatDuration(session.duration))")
                        .font(.subheadline)
                    
                    Text("Shots: \(session.shots.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if !session.shots.isEmpty {
                HStack {
                    Text("Accuracy: \(String(format: "%.1f%%", session.accuracy * 100))")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    let avgForm = session.shots.map { $0.shootingForm.overallScore }.reduce(0, +) / Float(session.shots.count)
                    Text("Avg Form: \(String(format: "%.1f%%", avgForm * 100))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct NoSessionView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "basketball")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No Active Session")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Start a session to begin shot analysis")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct RealtimeAnalysisView: View {
    let analysis: EnhancedShotAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Latest Analysis")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Spacer()
                
                Text("Confidence: \(analysis.confidence)/10")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text("Shot: \(analysis.originalAnalysis.shotType.description)")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Outcome: \(analysis.originalAnalysis.outcome.rawValue)")
                .font(.subheadline)
                .foregroundColor(analysis.originalAnalysis.outcome == .made ? .green : .red)
            
            if !analysis.primaryFocus.isEmpty {
                Text("Focus: \(analysis.primaryFocus)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            if !analysis.positiveAspects.isEmpty {
                Text("✅ \(analysis.positiveAspects)")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
}

struct SessionSummaryView: View {
    let summary: SessionSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session Summary")
                .font(.headline)
                .foregroundColor(.purple)
            
            Text(summary.overallAssessment)
                .font(.subheadline)
            
            if !summary.keyStrengths.isEmpty {
                Text("Strengths: \(summary.keyStrengths.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            if !summary.improvementAreas.isEmpty {
                Text("Improve: \(summary.improvementAreas.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
}

struct ErrorView: View {
    let error: CoachingError
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.red)
            
            Spacer()
        }
    }
}

struct SessionHistoryView: View {
    let sessions: [CoachingSession]
    let coachingService: BasketballCoachingService
    
    var body: some View {
        NavigationView {
            List(sessions) { session in
                SessionRowView(session: session, coachingService: coachingService)
            }
            .navigationTitle("Session History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SessionRowView: View {
    let session: CoachingSession
    let coachingService: BasketballCoachingService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(session.sessionType.description) Session")
                    .font(.headline)
                
                Spacer()
                
                Text(session.startTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Shots: \(session.shots.count)")
                    .font(.subheadline)
                
                Spacer()
                
                Text("Accuracy: \(String(format: "%.1f%%", session.accuracy * 100))")
                    .font(.subheadline)
                    .foregroundColor(session.accuracy > 0.5 ? .green : .red)
            }
            
            if let summary = session.summary {
                Text(summary.overallAssessment)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .swipeActions {
            Button("Delete") {
                coachingService.deleteSession(session)
            }
            .tint(.red)
            
            Button("Export") {
                _ = coachingService.exportSession(session)
            }
            .tint(.blue)
        }
    }
}

struct RecommendationsView: View {
    let recommendations: [CoachingRecommendation]
    
    var body: some View {
        NavigationView {
            List(recommendations) { recommendation in
                RecommendationRowView(recommendation: recommendation)
            }
            .navigationTitle("Coaching Tips")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct RecommendationRowView: View {
    let recommendation: CoachingRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recommendation.title)
                    .font(.headline)
                
                Spacer()
                
                Text(recommendation.priority.description)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(recommendation.priority.color.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text(recommendation.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !recommendation.drills.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended Drills:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    ForEach(recommendation.drills, id: \.self) { drill in
                        Text("• \(drill)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct FullSystemDemo_Previews: PreviewProvider {
    static var previews: some View {
        FullSystemDemo()
    }
} 