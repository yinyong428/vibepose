import XCTest
@testable import VibePose

final class CameraGuidanceFramePipelineTests: XCTestCase {
    func testReturnsNoPersonDecisionAndRecommendationsWhenPoseMissing() async {
        let pipeline = makePipeline()
        let selected = makeTemplate(id: "selected", difficulty: .hard, status: .released, offset: 0.0)
        let easy = makeTemplate(id: "easy", difficulty: .easy, status: .released, offset: 0.15)
        let draft = makeTemplate(id: "draft", difficulty: .easy, status: .draft, offset: 0.3)

        let output = await pipeline.evaluate(
            currentPose: nil,
            subjectStatus: .noPerson,
            selectedTemplate: selected,
            templates: [selected, easy, draft],
            autoCaptureEnabled: true,
            timestamp: 0
        )

        XCTAssertEqual(output.score, PoseScore(value: 0, matchedJoints: 0, coverage: 0))
        XCTAssertEqual(output.decision, AutoCaptureDecision(state: .noPerson, shouldTriggerCapture: false))
        XCTAssertEqual(output.coachCopy, "coach.no_person")
        XCTAssertEqual(output.recommendations.map(\.id), ["easy", "selected"])
    }

    func testReturnsPerfectDecisionAndCoachCopyForMatchingPose() async {
        let pipeline = makePipeline()
        let selected = makeTemplate(id: "selected", difficulty: .easy, status: .released, offset: 0.0)
        let alternate = makeTemplate(id: "alternate", difficulty: .medium, status: .released, offset: 0.2)

        let output = await pipeline.evaluate(
            currentPose: selected.pose,
            subjectStatus: .clear,
            selectedTemplate: selected,
            templates: [selected, alternate],
            autoCaptureEnabled: false,
            timestamp: 10
        )

        XCTAssertEqual(output.score.value, 1, accuracy: 0.0001)
        XCTAssertEqual(output.score.matchedJoints, JointName.allCases.count)
        XCTAssertEqual(output.score.coverage, 1, accuracy: 0.0001)
        XCTAssertEqual(output.decision, AutoCaptureDecision(state: .perfect(1), shouldTriggerCapture: false))
        XCTAssertEqual(output.coachCopy, "coach.perfect")
        XCTAssertEqual(output.recommendations.map(\.id), ["alternate"])
    }

    func testMaintainsAutoCaptureStateAcrossSequentialEvaluations() async {
        let pipeline = makePipeline()
        let selected = makeTemplate(id: "selected", difficulty: .easy, status: .released, offset: 0.0)
        let alternate = makeTemplate(id: "alternate", difficulty: .medium, status: .released, offset: 0.25)

        _ = await pipeline.evaluate(
            currentPose: selected.pose,
            subjectStatus: .clear,
            selectedTemplate: selected,
            templates: [selected, alternate],
            autoCaptureEnabled: true,
            timestamp: 20
        )
        let countdown = await pipeline.evaluate(
            currentPose: selected.pose,
            subjectStatus: .clear,
            selectedTemplate: selected,
            templates: [selected, alternate],
            autoCaptureEnabled: true,
            timestamp: 22
        )
        let trigger = await pipeline.evaluate(
            currentPose: selected.pose,
            subjectStatus: .clear,
            selectedTemplate: selected,
            templates: [selected, alternate],
            autoCaptureEnabled: true,
            timestamp: 24.6
        )

        XCTAssertEqual(countdown.decision, AutoCaptureDecision(state: .countdown(3), shouldTriggerCapture: false))
        XCTAssertEqual(countdown.coachCopy, "coach.countdown_3")
        XCTAssertEqual(trigger.decision, AutoCaptureDecision(state: .countdown(1), shouldTriggerCapture: true))
        XCTAssertEqual(trigger.coachCopy, "coach.countdown_1")
    }

    func testReturnsMultiPersonUnsupportedWhenSceneContainsMultipleSubjects() async {
        let pipeline = makePipeline()
        let selected = makeTemplate(id: "selected", difficulty: .easy, status: .released, offset: 0.0)
        let alternate = makeTemplate(id: "alternate", difficulty: .medium, status: .released, offset: 0.2)

        let output = await pipeline.evaluate(
            currentPose: nil,
            subjectStatus: .multiPersonUnsupported,
            selectedTemplate: selected,
            templates: [selected, alternate],
            autoCaptureEnabled: true,
            timestamp: 0
        )

        XCTAssertEqual(output.score, PoseScore(value: 0, matchedJoints: 0, coverage: 0))
        XCTAssertEqual(output.decision, AutoCaptureDecision(state: .multiPersonUnsupported, shouldTriggerCapture: false))
        XCTAssertEqual(output.coachCopy, "coach.multi_person_unsupported")
        XCTAssertEqual(output.recommendations.map(\.id), ["selected", "alternate"])
    }

    private func makePipeline() -> CameraGuidanceFramePipeline {
        CameraGuidanceFramePipeline(
            scoringActor: ScoringActor(),
            recommendationService: RecommendationService(),
            autoCaptureCoordinator: AutoCaptureCoordinator()
        )
    }

    private func makeTemplate(
        id: String,
        difficulty: PoseDifficulty,
        status: TemplateStatus,
        offset: Double
    ) -> PoseTemplate {
        let points = Dictionary(uniqueKeysWithValues: JointName.allCases.enumerated().map { index, joint in
            let normalized = Double(index) / Double(JointName.allCases.count)
            return (
                joint,
                PosePoint(
                    joint: joint,
                    x: normalized + offset,
                    y: (1 - normalized) - offset,
                    confidence: 1
                )
            )
        })

        return PoseTemplate(
            templateId: id,
            version: "1.0.0",
            status: status,
            displayNameKey: "pose.template.\(id).title",
            subtitleKey: nil,
            sceneTags: ["studio"],
            styleTags: ["editorial"],
            effectTags: [],
            framing: .fullBody,
            subjectCount: 1,
            difficulty: difficulty,
            cameraFacing: [.front, .back],
            mirrorPolicy: .autoByCamera,
            pose: CanonicalPose19(
                points: points,
                coverage: 1,
                source: .syntheticTemplate,
                mirrorMode: .none
            ),
            matching: MatchingConfig(
                readyThreshold: 0.72,
                perfectThreshold: 0.9,
                holdDuration: 1.5,
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
