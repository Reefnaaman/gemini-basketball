import Foundation
import Vision
import CoreGraphics
import simd

// MARK: - Pose Detection Models

struct PoseResult {
    let timestamp: TimeInterval
    let confidence: Float
    let keyPoints: [PoseKeyPoint]
    let boundingBox: CGRect
    
    // Basketball-specific pose analysis
    var shootingForm: ShootingForm {
        return ShootingForm(from: keyPoints)
    }
}

struct PoseKeyPoint {
    let type: VNHumanBodyPoseObservation.JointName
    let position: CGPoint
    let confidence: Float
    
    var isValid: Bool {
        return confidence > 0.5
    }
}

struct ShootingForm {
    let elbowAlignment: Float      // 0-1 (1 = perfect alignment)
    let shoulderSquare: Float      // 0-1 (1 = perfectly square)
    let kneeFlexion: Float         // 0-1 (1 = optimal bend)
    let followThrough: Float       // 0-1 (1 = perfect follow-through)
    let balance: Float             // 0-1 (1 = perfect balance)
    
    var overallScore: Float {
        return (elbowAlignment + shoulderSquare + kneeFlexion + followThrough + balance) / 5.0
    }
    
    init(from keyPoints: [PoseKeyPoint]) {
        // Calculate shooting form metrics from pose keypoints
        self.elbowAlignment = Self.calculateElbowAlignment(keyPoints)
        self.shoulderSquare = Self.calculateShoulderAlignment(keyPoints)
        self.kneeFlexion = Self.calculateKneeFlexion(keyPoints)
        self.followThrough = Self.calculateFollowThrough(keyPoints)
        self.balance = Self.calculateBalance(keyPoints)
    }
    
    private static func calculateElbowAlignment(_ keyPoints: [PoseKeyPoint]) -> Float {
        guard let rightWrist = keyPoints.first(where: { $0.type == .rightWrist }),
              let rightElbow = keyPoints.first(where: { $0.type == .rightElbow }),
              let rightShoulder = keyPoints.first(where: { $0.type == .rightShoulder }) else {
            return 0.0
        }
        
        // Calculate if elbow is properly aligned under the ball
        let shoulderToElbow = CGVector(
            dx: rightElbow.position.x - rightShoulder.position.x,
            dy: rightElbow.position.y - rightShoulder.position.y
        )
        let elbowToWrist = CGVector(
            dx: rightWrist.position.x - rightElbow.position.x,
            dy: rightWrist.position.y - rightElbow.position.y
        )
        
        // Perfect alignment would have minimal horizontal deviation
        let horizontalDeviation = abs(shoulderToElbow.dx + elbowToWrist.dx)
        return max(0, 1.0 - Float(horizontalDeviation * 2))
    }
    
    private static func calculateShoulderAlignment(_ keyPoints: [PoseKeyPoint]) -> Float {
        guard let leftShoulder = keyPoints.first(where: { $0.type == .leftShoulder }),
              let rightShoulder = keyPoints.first(where: { $0.type == .rightShoulder }) else {
            return 0.0
        }
        
        // Calculate if shoulders are square (horizontal)
        let shoulderSlope = abs(rightShoulder.position.y - leftShoulder.position.y) / 
                           abs(rightShoulder.position.x - leftShoulder.position.x)
        return max(0, 1.0 - Float(shoulderSlope * 10))
    }
    
    private static func calculateKneeFlexion(_ keyPoints: [PoseKeyPoint]) -> Float {
        guard let rightHip = keyPoints.first(where: { $0.type == .rightHip }),
              let rightKnee = keyPoints.first(where: { $0.type == .rightKnee }),
              let rightAnkle = keyPoints.first(where: { $0.type == .rightAnkle }) else {
            return 0.0
        }
        
        // Calculate knee angle for proper shooting stance
        let hipToKnee = CGVector(
            dx: rightKnee.position.x - rightHip.position.x,
            dy: rightKnee.position.y - rightHip.position.y
        )
        let kneeToAnkle = CGVector(
            dx: rightAnkle.position.x - rightKnee.position.x,
            dy: rightAnkle.position.y - rightKnee.position.y
        )
        
        let angle = atan2(hipToKnee.dy, hipToKnee.dx) - atan2(kneeToAnkle.dy, kneeToAnkle.dx)
        let normalizedAngle = abs(angle)
        
        // Optimal knee flexion is around 15-30 degrees
        let optimalRange: ClosedRange<Float> = 0.26...0.52 // radians
        if optimalRange.contains(Float(normalizedAngle)) {
            return 1.0
        } else {
            let deviation = min(abs(Float(normalizedAngle) - optimalRange.lowerBound),
                              abs(Float(normalizedAngle) - optimalRange.upperBound))
            return max(0, 1.0 - deviation * 2)
        }
    }
    
    private static func calculateFollowThrough(_ keyPoints: [PoseKeyPoint]) -> Float {
        guard let rightWrist = keyPoints.first(where: { $0.type == .rightWrist }),
              let rightElbow = keyPoints.first(where: { $0.type == .rightElbow }) else {
            return 0.0
        }
        
        // Follow-through should have wrist below elbow after release
        let wristBelowElbow = rightWrist.position.y > rightElbow.position.y
        return wristBelowElbow ? 1.0 : 0.0
    }
    
    private static func calculateBalance(_ keyPoints: [PoseKeyPoint]) -> Float {
        guard let leftAnkle = keyPoints.first(where: { $0.type == .leftAnkle }),
              let rightAnkle = keyPoints.first(where: { $0.type == .rightAnkle }),
              let nose = keyPoints.first(where: { $0.type == .nose }) else {
            return 0.0
        }
        
        // Center of gravity should be between feet
        let feetCenter = CGPoint(
            x: (leftAnkle.position.x + rightAnkle.position.x) / 2,
            y: (leftAnkle.position.y + rightAnkle.position.y) / 2
        )
        
        let balanceDeviation = abs(nose.position.x - feetCenter.x)
        return max(0, 1.0 - Float(balanceDeviation * 5))
    }
}

// MARK: - Ball Tracking Models

struct BallTrackingResult {
    let timestamp: TimeInterval
    let position: CGPoint
    let velocity: CGVector
    let confidence: Float
    let boundingBox: CGRect
    
    var isValid: Bool {
        return confidence > 0.7
    }
}

struct BallTrajectory {
    let points: [BallTrackingResult]
    let startTime: TimeInterval
    let endTime: TimeInterval
    
    var duration: TimeInterval {
        return endTime - startTime
    }
    
    var averageVelocity: CGVector {
        let velocities = points.map { $0.velocity }
        let sumX = velocities.reduce(0) { $0 + $1.dx }
        let sumY = velocities.reduce(0) { $0 + $1.dy }
        return CGVector(dx: sumX / CGFloat(velocities.count),
                       dy: sumY / CGFloat(velocities.count))
    }
    
    var peakHeight: CGFloat {
        return points.map { $0.position.y }.min() ?? 0 // Lower Y = higher in screen coordinates
    }
}

// MARK: - Shot Analysis Models

enum ShotType: String, CaseIterable {
    case jumpShot = "Jump Shot"
    case threePointer = "Three Pointer"
    case layup = "Layup"
    case freeThrow = "Free Throw"
    case hookShot = "Hook Shot"
    case fadeaway = "Fadeaway"
    
    var description: String {
        return self.rawValue
    }
}

enum ShotOutcome: String {
    case made = "made"
    case missed = "missed"
    case unknown = "unknown"
}

struct ShotAnalysis {
    let shotType: ShotType
    let outcome: ShotOutcome
    let confidence: Float
    let timestamp: TimeInterval
    let duration: TimeInterval
    
    // Technical analysis
    let shootingForm: ShootingForm
    let ballTrajectory: BallTrajectory
    let releasePoint: CGPoint
    let peakHeight: CGFloat
    let shotArc: Float // Degrees
    
    // AI-generated feedback
    var feedback: String {
        return generateFeedback()
    }
    
    private func generateFeedback() -> String {
        var feedbackComponents: [String] = []
        
        // Analyze shooting form
        if shootingForm.elbowAlignment < 0.7 {
            feedbackComponents.append("Keep your elbow under the ball for better accuracy")
        }
        
        if shootingForm.shoulderSquare < 0.7 {
            feedbackComponents.append("Square your shoulders to the basket")
        }
        
        if shootingForm.followThrough < 0.7 {
            feedbackComponents.append("Follow through with your wrist - snap it down")
        }
        
        if shootingForm.balance < 0.7 {
            feedbackComponents.append("Maintain better balance throughout your shot")
        }
        
        // Analyze trajectory
        if shotArc < 35 {
            feedbackComponents.append("Try to get more arc on your shot")
        } else if shotArc > 55 {
            feedbackComponents.append("You're shooting too high - flatten your arc slightly")
        }
        
        // Default positive feedback
        if feedbackComponents.isEmpty {
            if outcome == .made {
                return "Great shot! Keep up that form and follow-through."
            } else {
                return "Good form overall - sometimes shots just don't fall. Keep shooting!"
            }
        }
        
        return feedbackComponents.joined(separator(". ")) + "."
    }
}

// MARK: - Error Types

enum ComputerVisionError: Error, LocalizedError {
    case poseDetectionFailed
    case ballTrackingFailed
    case invalidFrame
    case processingTimeout
    case insufficientData
    
    var errorDescription: String? {
        switch self {
        case .poseDetectionFailed:
            return "Failed to detect player pose in frame"
        case .ballTrackingFailed:
            return "Failed to track basketball in frame"
        case .invalidFrame:
            return "Invalid video frame provided"
        case .processingTimeout:
            return "Computer vision processing timed out"
        case .insufficientData:
            return "Insufficient data for analysis"
        }
    }
}

// MARK: - Performance Metrics

struct CVPerformanceMetrics {
    let processingTime: TimeInterval
    let frameRate: Double
    let memoryUsage: Int64
    let confidence: Float
    
    var isWithinPerformanceTargets: Bool {
        return processingTime < 0.5 && frameRate >= 20.0 // PRD requirements
    }
} 