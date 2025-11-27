import AVFoundation
import SwiftUI
import Vision
import os.log

/// Service for handling camera capture and real-time video processing
class CameraService: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "BasketballCoachApp", category: "CameraService")
    
    // Camera components
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let audioOutput = AVCaptureAudioDataOutput()
    private var videoDevice: AVCaptureDevice?
    private var audioDevice: AVCaptureDevice?
    
    // Processing queues
    private let videoQueue = DispatchQueue(label: "video.queue", qos: .userInitiated)
    private let audioQueue = DispatchQueue(label: "audio.queue", qos: .userInitiated)
    
    // Services
    private let computerVisionService: ComputerVisionService
    private let geminiService: GeminiService?
    
    // Recording components
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    // State management
    @Published var isSessionRunning = false
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    @Published var currentAnalysis: ShotAnalysis?
    @Published var enhancedAnalysis: EnhancedShotAnalysis?
    @Published var sessionShots: [ShotAnalysis] = []
    @Published var error: CameraError?
    
    // Configuration
    private let preferredVideoSize = CGSize(width: 1920, height: 1080)
    private let frameRate: Double = 30.0
    private let maxRecordingDuration: TimeInterval = 1800 // 30 minutes
    
    // Frame processing
    private var lastFrameTime: CMTime = .zero
    private var frameCount: Int = 0
    private var analysisFrameInterval: Int = 5 // Analyze every 5th frame for performance
    
    // MARK: - Initialization
    
    init(computerVisionService: ComputerVisionService, geminiService: GeminiService? = nil) {
        self.computerVisionService = computerVisionService
        self.geminiService = geminiService
        
        super.init()
        
        setupCaptureSession()
        logger.info("CameraService initialized")
    }
    
    // MARK: - Public API
    
    /// Start the camera session
    func startSession() {
        logger.info("Starting camera session")
        
        Task {
            await requestPermissions()
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                self.captureSession.startRunning()
                
                DispatchQueue.main.async {
                    self.isSessionRunning = self.captureSession.isRunning
                    self.logger.info("Camera session started: \(self.isSessionRunning)")
                }
            }
        }
    }
    
    /// Stop the camera session
    func stopSession() {
        logger.info("Stopping camera session")
        
        if isRecording {
            stopRecording()
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.stopRunning()
            
            DispatchQueue.main.async {
                self.isSessionRunning = false
                self.logger.info("Camera session stopped")
            }
        }
    }
    
    /// Toggle between front and back camera
    func toggleCamera() {
        logger.info("Toggling camera position")
        
        let newPosition: AVCaptureDevice.Position = cameraPosition == .back ? .front : .back
        
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            logger.error("Failed to get camera device for position: \(newPosition.rawValue)")
            return
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            
            captureSession.beginConfiguration()
            
            // Remove old input
            if let currentInput = captureSession.inputs.first {
                captureSession.removeInput(currentInput)
            }
            
            // Add new input
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
                videoDevice = newDevice
                cameraPosition = newPosition
                logger.info("Camera toggled to: \(newPosition == .back ? "back" : "front")")
            } else {
                logger.error("Cannot add new camera input")
            }
            
            captureSession.commitConfiguration()
            
        } catch {
            logger.error("Error toggling camera: \(error.localizedDescription)")
            self.error = .cameraToggleFailure(error.localizedDescription)
        }
    }
    
    /// Start recording video
    func startRecording() {
        logger.info("Starting video recording")
        
        guard !isRecording else {
            logger.warning("Recording already in progress")
            return
        }
        
        guard isSessionRunning else {
            logger.error("Cannot start recording - session not running")
            return
        }
        
        setupVideoRecording()
        isRecording = true
        sessionShots.removeAll()
        
        logger.info("Video recording started")
    }
    
    /// Stop recording video
    func stopRecording() {
        logger.info("Stopping video recording")
        
        guard isRecording else {
            logger.warning("No recording in progress")
            return
        }
        
        isRecording = false
        finishVideoRecording()
        
        logger.info("Video recording stopped")
    }
    
    /// Get current session summary
    func getSessionSummary() async -> SessionSummary? {
        guard !sessionShots.isEmpty else {
            logger.info("No shots in session for summary")
            return nil
        }
        
        guard let geminiService = geminiService else {
            logger.info("No Gemini service available for session summary")
            return createBasicSessionSummary()
        }
        
        do {
            let summary = try await geminiService.generateSessionSummary(sessionShots)
            logger.info("Session summary generated with Gemini")
            return summary
        } catch {
            logger.error("Failed to generate Gemini session summary: \(error.localizedDescription)")
            return createBasicSessionSummary()
        }
    }
    
    /// Clear current session data
    func clearSession() {
        sessionShots.removeAll()
        currentAnalysis = nil
        enhancedAnalysis = nil
        logger.info("Session data cleared")
    }
    
    // MARK: - Private Methods
    
    private func setupCaptureSession() {
        captureSession.sessionPreset = .high
        
        // Configure video device
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            logger.error("Failed to get video device")
            return
        }
        
        self.videoDevice = videoDevice
        
        do {
            // Add video input
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                logger.info("Video input added")
            }
            
            // Add audio input
            if let audioDevice = AVCaptureDevice.default(for: .audio) {
                self.audioDevice = audioDevice
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if captureSession.canAddInput(audioInput) {
                    captureSession.addInput(audioInput)
                    logger.info("Audio input added")
                }
            }
            
            // Configure video output
            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
                logger.info("Video output added")
            }
            
            // Configure audio output
            audioOutput.setSampleBufferDelegate(self, queue: audioQueue)
            if captureSession.canAddOutput(audioOutput) {
                captureSession.addOutput(audioOutput)
                logger.info("Audio output added")
            }
            
            // Configure video orientation and frame rate
            configureVideoOutput()
            
        } catch {
            logger.error("Error setting up capture session: \(error.localizedDescription)")
            self.error = .setupFailure(error.localizedDescription)
        }
    }
    
    private func configureVideoOutput() {
        guard let connection = videoOutput.connection(with: .video) else {
            logger.error("No video connection found")
            return
        }
        
        // Set video orientation
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        // Set frame rate
        do {
            try videoDevice?.lockForConfiguration()
            
            // Find the best format for our preferred size
            let formats = videoDevice?.formats ?? []
            let bestFormat = formats.first { format in
                let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                return dimensions.width >= Int32(preferredVideoSize.width) && 
                       dimensions.height >= Int32(preferredVideoSize.height)
            }
            
            if let format = bestFormat {
                videoDevice?.activeFormat = format
                
                // Set frame rate
                let frameRateRange = format.videoSupportedFrameRateRanges.first { range in
                    range.maxFrameRate >= frameRate
                }
                
                if let range = frameRateRange {
                    videoDevice?.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
                    videoDevice?.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
                    logger.info("Frame rate set to \(frameRate) fps")
                }
            }
            
            videoDevice?.unlockForConfiguration()
        } catch {
            logger.error("Error configuring video device: \(error.localizedDescription)")
        }
    }
    
    private func setupVideoRecording() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.error("Cannot access documents directory")
            return
        }
        
        let timestamp = DateFormatter.fileNameFormatter.string(from: Date())
        let fileName = "basketball_session_\(timestamp).mp4"
        let outputURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }
            
            // Create asset writer
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
            
            // Configure video input
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: preferredVideoSize.width,
                AVVideoHeightKey: preferredVideoSize.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 2_000_000, // 2 Mbps
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel
                ]
            ]
            
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoInput?.expectsMediaDataInRealTime = true
            
            // Create pixel buffer adaptor
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoInput!,
                sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
            )
            
            // Configure audio input
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 64000
            ]
            
            audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioInput?.expectsMediaDataInRealTime = true
            
            // Add inputs to writer
            if let videoInput = videoInput, assetWriter?.canAdd(videoInput) == true {
                assetWriter?.add(videoInput)
            }
            
            if let audioInput = audioInput, assetWriter?.canAdd(audioInput) == true {
                assetWriter?.add(audioInput)
            }
            
            // Start writing
            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: .zero)
            
            logger.info("Video recording setup complete - output: \(outputURL.path)")
            
        } catch {
            logger.error("Error setting up video recording: \(error.localizedDescription)")
            self.error = .recordingSetupFailure(error.localizedDescription)
        }
    }
    
    private func finishVideoRecording() {
        guard let assetWriter = assetWriter else { return }
        
        videoInput?.markAsFinished()
        audioInput?.markAsFinished()
        
        assetWriter.finishWriting { [weak self] in
            guard let self = self else { return }
            
            if assetWriter.status == .completed {
                self.logger.info("Video recording finished successfully")
            } else {
                self.logger.error("Video recording failed: \(assetWriter.error?.localizedDescription ?? "Unknown error")")
            }
            
            DispatchQueue.main.async {
                self.assetWriter = nil
                self.videoInput = nil
                self.audioInput = nil
                self.pixelBufferAdaptor = nil
            }
        }
    }
    
    private func createBasicSessionSummary() -> SessionSummary {
        let totalShots = sessionShots.count
        let madeShots = sessionShots.filter { $0.outcome == .made }.count
        let accuracy = totalShots > 0 ? Float(madeShots) / Float(totalShots) : 0.0
        
        return SessionSummary(
            totalShots: totalShots,
            accuracy: accuracy,
            overallAssessment: "Session completed with \(totalShots) shots",
            keyStrengths: ["Consistent shooting rhythm"],
            improvementAreas: ["Focus on follow-through"],
            recommendedDrills: ["Form shooting", "Free throw practice"],
            nextSessionGoals: ["Improve accuracy", "Consistent form"],
            trackingMetrics: ["Shot percentage", "Form consistency"]
        )
    }
    
    private func requestPermissions() async {
        // Request camera permission
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraStatus == .notDetermined {
            await AVCaptureDevice.requestAccess(for: .video)
        }
        
        // Request microphone permission
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if audioStatus == .notDetermined {
            await AVCaptureDevice.requestAccess(for: .audio)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // Record video if needed
        if isRecording && output == videoOutput {
            recordVideoFrame(sampleBuffer)
        }
        
        // Process frames for computer vision
        if output == videoOutput {
            processVideoFrame(sampleBuffer)
        }
    }
    
    private func recordVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let videoInput = videoInput,
              let pixelBufferAdaptor = pixelBufferAdaptor,
              videoInput.isReadyForMoreMediaData else {
            return
        }
        
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
    
    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        frameCount += 1
        
        // Skip frames for performance (analyze every Nth frame)
        guard frameCount % analysisFrameInterval == 0 else {
            return
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        // Skip if we're already processing
        guard !isProcessing else {
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                // Convert to UIImage for processing
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                let context = CIContext()
                
                guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                    return
                }
                
                let image = UIImage(cgImage: cgImage)
                
                // Perform computer vision analysis
                let analysis = try await computerVisionService.analyzeShootingForm(in: image)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.currentAnalysis = analysis
                    
                    // Add significant shots to session
                    if analysis.confidence > 0.7 {
                        self.sessionShots.append(analysis)
                        
                        // Enhance analysis with Gemini if available
                        if let geminiService = self.geminiService {
                            Task {
                                do {
                                    let enhanced = try await geminiService.enhanceShotAnalysis(analysis)
                                    await MainActor.run {
                                        self.enhancedAnalysis = enhanced
                                    }
                                } catch {
                                    self.logger.error("Failed to enhance analysis: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                    
                    self.isProcessing = false
                }
                
            } catch {
                logger.error("Error processing video frame: \(error.localizedDescription)")
                DispatchQueue.main.async { [weak self] in
                    self?.isProcessing = false
                }
            }
        }
    }
}

// MARK: - AVCaptureAudioDataOutputSampleBufferDelegate

extension CameraService: AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // Record audio if needed
        if isRecording && output == audioOutput {
            recordAudioFrame(sampleBuffer)
        }
    }
    
    private func recordAudioFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let audioInput = audioInput,
              audioInput.isReadyForMoreMediaData else {
            return
        }
        
        audioInput.append(sampleBuffer)
    }
}

// MARK: - Supporting Types

enum CameraError: Error, LocalizedError {
    case setupFailure(String)
    case recordingSetupFailure(String)
    case cameraToggleFailure(String)
    case permissionDenied
    case deviceNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .setupFailure(let message):
            return "Camera setup failed: \(message)"
        case .recordingSetupFailure(let message):
            return "Recording setup failed: \(message)"
        case .cameraToggleFailure(let message):
            return "Camera toggle failed: \(message)"
        case .permissionDenied:
            return "Camera permission denied"
        case .deviceNotAvailable:
            return "Camera device not available"
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
} 