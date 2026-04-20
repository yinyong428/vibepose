import Foundation
import UIKit

struct CameraGuidanceCaptureCompletion {
    let result: CaptureResult?
    let shouldResetAutoCapture: Bool
}

struct CameraGuidanceDismissalState {
    let captureResult: CaptureResult?
    let autoCaptureState: AutoCaptureState
    let coachCopy: String
}

struct CameraGuidanceCaptureCoordinator {
    func completeCapture(
        stillImage: UIImage?,
        fallbackImage: UIImage?,
        selectedTemplate: PoseTemplate?,
        score: Double,
        trigger: CaptureTrigger,
        capturedAt: Date
    ) -> CameraGuidanceCaptureCompletion {
        CameraGuidanceCaptureCompletion(
            result: CaptureResultFactory.makeResult(
                stillImage: stillImage,
                fallbackImage: fallbackImage,
                templateDisplayNameKey: selectedTemplate?.displayNameKey ?? "template.unknown",
                score: score,
                trigger: trigger,
                capturedAt: capturedAt
            ),
            // Reset even on failure so auto-capture must earn a new cycle.
            shouldResetAutoCapture: true
        )
    }

    func makeDismissalState() -> CameraGuidanceDismissalState {
        CameraGuidanceDismissalState(
            captureResult: nil,
            autoCaptureState: .idle,
            coachCopy: "coach.idle"
        )
    }
}
