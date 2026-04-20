import AVFoundation
import CoreImage
import CoreMedia
import UIKit

final class CameraSessionController: NSObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    let captureQueue = DispatchQueue(label: "com.vibepose.capture")
    let videoOutput = AVCaptureVideoDataOutput()
    let photoOutput = AVCapturePhotoOutput()

    var onSampleBuffer: ((CMSampleBuffer) -> Void)?
    private var currentInput: AVCaptureDeviceInput?
    private(set) var currentPosition: AVCaptureDevice.Position = .front
    private let ciContext = CIContext()
    private var latestSampleBuffer: CMSampleBuffer?
    private var pendingPhotoCapture: CheckedContinuation<UIImage?, Never>?

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

            if self.photoOutput.connection(with: .video) == nil, self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                self.photoOutput.isHighResolutionCaptureEnabled = true
                self.photoOutput.maxPhotoQualityPrioritization = .quality
            }

            if let connection = self.videoOutput.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
                connection.isVideoMirrored = self.currentPosition == .front
            }

            if let connection = self.photoOutput.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = self.currentPosition == .front
                }
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

    func captureLatestFrame() async -> UIImage? {
        await withCheckedContinuation { continuation in
            captureQueue.async {
                guard let sampleBuffer = self.latestSampleBuffer else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: self.makeImage(from: sampleBuffer))
            }
        }
    }

    func capturePhoto() async -> UIImage? {
        await withCheckedContinuation { continuation in
            captureQueue.async {
                guard self.pendingPhotoCapture == nil else {
                    continuation.resume(returning: nil)
                    return
                }

                self.pendingPhotoCapture = continuation
                let settings = AVCapturePhotoSettings()
                settings.photoQualityPrioritization = .quality

                if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    settings.isHighResolutionPhotoEnabled = true
                }

                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    private func camera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }

    private func makeImage(from sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }

        let orientation: UIImage.Orientation = currentPosition == .front ? .leftMirrored : .right
        let image = UIImage(cgImage: cgImage, scale: 1, orientation: orientation)
        return normalizedImage(from: image)
    }

    private func resolvePhotoCapture(with image: UIImage?) {
        let continuation = pendingPhotoCapture
        pendingPhotoCapture = nil
        continuation?.resume(returning: image)
    }
}

extension CameraSessionController: CameraSessionControlling {}

extension CameraSessionController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        var copiedBuffer: CMSampleBuffer?
        CMSampleBufferCreateCopy(allocator: kCFAllocatorDefault, sampleBuffer: sampleBuffer, sampleBufferOut: &copiedBuffer)
        latestSampleBuffer = copiedBuffer
        onSampleBuffer?(sampleBuffer)
    }
}

extension CameraSessionController {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            resolvePhotoCapture(with: nil)
            return
        }

        resolvePhotoCapture(with: normalizedImage(from: image))
    }

    private func normalizedImage(from image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}
