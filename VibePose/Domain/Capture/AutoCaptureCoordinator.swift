import Foundation

enum AutoCaptureState: Equatable {
    case idle
    case noPerson
    case aligning(Double)
    case ready(Double)
    case perfect(Double)
    case countdown(Int)
}

actor AutoCaptureCoordinator {
    private var perfectStart: TimeInterval?

    func evaluate(
        score: PoseScore,
        target: PoseTemplate?,
        autoCaptureEnabled: Bool,
        timestamp: TimeInterval
    ) -> AutoCaptureState {
        guard target != nil, score.coverage > 0.25 else {
            perfectStart = nil
            return .noPerson
        }

        guard let target else {
            perfectStart = nil
            return .idle
        }

        if score.value >= target.matching.perfectThreshold {
            if !autoCaptureEnabled {
                perfectStart = nil
                return .perfect(score.value)
            }

            if perfectStart == nil {
                perfectStart = timestamp
            }

            let elapsed = timestamp - (perfectStart ?? timestamp)
            if elapsed >= target.matching.holdDuration {
                let remaining = max(1, 3 - Int(elapsed - target.matching.holdDuration))
                return .countdown(remaining)
            }

            return .perfect(score.value)
        }

        perfectStart = nil

        if score.value >= target.matching.readyThreshold {
            return .ready(score.value)
        }

        return .aligning(score.value)
    }
}

