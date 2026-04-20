import CoreMedia
import Vision

enum CameraGuidanceSubjectStatus: Equatable {
    case clear
    case noPerson
    case multiPersonUnsupported
}

struct VisionPoseDetection {
    let pose: CanonicalPose19?
    let subjectStatus: CameraGuidanceSubjectStatus
}

actor VisionPoseDetector {
    private let request = VNDetectHumanBodyPoseRequest()

    func detectPose(in buffer: CMSampleBuffer, mirrored: Bool) async -> VisionPoseDetection {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            return VisionPoseDetection(pose: nil, subjectStatus: .noPerson)
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)

        do {
            try handler.perform([request])
            let observations = request.results ?? []
            let subjectStatus = Self.subjectStatus(forObservationCount: observations.count)
            guard subjectStatus == .clear, let observation = observations.first else {
                return VisionPoseDetection(pose: nil, subjectStatus: subjectStatus)
            }

            let recognizedPoints = try observation.recognizedPoints(.all)
            let pose = Self.map(points: recognizedPoints, mirrored: mirrored)
            return VisionPoseDetection(
                pose: pose,
                subjectStatus: pose == nil ? .noPerson : .clear
            )
        } catch {
            return VisionPoseDetection(pose: nil, subjectStatus: .noPerson)
        }
    }

    static func subjectStatus(forObservationCount count: Int) -> CameraGuidanceSubjectStatus {
        switch count {
        case 0:
            return .noPerson
        case 1:
            return .clear
        default:
            return .multiPersonUnsupported
        }
    }

    static func map(points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint], mirrored: Bool) -> CanonicalPose19? {
        var canonical: [JointName: PosePoint] = [:]

        func makePoint(_ joint: JointName, from visionJoint: VNHumanBodyPoseObservation.JointName) {
            guard let point = points[visionJoint], point.confidence > 0 else { return }
            let x = mirrored ? 1 - Double(point.location.x) : Double(point.location.x)
            let y = 1 - Double(point.location.y)
            canonical[joint] = PosePoint(joint: joint, x: x, y: y, confidence: Double(point.confidence))
        }

        makePoint(.nose, from: .nose)
        makePoint(.leftShoulder, from: .leftShoulder)
        makePoint(.rightShoulder, from: .rightShoulder)
        makePoint(.leftElbow, from: .leftElbow)
        makePoint(.rightElbow, from: .rightElbow)
        makePoint(.leftWrist, from: .leftWrist)
        makePoint(.rightWrist, from: .rightWrist)
        makePoint(.leftHip, from: .leftHip)
        makePoint(.rightHip, from: .rightHip)
        makePoint(.leftKnee, from: .leftKnee)
        makePoint(.rightKnee, from: .rightKnee)
        makePoint(.leftAnkle, from: .leftAnkle)
        makePoint(.rightAnkle, from: .rightAnkle)
        makePoint(.leftEye, from: .leftEye)
        makePoint(.rightEye, from: .rightEye)
        makePoint(.leftEar, from: .leftEar)
        makePoint(.rightEar, from: .rightEar)

        if
            let leftShoulder = canonical[.leftShoulder],
            let rightShoulder = canonical[.rightShoulder]
        {
            canonical[.neck] = PosePoint(
                joint: .neck,
                x: (leftShoulder.x + rightShoulder.x) / 2,
                y: (leftShoulder.y + rightShoulder.y) / 2,
                confidence: min(leftShoulder.confidence, rightShoulder.confidence)
            )
        }

        if
            let leftHip = canonical[.leftHip],
            let rightHip = canonical[.rightHip]
        {
            canonical[.pelvis] = PosePoint(
                joint: .pelvis,
                x: (leftHip.x + rightHip.x) / 2,
                y: (leftHip.y + rightHip.y) / 2,
                confidence: min(leftHip.confidence, rightHip.confidence)
            )
        }

        guard !canonical.isEmpty else { return nil }
        let coverage = Double(canonical.count) / Double(JointName.allCases.count)
        return CanonicalPose19(
            points: canonical,
            coverage: coverage,
            source: .vision,
            mirrorMode: mirrored ? .force : .none
        )
    }
}
