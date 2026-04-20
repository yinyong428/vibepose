import Foundation

protocol CameraSessionControlling: AnyObject {
    func requestAccess() async -> Bool
    func configureSession()
    func startRunning()
    func stopRunning()
}

protocol MotionServicing: AnyObject {
    func start(onUpdate: @escaping (Double) -> Void)
    func stop()
}

final class CameraGuidanceLifecycleCoordinator {
    private let cameraController: CameraSessionControlling
    private let motionService: MotionServicing

    init(
        cameraController: CameraSessionControlling,
        motionService: MotionServicing
    ) {
        self.cameraController = cameraController
        self.motionService = motionService
    }

    func start(onPitchUpdate: @escaping (String) -> Void) async -> Bool {
        let authorized = await cameraController.requestAccess()
        guard authorized else { return false }

        cameraController.configureSession()
        cameraController.startRunning()
        motionService.start { pitch in
            onPitchUpdate(Self.formatPitch(pitch))
        }
        return true
    }

    func stop() {
        cameraController.stopRunning()
        motionService.stop()
    }

    static func formatPitch(_ pitch: Double) -> String {
        String(format: "%.2f rad", pitch)
    }
}
