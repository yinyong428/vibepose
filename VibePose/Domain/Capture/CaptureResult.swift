import Foundation
import UIKit

enum CaptureTrigger: String, Hashable {
    case manual
    case automatic
}

enum CaptureRepresentation: String, Hashable {
    case stillPhoto
    case liveFrameFallback
}

struct CaptureResult: Identifiable {
    let id = UUID()
    let image: UIImage
    let templateDisplayNameKey: String
    let score: Double
    let trigger: CaptureTrigger
    let representation: CaptureRepresentation
    let capturedAt: Date
}

struct AutoCaptureDecision: Equatable {
    let state: AutoCaptureState
    let shouldTriggerCapture: Bool
}
