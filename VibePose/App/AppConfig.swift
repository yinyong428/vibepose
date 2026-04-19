import Foundation

struct RuntimeConfig {
    let baselineDevice: String
    let targetInferenceFPS: ClosedRange<Int>
    let uiRefreshMode: String
}

struct FeatureFlags {
    var autoCaptureEnabled = true
    var faceAssistEnabled = false
    var copyPoseEnabled = false
    var photographerGuidanceEnabled = true
    var overlayScreenshotEnabled = false
    var watermarkEnabled = false
}

enum ReleaseCutLine: String, CaseIterable, Identifiable {
    case mustShip = "Must Ship"
    case shouldShip = "Should Ship"
    case stretch = "Stretch"

    var id: String { rawValue }
}

enum AppConfig {
    static let runtime = RuntimeConfig(
        baselineDevice: "A15",
        targetInferenceFPS: 12...15,
        uiRefreshMode: "Adaptive 30/60Hz"
    )

    static let starterPackFileName = "starter_pack"
    static let starterPackFileExtension = "json"
}

