import CoreMedia
import Vision

actor VisionPoseDetector {
    private let request = VNDetectHumanBodyPoseRequest()

    func detectPose(in buffer: CMSampleBuffer, mirrored: Bool) async -> CanonicalPose19? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return nil }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)

        do {
            try handler.perform([request])
            guard let observation = request.results?.first else { return nil }
            let recognizedPoints = try observation.recognizedPoints(.all)
            return Self.map(points: recognizedPoints, mirrored: mirrored)
        } catch {
            return nil
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

