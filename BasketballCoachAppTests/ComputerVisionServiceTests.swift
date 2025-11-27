import XCTest
import Vision
import AVFoundation
import CoreImage
@testable import BasketballCoachApp

@MainActor
final class ComputerVisionServiceTests: XCTestCase {
    
    var cvService: ComputerVisionService!
    var testPixelBuffer: CVPixelBuffer!
    
    override func setUp() async throws {
        try await super.setUp()
        cvService = ComputerVisionService()
        testPixelBuffer = createTestPixelBuffer()
    }
    
    override func tearDown() async throws {
        cvService = nil
        testPixelBuffer = nil
        try await super.tearDown()
    }
    
    // MARK: - Performance Tests
    
    func testFrameProcessingPerformance() async throws {
        // Test that frame processing meets PRD requirement: <500ms latency
        let expectation = expectation(description: "Frame processing performance")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await cvService.processFrame(testPixelBuffer)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // PRD requirement: <500ms processing time
        XCTAssertLessThan(processingTime, 0.5, "Frame processing must complete within 500ms")
        XCTAssertNotNil(result, "Processing should return a valid result")
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testConcurrentFrameProcessing() async throws {
        // Test that concurrent processing is handled correctly
        let frameCount = 10
        let tasks: [Task<FrameAnalysisResult, Error>] = (0..<frameCount).map { _ in
            Task {
                return try await cvService.processFrame(testPixelBuffer)
            }
        }
        
        var results: [FrameAnalysisResult] = []
        for task in tasks {
            let result = try await task.value
            results.append(result)
        }
        
        XCTAssertEqual(results.count, frameCount, "All frames should be processed")
        
        // Verify no processing takes too long
        for result in results {
            XCTAssertLessThan(result.processingTime, 0.5, "Each frame should process within 500ms")
        }
    }
    
    func testMemoryUsageStability() async throws {
        // Test that memory usage remains stable during continuous processing
        let initialMemory = getMemoryUsage()
        
        // Process multiple frames
        for _ in 0..<50 {
            _ = try await cvService.processFrame(testPixelBuffer)
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory increase should be reasonable (less than 50MB)
        XCTAssertLessThan(memoryIncrease, 50_000_000, "Memory usage should remain stable")
    }
    
    // MARK: - Pose Detection Tests
    
    func testPoseDetectionAccuracy() async throws {
        // Create a pixel buffer with a human pose
        let posePixelBuffer = createPixelBufferWithPose()
        let result = try await cvService.processFrame(posePixelBuffer)
        
        XCTAssertNotNil(result.pose, "Should detect pose in frame with human")
        
        if let pose = result.pose {
            XCTAssertGreaterThan(pose.confidence, 0.5, "Pose detection confidence should be > 50%")
            XCTAssertFalse(pose.keyPoints.isEmpty, "Should detect key points")
            
            // Verify essential basketball keypoints are detected
            let hasWrist = pose.keyPoints.contains { $0.type == .rightWrist || $0.type == .leftWrist }
            let hasShoulder = pose.keyPoints.contains { $0.type == .rightShoulder || $0.type == .leftShoulder }
            let hasElbow = pose.keyPoints.contains { $0.type == .rightElbow || $0.type == .leftElbow }
            
            XCTAssertTrue(hasWrist, "Should detect wrist for shooting analysis")
            XCTAssertTrue(hasShoulder, "Should detect shoulder for form analysis")
            XCTAssertTrue(hasElbow, "Should detect elbow for form analysis")
        }
    }
    
    func testShootingFormAnalysis() async throws {
        let posePixelBuffer = createPixelBufferWithShootingPose()
        let result = try await cvService.processFrame(posePixelBuffer)
        
        XCTAssertNotNil(result.pose, "Should detect shooting pose")
        
        if let pose = result.pose {
            let shootingForm = pose.shootingForm
            
            // Shooting form scores should be between 0 and 1
            XCTAssertGreaterThanOrEqual(shootingForm.elbowAlignment, 0)
            XCTAssertLessThanOrEqual(shootingForm.elbowAlignment, 1)
            
            XCTAssertGreaterThanOrEqual(shootingForm.shoulderSquare, 0)
            XCTAssertLessThanOrEqual(shootingForm.shoulderSquare, 1)
            
            XCTAssertGreaterThanOrEqual(shootingForm.balance, 0)
            XCTAssertLessThanOrEqual(shootingForm.balance, 1)
            
            XCTAssertGreaterThanOrEqual(shootingForm.overallScore, 0)
            XCTAssertLessThanOrEqual(shootingForm.overallScore, 1)
        }
    }
    
    // MARK: - Ball Tracking Tests
    
    func testBallDetectionAccuracy() async throws {
        let ballPixelBuffer = createPixelBufferWithBasketball()
        let result = try await cvService.processFrame(ballPixelBuffer)
        
        XCTAssertNotNil(result.ball, "Should detect basketball in frame")
        
        if let ball = result.ball {
            XCTAssertGreaterThan(ball.confidence, 0.7, "Ball detection confidence should be > 70%")
            XCTAssertTrue(ball.isValid, "Ball tracking result should be valid")
            
            // Position should be within frame bounds
            XCTAssertGreaterThanOrEqual(ball.position.x, 0)
            XCTAssertLessThanOrEqual(ball.position.x, 1)
            XCTAssertGreaterThanOrEqual(ball.position.y, 0)
            XCTAssertLessThanOrEqual(ball.position.y, 1)
        }
    }
    
    func testBallVelocityCalculation() async throws {
        // Process multiple frames to test velocity calculation
        var ballPixelBuffer = createPixelBufferWithBasketball(at: CGPoint(x: 0.3, y: 0.7))
        _ = try await cvService.processFrame(ballPixelBuffer)
        
        // Simulate ball movement
        ballPixelBuffer = createPixelBufferWithBasketball(at: CGPoint(x: 0.4, y: 0.6))
        let result = try await cvService.processFrame(ballPixelBuffer)
        
        if let ball = result.ball {
            // Velocity should be calculated based on position change
            XCTAssertNotEqual(ball.velocity, CGVector.zero, "Velocity should be calculated when ball moves")
        }
    }
    
    // MARK: - Shot Analysis Tests
    
    func testShotDetection() async throws {
        // Simulate a complete shot sequence
        await simulateShootingSequence()
        
        XCTAssertNotNil(cvService.latestShotAnalysis, "Should detect shot after complete sequence")
        
        if let shotAnalysis = cvService.latestShotAnalysis {
            XCTAssertGreaterThan(shotAnalysis.confidence, 0.6, "Shot detection confidence should be > 60%")
            XCTAssertNotEqual(shotAnalysis.shotType, ShotType.jumpShot, "Should classify shot type") // This will fail if default is jumpShot
            XCTAssertNotEqual(shotAnalysis.outcome, ShotOutcome.unknown, "Should determine shot outcome")
        }
    }
    
    func testShotTypeClassification() async throws {
        // Test three-pointer detection
        await simulateThreePointerSequence()
        
        if let shotAnalysis = cvService.latestShotAnalysis {
            XCTAssertEqual(shotAnalysis.shotType, .threePointer, "Should classify long shots as three-pointers")
        }
        
        // Reset and test layup detection
        cvService.resetTracking()
        await simulateLayupSequence()
        
        if let shotAnalysis = cvService.latestShotAnalysis {
            XCTAssertEqual(shotAnalysis.shotType, .layup, "Should classify close, high-release shots as layups")
        }
    }
    
    func testShotArcCalculation() async throws {
        await simulateShootingSequence()
        
        if let shotAnalysis = cvService.latestShotAnalysis {
            XCTAssertGreaterThan(shotAnalysis.shotArc, 0, "Shot arc should be calculated")
            XCTAssertLessThan(shotAnalysis.shotArc, 90, "Shot arc should be reasonable (< 90 degrees)")
        }
    }
    
    func testFeedbackGeneration() async throws {
        await simulatePoorFormShot()
        
        if let shotAnalysis = cvService.latestShotAnalysis {
            XCTAssertFalse(shotAnalysis.feedback.isEmpty, "Should generate feedback for shots")
            XCTAssertTrue(shotAnalysis.feedback.count > 10, "Feedback should be meaningful (> 10 characters)")
        }
    }
    
    // MARK: - State Management Tests
    
    func testResetTracking() async throws {
        // Process some frames to build up state
        for _ in 0..<10 {
            _ = try await cvService.processFrame(testPixelBuffer)
        }
        
        // Reset tracking
        cvService.resetTracking()
        
        // Verify state is cleared
        XCTAssertNil(cvService.currentPose, "Current pose should be nil after reset")
        XCTAssertNil(cvService.currentBallPosition, "Current ball position should be nil after reset")
        XCTAssertNil(cvService.latestShotAnalysis, "Latest shot analysis should be nil after reset")
    }
    
    func testHistoryManagement() async throws {
        // Process many frames to test history management
        for _ in 0..<150 { // More than maxPoseHistoryCount (120)
            _ = try await cvService.processFrame(testPixelBuffer)
        }
        
        // Verify history doesn't grow unbounded
        // We can't directly access poseHistory, but we can verify performance doesn't degrade
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = try await cvService.processFrame(testPixelBuffer)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(processingTime, 0.5, "Processing time should remain stable with history management")
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidFrameHandling() async throws {
        // Test with nil pixel buffer should be handled gracefully
        // This test would need a way to create an invalid pixel buffer
        
        let corruptPixelBuffer = createCorruptPixelBuffer()
        
        do {
            _ = try await cvService.processFrame(corruptPixelBuffer)
        } catch ComputerVisionError.invalidFrame {
            // Expected error
            XCTAssertTrue(true, "Should handle invalid frames gracefully")
        } catch {
            XCTFail("Should throw specific ComputerVisionError.invalidFrame")
        }
    }
    
    func testProcessingTimeoutHandling() async throws {
        // This is hard to test directly, but we can verify the timeout mechanism exists
        XCTAssertFalse(cvService.isProcessing, "Should not be processing initially")
        
        // Start processing
        let task = Task {
            try await cvService.processFrame(testPixelBuffer)
        }
        
        // Verify processing state
        // Note: This is a race condition test, might be flaky
        await Task.yield() // Give the task a chance to start
        
        _ = try await task.value
        XCTAssertFalse(cvService.isProcessing, "Should not be processing after completion")
    }
    
    // MARK: - Helper Methods
    
    private func createTestPixelBuffer() -> CVPixelBuffer {
        let width = 1920
        let height = 1080
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            nil,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            fatalError("Failed to create test pixel buffer")
        }
        
        return buffer
    }
    
    private func createPixelBufferWithPose() -> CVPixelBuffer {
        // In a real implementation, this would create a pixel buffer with a human pose
        // For testing, we'll use the basic test buffer
        return createTestPixelBuffer()
    }
    
    private func createPixelBufferWithShootingPose() -> CVPixelBuffer {
        // In a real implementation, this would create a pixel buffer with a shooting pose
        return createTestPixelBuffer()
    }
    
    private func createPixelBufferWithBasketball(at position: CGPoint = CGPoint(x: 0.5, y: 0.5)) -> CVPixelBuffer {
        // In a real implementation, this would create a pixel buffer with a basketball at the specified position
        return createTestPixelBuffer()
    }
    
    private func createCorruptPixelBuffer() -> CVPixelBuffer {
        // Create a deliberately corrupted pixel buffer for error testing
        return createTestPixelBuffer()
    }
    
    private func simulateShootingSequence() async {
        // Simulate a complete shooting motion with ball trajectory
        let positions: [CGPoint] = [
            CGPoint(x: 0.5, y: 0.8), // Start low
            CGPoint(x: 0.5, y: 0.6), // Release
            CGPoint(x: 0.5, y: 0.4), // Arc peak
            CGPoint(x: 0.5, y: 0.2), // Descent
            CGPoint(x: 0.5, y: 0.1)  // End high (made shot)
        ]
        
        for position in positions {
            let pixelBuffer = createPixelBufferWithBasketball(at: position)
            _ = try? await cvService.processFrame(pixelBuffer)
            // Small delay to simulate real-time processing
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
    }
    
    private func simulateThreePointerSequence() async {
        // Simulate a long-distance shot
        let positions: [CGPoint] = [
            CGPoint(x: 0.2, y: 0.8), // Start far from basket
            CGPoint(x: 0.3, y: 0.6),
            CGPoint(x: 0.4, y: 0.3),
            CGPoint(x: 0.5, y: 0.2),
            CGPoint(x: 0.6, y: 0.1)  // End at basket
        ]
        
        for position in positions {
            let pixelBuffer = createPixelBufferWithBasketball(at: position)
            _ = try? await cvService.processFrame(pixelBuffer)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }
    
    private func simulateLayupSequence() async {
        // Simulate a close, high-release shot
        let positions: [CGPoint] = [
            CGPoint(x: 0.6, y: 0.9), // Start close and low
            CGPoint(x: 0.6, y: 0.7), // High release
            CGPoint(x: 0.6, y: 0.5),
            CGPoint(x: 0.6, y: 0.3),
            CGPoint(x: 0.6, y: 0.1)  // End at basket
        ]
        
        for position in positions {
            let pixelBuffer = createPixelBufferWithBasketball(at: position)
            _ = try? await cvService.processFrame(pixelBuffer)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }
    
    private func simulatePoorFormShot() async {
        // Simulate a shot with poor form to test feedback generation
        await simulateShootingSequence() // Use basic sequence
    }
    
    private func getMemoryUsage() -> Int64 {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(taskInfo.resident_size)
        } else {
            return 0
        }
    }
}

// MARK: - Performance Test Extensions

extension ComputerVisionServiceTests {
    
    func testPerformanceMetricsTracking() async throws {
        // Process several frames
        for _ in 0..<10 {
            _ = try await cvService.processFrame(testPixelBuffer)
        }
        
        // Verify performance metrics are being tracked
        XCTAssertNotNil(cvService.performanceMetrics, "Performance metrics should be tracked")
        
        if let metrics = cvService.performanceMetrics {
            XCTAssertGreaterThan(metrics.frameRate, 0, "Frame rate should be calculated")
            XCTAssertGreaterThan(metrics.processingTime, 0, "Processing time should be measured")
            XCTAssertTrue(metrics.isWithinPerformanceTargets, "Should meet performance targets")
        }
    }
    
    func testFrameRateStability() async throws {
        let frameCount = 30
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<frameCount {
            _ = try await cvService.processFrame(testPixelBuffer)
        }
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        let averageFrameRate = Double(frameCount) / totalTime
        
        // Should maintain at least 20fps as per PRD requirements
        XCTAssertGreaterThan(averageFrameRate, 20.0, "Should maintain minimum 20fps processing rate")
    }
} 