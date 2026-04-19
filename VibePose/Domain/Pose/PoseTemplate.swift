import Foundation

enum TemplateStatus: String, Codable {
    case draft
    case reviewReady = "review_ready"
    case qaReady = "qa_ready"
    case released
    case deprecated
    case blocked
}

enum PoseDifficulty: String, Codable, CaseIterable {
    case easy
    case medium
    case hard
}

enum PoseFraming: String, Codable {
    case fullBody = "full_body"
    case halfBody = "half_body"
    case seated
    case closeUp = "close_up"
}

enum CameraFacing: String, Codable {
    case front
    case back
}

enum MirrorPolicy: String, Codable {
    case allow
    case deny
    case autoByCamera = "auto_by_camera"
}

struct MatchingConfig: Codable, Hashable {
    let readyThreshold: Double
    let perfectThreshold: Double
    let holdDuration: Double
    let jointWeights: [JointName: Double]
}

struct GuideConfig: Codable, Hashable {
    let coachKey: String
    let photographerKey: String
    let framingKey: String
    let preferredCamera: CameraFacing
}

struct PoseTemplate: Codable, Hashable, Identifiable {
    let templateId: String
    let version: String
    let status: TemplateStatus
    let displayNameKey: String
    let subtitleKey: String?
    let sceneTags: [String]
    let styleTags: [String]
    let effectTags: [String]
    let framing: PoseFraming
    let subjectCount: Int
    let difficulty: PoseDifficulty
    let cameraFacing: [CameraFacing]
    let mirrorPolicy: MirrorPolicy
    let pose: CanonicalPose19
    let matching: MatchingConfig
    let guide: GuideConfig

    var id: String { templateId }
}

