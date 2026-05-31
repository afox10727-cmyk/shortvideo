import SwiftUI
import AVFoundation
import Observation

@Observable
final class RecordViewModel: NSObject {
    // Camera
    let captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureMovieFileOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    var cameraPosition: AVCaptureDevice.Position = .front

    // Recording state
    var isRecording = false
    var recordingProgress: Double = 0
    var recordedFileURL: URL?
    var showUpload = false

    // Permissions
    var cameraPermissionGranted = false
    var microphonePermissionGranted = false

    // Timer
    private var progressTimer: Timer?

    override init() {
        super.init()
        checkPermissions()
    }

    // MARK: - Permissions

    func checkPermissions() {
        Task {
            cameraPermissionGranted = await AVCaptureDevice.requestAccess(for: .video)
            microphonePermissionGranted = await AVCaptureDevice.requestAccess(for: .audio)
            if cameraPermissionGranted {
                setupCaptureSession()
            }
        }
    }

    // MARK: - Setup

    func setupCaptureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        // Video input
        guard let videoDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: cameraPosition
        ) else { return }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                videoDeviceInput = videoInput
            }
        } catch {
            print("Failed to add video input: \(error)")
        }

        // Audio input
        if microphonePermissionGranted,
           let audioDevice = AVCaptureDevice.default(for: .audio) {
            do {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if captureSession.canAddInput(audioInput) {
                    captureSession.addInput(audioInput)
                }
            } catch {
                print("Failed to add audio input: \(error)")
            }
        }

        // Video output
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        captureSession.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    // MARK: - Camera Flip

    func flipCamera() {
        guard let currentInput = videoDeviceInput else { return }
        let newPosition: AVCaptureDevice.Position = cameraPosition == .front ? .back : .front

        captureSession.beginConfiguration()
        captureSession.removeInput(currentInput)

        guard let newDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: newPosition
        ) else { return }

        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
                videoDeviceInput = newInput
                cameraPosition = newPosition
            }
        } catch {
            print("Failed to flip camera: \(error)")
            captureSession.addInput(currentInput) // Restore original
        }

        captureSession.commitConfiguration()
    }

    // MARK: - Recording

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "recording_\(UUID().uuidString).mov"
        let fileURL = tempDir.appendingPathComponent(fileName)

        videoOutput.startRecording(to: fileURL, recordingDelegate: self)
        isRecording = true
        recordingProgress = 0

        // Update progress every 0.1s
        let maxDuration: Double = Constants.maxVideoDuration
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingProgress += 0.1 / maxDuration
            if self.recordingProgress >= 1.0 {
                self.stopRecording()
            }
        }
    }

    private func stopRecording() {
        videoOutput.stopRecording()
        isRecording = false
        progressTimer?.invalidate()
        progressTimer = nil
    }

    // MARK: - Cleanup

    func cleanup() {
        captureSession.stopRunning()
        progressTimer?.invalidate()
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension RecordViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        if let error = error {
            print("Recording error: \(error)")
            return
        }
        recordedFileURL = outputFileURL
        showUpload = true
    }
}
