import AVFoundation
import CoreMedia

final class CameraSessionController: NSObject {
    let session = AVCaptureSession()
    let captureQueue = DispatchQueue(label: "com.vibepose.capture")
    let videoOutput = AVCaptureVideoDataOutput()

    var onSampleBuffer: ((CMSampleBuffer) -> Void)?
    private var currentInput: AVCaptureDeviceInput?
    private(set) var currentPosition: AVCaptureDevice.Position = .front

    func requestAccess() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    func configureSession() {
        captureQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            if let currentInput = self.currentInput {
                self.session.removeInput(currentInput)
            }

            guard let device = self.camera(for: self.currentPosition),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                self.session.commitConfiguration()
                return
            }

            self.currentInput = input
            self.session.addInput(input)

            if self.videoOutput.connection(with: .video) == nil {
                self.videoOutput.setSampleBufferDelegate(self, queue: self.captureQueue)
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                if self.session.canAddOutput(self.videoOutput) {
                    self.session.addOutput(self.videoOutput)
                }
            }

            if let connection = self.videoOutput.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
                connection.isVideoMirrored = self.currentPosition == .front
            }
            self.session.commitConfiguration()
        }
    }

    func startRunning() {
        captureQueue.async {
            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopRunning() {
        captureQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func toggleCamera() {
        currentPosition = currentPosition == .front ? .back : .front
        configureSession()
    }

    private func camera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }
}

extension CameraSessionController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        onSampleBuffer?(sampleBuffer)
    }
}
