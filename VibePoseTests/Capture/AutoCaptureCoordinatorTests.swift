import XCTest
@testable import VibePose

final class AutoCaptureCoordinatorTests: XCTestCase {
    func testReturnsReadyWhenScoreIsAboveReadyThreshold() async {
        let coordinator = AutoCaptureCoordinator()
        let template = makeTemplate(ready: 0.72, perfect: 0.9, holdDuration: 1.5)

        let decision = await coordinator.evaluate(
            score: PoseScore(value: 0.8, matchedJoints: 19, coverage: 0.9),
            target: template,
            autoCaptureEnabled: true,
            timestamp: 0
        )

        XCTAssertEqual(decision, AutoCaptureDecision(state: .ready(0.8), shouldTriggerCapture: false))
    }

    func testEntersCountdownBeforeCaptureTrigger() async {
        let coordinator = AutoCaptureCoordinator()
        let template = makeTemplate(ready: 0.72, perfect: 0.9, holdDuration: 1.5)

        _ = await coordinator.evaluate(
            score: PoseScore(value: 0.95, matchedJoints: 19, coverage: 0.9),
            target: template,
            autoCaptureEnabled: true,
            timestamp: 10
        )

        let decision = await coordinator.evaluate(
            score: PoseScore(value: 0.95, matchedJoints: 19, coverage: 0.9),
            target: template,
            autoCaptureEnabled: true,
            timestamp: 12
        )

        XCTAssertEqual(decision, AutoCaptureDecision(state: .countdown(3), shouldTriggerCapture: false))
    }

    func testTriggersCaptureAfterHoldAndCountdownWindow() async {
        let coordinator = AutoCaptureCoordinator()
        let template = makeTemplate(ready: 0.72, perfect: 0.9, holdDuration: 1.5)

        _ = await coordinator.evaluate(
            score: PoseScore(value: 0.95, matchedJoints: 19, coverage: 0.9),
            target: template,
            autoCaptureEnabled: true,
            timestamp: 20
        )

        let decision = await coordinator.evaluate(
            score: PoseScore(value: 0.95, matchedJoints: 19, coverage: 0.9),
            target: template,
            autoCaptureEnabled: true,
            timestamp: 24.6
        )

        XCTAssertEqual(decision, AutoCaptureDecision(state: .countdown(1), shouldTriggerCapture: true))
    }

    func testResetAllowsNewCaptureCycle() async {
        let coordinator = AutoCaptureCoordinator()
        let template = makeTemplate(ready: 0.72, perfect: 0.9, holdDuration: 1.5)

        _ = await coordinator.evaluate(
            score: PoseScore(value: 0.95, matchedJoints: 19, coverage: 0.9),
            target: template,
            autoCaptureEnabled: true,
            timestamp: 40
        )
        _ = await coordinator.evaluate(
            score: PoseScore(value: 0.95, matchedJoints: 19, coverage: 0.9),
            target: template,
            autoCaptureEnabled: true,
            timestamp: 44.6
        )

        await coordinator.reset()

        let decision = await coordinator.evaluate(
            score: PoseScore(value: 0.95, matchedJoints: 19, coverage: 0.9),
            target: template,
            autoCaptureEnabled: true,
            timestamp: 44.7
        )

        XCTAssertEqual(decision, AutoCaptureDecision(state: .perfect(0.95), shouldTriggerCapture: false))
    }

    private func makeTemplate(ready: Double, perfect: Double, holdDuration: Double) -> PoseTemplate {
        let points = Dictionary(uniqueKeysWithValues: JointName.allCases.map { joint in
            (
                joint,
                PosePoint(
                    joint: joint,
                    x: 0.5,
                    y: 0.5,
                    confidence: 1
                )
            )
        })

        return PoseTemplate(
            templateId: "starter.\(UUID().uuidString)",
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
                points: points,
                coverage: 1,
                source: .syntheticTemplate,
                mirrorMode: .none
            ),
            matching: MatchingConfig(
                readyThreshold: ready,
                perfectThreshold: perfect,
                holdDuration: holdDuration,
                jointWeights: Dictionary(uniqueKeysWithValues: JointName.allCases.map { ($0, 1.0) })
            ),
            guide: GuideConfig(
                coachKey: "pose.guide.test.coach",
                photographerKey: "pose.guide.test.photographer",
                framingKey: "pose.guide.test.framing",
                preferredCamera: .back
            )
        )
    }
}
