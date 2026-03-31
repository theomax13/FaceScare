import AVFoundation
import Vision
import AppKit

/// Sensitivity levels mapping to face bounding box width thresholds.
/// A larger bounding box means the face is closer to the camera.
enum Sensitivity: String, CaseIterable {
    case low = "Low"        // Face must fill 50% of frame width
    case medium = "Medium"  // Face must fill 40% of frame width
    case high = "High"      // Face must fill 30% of frame width

    /// The fraction of frame width the face bounding box must exceed to trigger a scare.
    var threshold: CGFloat {
        switch self {
        case .low:    return 0.50
        case .medium: return 0.40
        case .high:   return 0.30
        }
    }
}

/// FaceDetector uses AVCaptureSession and Vision to detect face proximity in real time.
///
/// It captures video frames from the front-facing webcam, runs `VNDetectFaceRectanglesRequest`
/// on each frame, and fires `onFaceTooClose` when the largest detected face bounding box
/// exceeds the configured sensitivity threshold.
final class FaceDetector: NSObject {

    // MARK: - Public API

    /// Callback fired on the main thread when a face is detected too close.
    var onFaceTooClose: (() -> Void)?

    /// Current sensitivity level (controls bounding box threshold).
    var sensitivity: Sensitivity = .medium

    /// Whether detection is actively running.
    private(set) var isRunning = false

    // MARK: - AVFoundation

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "com.theomax.facescare.facedetector", qos: .userInitiated)

    // MARK: - Vision

    private lazy var faceDetectionRequest: VNDetectFaceRectanglesRequest = {
        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            self?.handleFaceDetection(request: request, error: error)
        }
        // Prefer speed over accuracy for real-time detection
        request.revision = VNDetectFaceRectanglesRequestRevision3
        return request
    }()

    // MARK: - Lifecycle

    override init() {
        super.init()
        configureCaptureSession()
    }

    /// Start the webcam feed and face detection pipeline.
    func start() {
        guard !isRunning else { return }
        processingQueue.async { [weak self] in
            self?.captureSession.startRunning()
        }
        isRunning = true
    }

    /// Stop the webcam feed and face detection pipeline.
    func stop() {
        guard isRunning else { return }
        processingQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
        isRunning = false
    }

    // MARK: - Configuration

    private func configureCaptureSession() {
        captureSession.sessionPreset = .low // Low resolution is fine for face detection

        // Find the front-facing / built-in webcam
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified) else {
            print("[FaceScare] No camera found.")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            print("[FaceScare] Failed to create camera input: \(error.localizedDescription)")
            return
        }

        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
    }

    // MARK: - Vision Result Handling

    private func handleFaceDetection(request: VNRequest, error: Error?) {
        guard error == nil,
              let results = request.results as? [VNFaceObservation],
              let largestFace = results.max(by: { $0.boundingBox.width < $1.boundingBox.width })
        else { return }

        let faceWidth = largestFace.boundingBox.width // Normalized 0…1

        if faceWidth > sensitivity.threshold {
            DispatchQueue.main.async { [weak self] in
                self?.onFaceTooClose?()
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension FaceDetector: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([faceDetectionRequest])
        } catch {
            print("[FaceScare] Vision request failed: \(error.localizedDescription)")
        }
    }
}
