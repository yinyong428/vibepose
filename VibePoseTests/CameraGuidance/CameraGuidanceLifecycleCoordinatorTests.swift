import XCTest
@testable import VibePose

final class CameraGuidanceLifecycleCoordinatorTests: XCTestCase {
    func testStartReturnsFalseWhenCameraAccessDenied() async {
        let camera = MockCameraSessionController(authorized: false)
        let motion = MockMotionService()
        let coordinator = CameraGuidanceLifecycleCoordinator(
            cameraController: camera,
            motionService: motion
        )

        let authorized = await coordinator.start { _ in }

        XCTAssertFalse(authorized)
        XCTAssertEqual(camera.configureSessionCalls, 0)
        XCTAssertEqual(camera.startRunningCalls, 0)
        XCTAssertEqual(motion.startCalls, 0)
    }

    func testStartConfiguresCameraStartsMotionAndFormatsPitch() async {
        let camera = MockCameraSessionController(authorized: true)
        let motion = MockMotionService()
        let coordinator = CameraGuidanceLifecycleCoordinator(
            cameraController: camera,
            motionService: motion
        )
        var receivedPitchText: [String] = []

        let authorized = await coordinator.start { receivedPitchText.append($0) }
        motion.emit(0.456)

        XCTAssertTrue(authorized)
        XCTAssertEqual(camera.configureSessionCalls, 1)
        XCTAssertEqual(camera.startRunningCalls, 1)
        XCTAssertEqual(motion.startCalls, 1)
        XCTAssertEqual(receivedPitchText, ["0.46 rad"])
    }

    func testStopStopsCameraAndMotion() {
        let camera = MockCameraSessionController(authorized: true)
        let motion = MockMotionService()
        let coordinator = CameraGuidanceLifecycleCoordinator(
            cameraController: camera,
            motionService: motion
        )

        coordinator.stop()

        XCTAssertEqual(camera.stopRunningCalls, 1)
        XCTAssertEqual(motion.stopCalls, 1)
    }

    func testFormatPitchUsesTwoDecimalPlaces() {
        XCTAssertEqual(CameraGuidanceLifecycleCoordinator.formatPitch(-0.004), "-0.00 rad")
        XCTAssertEqual(CameraGuidanceLifecycleCoordinator.formatPitch(1.234), "1.23 rad")
    }
}

private final class MockCameraSessionController: CameraSessionControlling {
    let authorized: Bool
    private(set) var configureSessionCalls = 0
    private(set) var startRunningCalls = 0
    private(set) var stopRunningCalls = 0

    init(authorized: Bool) {
        self.authorized = authorized
    }

    func requestAccess() async -> Bool {
        authorized
    }

    func configureSession() {
        configureSessionCalls += 1
    }

    func startRunning() {
        startRunningCalls += 1
    }

    func stopRunning() {
        stopRunningCalls += 1
    }
}

private final class MockMotionService: MotionServicing {
    private(set) var startCalls = 0
    private(set) var stopCalls = 0
    private var onUpdate: ((Double) -> Void)?

    func start(onUpdate: @escaping (Double) -> Void) {
        startCalls += 1
        self.onUpdate = onUpdate
    }

    func stop() {
        stopCalls += 1
    }

    func emit(_ pitch: Double) {
        onUpdate?(pitch)
    }
}
