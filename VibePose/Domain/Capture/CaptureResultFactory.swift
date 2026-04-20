import Foundation
import UIKit

enum CaptureResultFactory {
    static func makeResult(
        stillImage: UIImage?,
        fallbackImage: UIImage?,
        templateDisplayNameKey: String,
        score: Double,
        trigger: CaptureTrigger,
        capturedAt: Date
    ) -> CaptureResult? {
        if let stillImage {
            return CaptureResult(
                image: stillImage,
                templateDisplayNameKey: templateDisplayNameKey,
                score: score,
                trigger: trigger,
                representation: .stillPhoto,
                capturedAt: capturedAt
            )
        }

        guard let fallbackImage else { return nil }
        return CaptureResult(
            image: fallbackImage,
            templateDisplayNameKey: templateDisplayNameKey,
            score: score,
            trigger: trigger,
            representation: .liveFrameFallback,
            capturedAt: capturedAt
        )
    }
}
