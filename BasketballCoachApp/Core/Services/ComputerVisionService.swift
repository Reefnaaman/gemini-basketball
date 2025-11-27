import Foundation
import Vision
import AVFoundation
import CoreImage
import Accelerate
import os.log

@MainActor
class ComputerVisionService: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "BasketballCoachApp", category: "ComputerVision")
    
    // Processing queues for performance optimization
    private let visionQueue = DispatchQueue(label: "cv.vision", qos: .userInteractive)
    private let analysisQueue = DispatchQueue(label: "cv.analysis", qos: .userInitiated)
    
    // Vision requests
    private lazy var poseRequest: VNDetectHumanBodyPoseRequest = {
        let request = VNDetectHumanBodyPoseRequest()
        request.revision = VNDetectHumanBodyPoseRequestRevision1
        return request
    }()
    
    private lazy var ballDetectionRequest: VNRecognizeObjectsRequest = {
        let request = VNRecognizeObjectsRequest()
        request.revision = VNRecognizeObjectsRequestRevision1
        return request
    }()
    
    // State management
    @Published var isProcessing = false
    @Published var currentPose: PoseResult?
    @Published var currentBallPosition: BallTrackingResult?
    @Published var latestShotAnalysis: ShotAnalysis?
    @Published var performanceMetrics: CVPerformanceMetrics?
    
    // Internal tracking
    private var poseHistory: [PoseResult] = []
    private var ballTrajectoryPoints: [BallTrackingResult] = []
    private var lastShotDetectionTime: TimeInterval = 0
    private var shotInProgress = false
    
    // Performance monitoring
    private var processingTimes: [TimeInterval] = []
    private var lastFrameTime: CFTimeInterval = 0
    
    // Configuration
    private let maxPoseHistoryCount = 120 // 4 seconds at 30fps
    private let maxBallTrajectoryCount = 90 // 3 seconds at 30fps
    private let shotDetectionCooldown: TimeInterval = 2.0 // Minimum time between shots
    private let processingTimeout: TimeInterval = 0.5 // Max processing time per frame
    
    // MARK: - Public Interface
    
    /// Process a single frame for pose detection and ball tracking
    /// - Parameter pixelBuffer: The camera frame to process
    /// - Returns: Combined analysis result
    func processFrame(_ pixelBuffer: CVPixelBuffer) async throws -> FrameAnalysisResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard !isProcessing else {
            throw ComputerVisionError.processingTimeout
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Process pose and ball detection in parallel for better performance
            async let poseResult = detectPose(in: pixelBuffer)
            async let ballResult = detectBall(in: pixelBuffer)
            
            let pose = try await poseResult
            let ball = try await ballResult
            
            // Update tracking history
            if let pose = pose {
                await updatePoseHistory(pose)
            }
            
            if let ball = ball {
                await updateBallTrajectory(ball)
            }
            
            // Analyze for shot detection
            let shotAnalysis = await analyzePotentialShot()
            
            // Update performance metrics
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            await updatePerformanceMetrics(processingTime: processingTime)
            
            // Check performance targets
            if processingTime > processingTimeout {
                logger.warning("Frame processing exceeded timeout: \(processingTime)s")
            }
            
            return FrameAnalysisResult(
                pose: pose,
                ball: ball,
                shotAnalysis: shotAnalysis,
                processingTime: processingTime
            )
            
        } catch {
            logger.error("Frame processing failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Reset all tracking state (call when starting new session)
    func resetTracking() {
        poseHistory.removeAll()
        ballTrajectoryPoints.removeAll()
        lastShotDetectionTime = 0
        shotInProgress = false
        currentPose = nil
        currentBallPosition = nil
        latestShotAnalysis = nil
        
        logger.info("Computer vision tracking reset")
    }
    
    /// Get current shooting form analysis
    var currentShootingForm: ShootingForm? {
        return currentPose?.shootingForm
    }
    
    // MARK: - Pose Detection
    
    private func detectPose(in pixelBuffer: CVPixelBuffer) async throws -> PoseResult? {
        return try await withCheckedThrowingContinuation { continuation in
            visionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ComputerVisionError.poseDetectionFailed)
                    return
                }
                
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
                
                do {
                    try handler.perform([self.poseRequest])
                    
                    guard let observation = self.poseRequest.results?.first else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    let poseResult = self.createPoseResult(from: observation)
                    
                    Task { @MainActor in
                        self.currentPose = poseResult
                    }
                    
                    continuation.resume(returning: poseResult)
                    
                } catch {
                    self.logger.error("Pose detection failed: \(error.localizedDescription)")
                    continuation.resume(throwing: ComputerVisionError.poseDetectionFailed)
                }
            }
        }
    }
    
    private func createPoseResult(from observation: VNHumanBodyPoseObservation) -> PoseResult {
        let timestamp = CFAbsoluteTimeGetCurrent()
        let confidence = observation.confidence
        
        // Extract key points
        var keyPoints: [PoseKeyPoint] = []
        
        let relevantJoints: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow, .leftWrist, .rightWrist,
            .leftHip, .rightHip, .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle
        ]
        
        for joint in relevantJoints {
            if let point = try? observation.recognizedPoint(joint) {
                let keyPoint = PoseKeyPoint(
                    type: joint,
                    position: CGPoint(x: point.location.x, y: 1.0 - point.location.y), // Flip Y coordinate
                    confidence: point.confidence
                )
                keyPoints.append(keyPoint)
            }
        }
        
        return PoseResult(
            timestamp: timestamp,
            confidence: confidence,
            keyPoints: keyPoints,
            boundingBox: observation.boundingBox
        )
    }
    
    // MARK: - Ball Detection
    
    private func detectBall(in pixelBuffer: CVPixelBuffer) async throws -> BallTrackingResult? {
        return try await withCheckedThrowingContinuation { continuation in
            visionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ComputerVisionError.ballTrackingFailed)
                    return
                }
                
                // Use object detection to find basketball
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
                
                do {
                    try handler.perform([self.ballDetectionRequest])
                    
                    // Look for basketball in results
                    let ballResult = self.findBasketball(in: self.ballDetectionRequest.results)
                    
                    Task { @MainActor in
                        self.currentBallPosition = ballResult
                    }
                    
                    continuation.resume(returning: ballResult)
                    
                } catch {
                    self.logger.error("Ball detection failed: \(error.localizedDescription)")
                    continuation.resume(throwing: ComputerVisionError.ballTrackingFailed)
                }
            }
        }
    }
    
    private func findBasketball(in observations: [VNRecognizedObjectObservation]?) -> BallTrackingResult? {
        guard let observations = observations else { return nil }
        
        // Look for objects that could be a basketball
        let basketballCandidates = observations.filter { observation in
            guard let topLabel = observation.labels.first else { return false }
            
            // Look for sports ball, sphere, or similar objects
            let basketballKeywords = ["ball", "sphere", "sports", "basketball"]
            return basketballKeywords.contains { keyword in
                topLabel.identifier.lowercased().contains(keyword)
            }
        }
        
        // Take the most confident basketball detection
        guard let bestCandidate = basketballCandidates.max(by: { $0.confidence < $1.confidence }) else {
            return nil
        }
        
        let timestamp = CFAbsoluteTimeGetCurrent()
        let position = CGPoint(
            x: bestCandidate.boundingBox.midX,
            y: 1.0 - bestCandidate.boundingBox.midY // Flip Y coordinate
        )
        
        // Calculate velocity if we have previous position
        var velocity = CGVector.zero
        if let lastBall = ballTrajectoryPoints.last {
            let deltaTime = timestamp - lastBall.timestamp
            if deltaTime > 0 {
                velocity = CGVector(
                    dx: (position.x - lastBall.position.x) / deltaTime,
                    dy: (position.y - lastBall.position.y) / deltaTime
                )
            }
        }
        
        return BallTrackingResult(
            timestamp: timestamp,
            position: position,
            velocity: velocity,
            confidence: bestCandidate.confidence,
            boundingBox: bestCandidate.boundingBox
        )
    }
    
    // MARK: - Shot Analysis
    
    private func analyzePotentialShot() async -> ShotAnalysis? {
        guard ballTrajectoryPoints.count >= 10 else { return nil } // Need minimum trajectory data
        
        let currentTime = CFAbsoluteTimeGetCurrent()
        
        // Check cooldown to prevent duplicate detections
        guard currentTime - lastShotDetectionTime > shotDetectionCooldown else { return nil }
        
        // Analyze ball trajectory for shooting motion
        let trajectory = BallTrajectory(
            points: ballTrajectoryPoints,
            startTime: ballTrajectoryPoints.first?.timestamp ?? currentTime,
            endTime: ballTrajectoryPoints.last?.timestamp ?? currentTime
        )
        
        // Detect if this looks like a shot
        guard isShootingMotion(trajectory) else { return nil }
        
        // Get corresponding pose data
        guard let shootingPose = findShootingPose(around: trajectory.startTime) else { return nil }
        
        // Classify shot type
        let shotType = classifyShotType(pose: shootingPose, trajectory: trajectory)
        
        // Determine outcome
        let outcome = classifyShotOutcome(trajectory: trajectory)
        
        // Calculate shot arc
        let shotArc = calculateShotArc(trajectory: trajectory)
        
        // Create shot analysis
        let shotAnalysis = ShotAnalysis(
            shotType: shotType,
            outcome: outcome,
            confidence: calculateShotConfidence(trajectory: trajectory, pose: shootingPose),
            timestamp: trajectory.startTime,
            duration: trajectory.duration,
            shootingForm: shootingPose.shootingForm,
            ballTrajectory: trajectory,
            releasePoint: trajectory.points.first?.position ?? .zero,
            peakHeight: trajectory.peakHeight,
            shotArc: shotArc
        )
        
        // Update state
        lastShotDetectionTime = currentTime
        latestShotAnalysis = shotAnalysis
        
        logger.info("Shot detected: \(shotType.description) - \(outcome.rawValue)")
        
        return shotAnalysis
    }
    
    private func isShootingMotion(_ trajectory: BallTrajectory) -> Bool {
        guard trajectory.points.count >= 5 else { return false }
        
        // Check for upward then downward motion (parabolic trajectory)
        let firstThird = trajectory.points.prefix(trajectory.points.count / 3)
        let lastThird = trajectory.points.suffix(trajectory.points.count / 3)
        
        let startHeight = firstThird.first?.position.y ?? 0
        let peakHeight = trajectory.peakHeight
        let endHeight = lastThird.last?.position.y ?? 0
        
        // Must have significant upward motion followed by downward
        let upwardMotion = startHeight - peakHeight > 0.1 // 10% of screen height
        let downwardMotion = peakHeight - endHeight < -0.05 // 5% of screen height
        
        return upwardMotion && downwardMotion
    }
    
    private func findShootingPose(around timestamp: TimeInterval) -> PoseResult? {
        let tolerance: TimeInterval = 0.5 // 500ms tolerance
        
        return poseHistory.first { pose in
            abs(pose.timestamp - timestamp) < tolerance
        }
    }
    
    private func classifyShotType(pose: PoseResult, trajectory: BallTrajectory) -> ShotType {
        let releaseHeight = trajectory.points.first?.position.y ?? 0
        let distance = calculateShotDistance(trajectory: trajectory)
        
        // Simple classification based on release point and distance
        if distance > 0.7 { // Far shots
            return .threePointer
        } else if releaseHeight > 0.8 { // High release point, close to basket
            return .layup
        } else {
            return .jumpShot
        }
    }
    
    private func classifyShotOutcome(trajectory: BallTrajectory) -> ShotOutcome {
        // Simplified outcome detection - in a real implementation,
        // this would require rim detection and more sophisticated analysis
        let endPoint = trajectory.points.last?.position ?? .zero
        let peakHeight = trajectory.peakHeight
        
        // Heuristic: shots that end in the top-center area after a good arc are likely made
        let isInTargetArea = endPoint.x > 0.4 && endPoint.x < 0.6 && endPoint.y < 0.3
        let hasGoodArc = abs(peakHeight - 0.2) < 0.1 // Peak around 20% from top
        
        if isInTargetArea && hasGoodArc {
            return .made
        } else {
            return .missed
        }
    }
    
    private func calculateShotArc(_ trajectory: BallTrajectory) -> Float {
        guard trajectory.points.count >= 3 else { return 0 }
        
        let start = trajectory.points.first!.position
        let peak = CGPoint(x: 0, y: trajectory.peakHeight)
        let end = trajectory.points.last!.position
        
        // Calculate angle using peak height and horizontal distance
        let horizontalDistance = abs(end.x - start.x)
        let verticalRise = abs(peak.y - start.y)
        
        guard horizontalDistance > 0 else { return 0 }
        
        let angle = atan(verticalRise / horizontalDistance) * 180 / .pi
        return Float(angle)
    }
    
    private func calculateShotDistance(_ trajectory: BallTrajectory) -> Float {
        guard let start = trajectory.points.first?.position,
              let end = trajectory.points.last?.position else { return 0 }
        
        let distance = sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2))
        return Float(distance)
    }
    
    private func calculateShotConfidence(trajectory: BallTrajectory, pose: PoseResult) -> Float {
        let trajectoryConfidence = trajectory.points.map { $0.confidence }.average()
        let poseConfidence = pose.confidence
        let dataQuality = min(1.0, Float(trajectory.points.count) / 30.0) // More points = higher confidence
        
        return (trajectoryConfidence + poseConfidence + dataQuality) / 3.0
    }
    
    // MARK: - State Management
    
    private func updatePoseHistory(_ pose: PoseResult) async {
        poseHistory.append(pose)
        
        // Keep only recent poses
        if poseHistory.count > maxPoseHistoryCount {
            poseHistory.removeFirst(poseHistory.count - maxPoseHistoryCount)
        }
    }
    
    private func updateBallTrajectory(_ ball: BallTrackingResult) async {
        ballTrajectoryPoints.append(ball)
        
        // Keep only recent trajectory
        if ballTrajectoryPoints.count > maxBallTrajectoryCount {
            ballTrajectoryPoints.removeFirst(ballTrajectoryPoints.count - maxBallTrajectoryCount)
        }
    }
    
    private func updatePerformanceMetrics(processingTime: TimeInterval) async {
        processingTimes.append(processingTime)
        
        // Keep only recent measurements
        if processingTimes.count > 60 {
            processingTimes.removeFirst()
        }
        
        let currentTime = CFAbsoluteTimeGetCurrent()
        let frameRate = lastFrameTime > 0 ? 1.0 / (currentTime - lastFrameTime) : 0
        lastFrameTime = currentTime
        
        let averageProcessingTime = processingTimes.average()
        let memoryUsage = getMemoryUsage()
        
        performanceMetrics = CVPerformanceMetrics(
            processingTime: averageProcessingTime,
            frameRate: frameRate,
            memoryUsage: memoryUsage,
            confidence: currentPose?.confidence ?? 0
        )
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

// MARK: - Supporting Types

struct FrameAnalysisResult {
    let pose: PoseResult?
    let ball: BallTrackingResult?
    let shotAnalysis: ShotAnalysis?
    let processingTime: TimeInterval
}

// MARK: - Extensions

extension Array where Element == Float {
    func average() -> Float {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Float(count)
    }
}

extension Array where Element == TimeInterval {
    func average() -> TimeInterval {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / TimeInterval(count)
    }
} 