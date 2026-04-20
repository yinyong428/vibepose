import CoreMotion

final class MotionService {
    private let manager = CMMotionManager()

    func start(onUpdate: @escaping (Double) -> Void) {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 0.2
        manager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let pitch = motion?.attitude.pitch else { return }
            onUpdate(pitch)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}

extension MotionService: MotionServicing {}
