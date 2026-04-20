import XCTest
@testable import VibePose

final class ScoringActorTests: XCTestCase {
    func testReturnsPerfectScoreForIdenticalPose() async {
        let actor = ScoringActor()
        let template = makeTemplate(
            targetPoints: makePoints(),
            weights: Dictionary(uniqueKeysWithValues: JointName.allCases.map { ($0, 1.0) }),
            targetCoverage: 0.95
        )
        let currentPose = CanonicalPose19(
            points: makePoints(),
            coverage: 0.9,
            source: .vision,
            mirrorMode: .none
        )

        let score = await actor.score(current: currentPose, target: template)

        XCTAssertEqual(score.value, 1.0, accuracy: 0.0001)
        XCTAssertEqual(score.matchedJoints, JointName.allCases.count)
        XCTAssertEqual(score.coverage, 0.9, accuracy: 0.0001)
    }

    func testWeightedDistancePenalizesHighPriorityJoint() async {
        let actor = ScoringActor()
        var targetPoints = makePoints()
        let weights = Dictionary(uniqueKeysWithValues: JointName.allCases.map { joint in
            (joint, joint == .leftWrist ? 5.0 : 1.0)
        })
        let template = makeTemplate(
            targetPoints: targetPoints,
            weights: weights,
            targetCoverage: 1
        )

        targetPoints[.leftWrist] = PosePoint(joint: .leftWrist, x: 0.8, y: 0.5, confidence: 1)
        let currentPose = CanonicalPose19(
            points: targetPoints,
            coverage: 1,
            source: .vision,
            mirrorMode: .none
        )

        let score = await actor.score(current: currentPose, target: template)

        XCTAssertEqual(score.matchedJoints, JointName.allCases.count)
        XCTAssertEqual(score.coverage, 1, accuracy: 0.0001)
        XCTAssertLessThan(score.value, 0.81)
        XCTAssertGreaterThan(score.value, 0.75)
    }

    func testSkipsMissingJointsAndClampsCoverageToLowerPose() async {
        let actor = ScoringActor()
        let targetPoints = makePoints()
        let template = makeTemplate(
            targetPoints: targetPoints,
            weights: Dictionary(uniqueKeysWithValues: JointName.allCases.map { ($0, 1.0) }),
            targetCoverage: 0.8
        )

        var partialPoints = targetPoints
        partialPoints.removeValue(forKey: .leftEar)
        partialPoints.removeValue(forKey: .rightEar)
        let currentPose = CanonicalPose19(
            points: partialPoints,
            coverage: 0.95,
            source: .vision,
            mirrorMode: .none
        )

        let score = await actor.score(current: currentPose, target: template)

        XCTAssertEqual(score.matchedJoints, JointName.allCases.count - 2)
        XCTAssertEqual(score.coverage, 0.8, accuracy: 0.0001)
        XCTAssertEqual(score.value, 1.0, accuracy: 0.0001)
    }

    private func makeTemplate(
        targetPoints: [JointName: PosePoint],
        weights: [JointName: Double],
        targetCoverage: Double
    ) -> PoseTemplate {
        PoseTemplate(
            templateId: "score.\(UUID().uuidString)",
            version: "1.0.0",
            status: .qaReady,
            displayNameKey: "pose.template.test.title",
            subtitleKey: nil,
            sceneTags: ["studio"],
            styleTags: ["editorial"],
            effectTags: [],
            framing: .fullBody,
            subjectCount: 1,
            difficulty: .easy,
            cameraFacing: [.front, .back],
            mirrorPolicy: .autoByCamera,
            pose: CanonicalPose19(
                points: targetPoints,
                coverage: targetCoverage,
                source: .syntheticTemplate,
                mirrorMode: .none
            ),
            matching: MatchingConfig(
                readyThreshold: 0.7,
                perfectThreshold: 0.9,
                holdDuration: 1.5,
                jointWeights: weights
            ),
            guide: GuideConfig(
                coachKey: "pose.guide.test.coach",
                photographerKey: "pose.guide.test.photographer",
                framingKey: "pose.guide.test.framing",
                preferredCamera: .back
            )
        )
    }

    private func makePoints() -> [JointName: PosePoint] {
        Dictionary(uniqueKeysWithValues: JointName.allCases.enumerated().map { index, joint in
            let normalized = Double(index) / Double(JointName.allCases.count)
            return (
                joint,
                PosePoint(
                    joint: joint,
                    x: normalized,
                    y: 1 - normalized,
                    confidence: 1
                )
            )
        })
    }
}
