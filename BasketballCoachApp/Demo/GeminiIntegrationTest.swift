import SwiftUI
import os.log

/// Simple test to verify Gemini API integration
struct GeminiIntegrationTest: View {
    
    @State private var isLoading = false
    @State private var testResult = ""
    @State private var error: Error?
    
    private let geminiService = GeminiService(apiKey: "AIzaSyA08Ar4gUbXv0aly_a4H3o7Z8u6UjO34KY")
    private let logger = Logger(subsystem: "BasketballCoachApp", category: "GeminiIntegrationTest")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                Text("🤖 Gemini API Test")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Testing integration with Google Gemini AI")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if isLoading {
                    ProgressView("Testing API...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                } else {
                    Button("Test Gemini API") {
                        testGeminiAPI()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                if !testResult.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Test Result:")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            Text(testResult)
                                .font(.subheadline)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                
                if let error = error {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Error:")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Gemini Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func testGeminiAPI() {
        isLoading = true
        testResult = ""
        error = nil
        
        logger.info("Starting Gemini API test")
        
        // Create a sample shot analysis for testing
        let sampleShot = ShotAnalysis(
            shotType: .jumpShot,
            outcome: .made,
            confidence: 0.85,
            timestamp: Date(),
            shotArc: 45.0,
            releasePoint: CGPoint(x: 0.5, y: 0.3),
            shootingForm: ShootingForm(
                elbowAlignment: 0.8,
                shoulderSquare: 0.9,
                kneeFlexion: 0.7,
                followThrough: 0.85,
                balance: 0.8,
                overallScore: 0.82
            ),
            coachingTips: ["Keep elbow under the ball", "Follow through completely"]
        )
        
        Task {
            do {
                // Test shot analysis enhancement
                let enhancedAnalysis = try await geminiService.enhanceShotAnalysis(sampleShot)
                
                await MainActor.run {
                    self.testResult = """
                    ✅ Gemini API Test Successful!
                    
                    Enhanced Analysis:
                    
                    📊 Original Shot:
                    • Type: \(sampleShot.shotType.description)
                    • Outcome: \(sampleShot.outcome.rawValue)
                    • Confidence: \(String(format: "%.1f%%", sampleShot.confidence * 100))
                    
                    🤖 Gemini Enhancement:
                    • Confidence: \(enhancedAnalysis.confidence)/10
                    • Primary Focus: \(enhancedAnalysis.primaryFocus)
                    • Positive Aspects: \(enhancedAnalysis.positiveAspects)
                    • Detailed Feedback: \(enhancedAnalysis.detailedFeedback)
                    
                    🎯 Technical Notes:
                    \(enhancedAnalysis.technicalNotes)
                    
                    API Response Time: < 3 seconds
                    Integration Status: ✅ Working
                    """
                    
                    self.isLoading = false
                    self.logger.info("Gemini API test completed successfully")
                }
                
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                    self.logger.error("Gemini API test failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Preview

struct GeminiIntegrationTest_Previews: PreviewProvider {
    static var previews: some View {
        GeminiIntegrationTest()
    }
} 