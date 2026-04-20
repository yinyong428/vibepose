import Foundation

enum AutoCaptureState: Equatable {
    case idle
    case noPerson
    case partialSubject
    case multiPersonUnsupported
    case aligning(Double)
    case ready(Double)
    case perfect(Double)
    case countdown(Int)
}

actor AutoCaptureCoordinator {
    private var perfectStart: TimeInterval?
    private var hasTriggeredCapture = false
    private let countdownDuration: TimeInterval = 3

    func evaluate(
        score: PoseScore,
        target: PoseTemplate?,
        autoCaptureEnabled: Bool,
        timestamp: TimeInterval
    ) -> AutoCaptureDecision {
        guard target != nil, score.coverage > 0.25 else {
            reset()
            return AutoCaptureDecision(state: .noPerson, shouldTriggerCapture: false)
        }

        guard let target else {
            reset()
            return AutoCaptureDecision(state: .idle, shouldTriggerCapture: false)
        }

        if score.value >= target.matching.perfectThreshold {
            if !autoCaptureEnabled {
                perfectStart = nil
                hasTriggeredCapture = false
                return AutoCaptureDecision(state: .perfect(score.value), shouldTriggerCapture: false)
            }

            if perfectStart == nil {
                perfectStart = timestamp
                hasTriggeredCapture = false
            }

            let elapsed = timestamp - (perfectStart ?? timestamp)
            if elapsed < target.matching.holdDuration {
                return AutoCaptureDecision(state: .perfect(score.value), shouldTriggerCapture: false)
            }

            let countdownElapsed = elapsed - target.matching.holdDuration
            if countdownElapsed < countdownDuration {
                let remaining = max(1, Int(ceil(countdownDuration - countdownElapsed)))
                return AutoCaptureDecision(state: .countdown(remaining), shouldTriggerCapture: false)
            }

            guard !hasTriggeredCapture else {
                return AutoCaptureDecision(state: .countdown(1), shouldTriggerCapture: false)
            }

            hasTriggeredCapture = true
            return AutoCaptureDecision(state: .countdown(1), shouldTriggerCapture: true)
        }

        reset()

        if score.value >= target.matching.readyThreshold {
            return AutoCaptureDecision(state: .ready(score.value), shouldTriggerCapture: false)
        }

        return AutoCaptureDecision(state: .aligning(score.value), shouldTriggerCapture: false)
    }

    func reset() {
        perfectStart = nil
        hasTriggeredCapture = false
    }
}
