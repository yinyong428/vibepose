import Foundation

enum PoseEngineSource: String, Codable {
    case vision
    case importedImage
    case syntheticTemplate
}

enum PoseMirrorMode: String, Codable {
    case none
    case allow
    case force
}

enum JointName: String, Codable, CaseIterable, Hashable {
    case nose
    case neck
    case leftShoulder
    case rightShoulder
    case leftElbow
    case rightElbow
    case leftWrist
    case rightWrist
    case leftHip
    case rightHip
    case leftKnee
    case rightKnee
    case leftAnkle
    case rightAnkle
    case leftEye
    case rightEye
    case leftEar
    case rightEar
    case pelvis
}

struct PosePoint: Codable, Hashable {
    let joint: JointName
    let x: Double
    let y: Double
    let confidence: Double
}

struct CanonicalPose19: Codable, Hashable {
    let points: [JointName: PosePoint]
    let coverage: Double
    let source: PoseEngineSource
    let mirrorMode: PoseMirrorMode

    func point(for joint: JointName) -> CGPoint? {
        guard let point = points[joint] else { return nil }
        return CGPoint(x: point.x, y: point.y)
    }

    static let skeletonSegments: [(JointName, JointName)] = [
        (.nose, .neck),
        (.neck, .leftShoulder),
        (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow),
        (.rightShoulder, .rightElbow),
        (.leftElbow, .leftWrist),
        (.rightElbow, .rightWrist),
        (.neck, .pelvis),
        (.pelvis, .leftHip),
        (.pelvis, .rightHip),
        (.leftHip, .leftKnee),
        (.rightHip, .rightKnee),
        (.leftKnee, .leftAnkle),
        (.rightKnee, .rightAnkle),
        (.nose, .leftEye),
        (.nose, .rightEye),
        (.leftEye, .leftEar),
        (.rightEye, .rightEar)
    ]
}

