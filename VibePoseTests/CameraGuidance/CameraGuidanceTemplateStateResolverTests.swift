import XCTest
@testable import VibePose

final class CameraGuidanceTemplateStateResolverTests: XCTestCase {
    func testInitialStateSelectsFirstTemplateAndBuildsRecommendations() {
        let resolver = CameraGuidanceTemplateStateResolver(recommendationService: RecommendationService())
        let first = makeTemplate(id: "first", difficulty: .medium, status: .released, offset: 0.0)
        let easy = makeTemplate(id: "easy", difficulty: .easy, status: .released, offset: 0.2)
        let draft = makeTemplate(id: "draft", difficulty: .easy, status: .draft, offset: 0.3)

        let state = resolver.makeInitialState(from: [first, easy, draft])

        XCTAssertEqual(state.templates.map(\.id), ["first", "easy", "draft"])
        XCTAssertEqual(state.selectedTemplate?.id, "first")
        XCTAssertEqual(state.recommendations.map(\.id), ["easy", "first"])
    }

    func testInitialStateHandlesEmptyTemplates() {
        let resolver = CameraGuidanceTemplateStateResolver(recommendationService: RecommendationService())

        let state = resolver.makeInitialState(from: [])

        XCTAssertTrue(state.templates.isEmpty)
        XCTAssertNil(state.selectedTemplate)
        XCTAssertTrue(state.recommendations.isEmpty)
    }

    func testSelectingTemplateImmediatelyRefreshesRecommendationsWithoutPose() {
        let resolver = CameraGuidanceTemplateStateResolver(recommendationService: RecommendationService())
        let hard = makeTemplate(id: "hard", difficulty: .hard, status: .released, offset: 0.0)
        let easy = makeTemplate(id: "easy", difficulty: .easy, status: .released, offset: 0.15)
        let medium = makeTemplate(id: "medium", difficulty: .medium, status: .released, offset: 0.3)

        let state = resolver.selecting(
            medium,
            templates: [hard, easy, medium],
            currentPose: nil
        )

        XCTAssertEqual(state.selectedTemplate?.id, "medium")
        XCTAssertEqual(state.recommendations.map(\.id), ["easy", "medium", "hard"])
    }

    func testSelectingTemplateUsesCurrentPoseForDistanceRanking() {
        let resolver = CameraGuidanceTemplateStateResolver(recommendationService: RecommendationService())
        let selected = makeTemplate(id: "selected", difficulty: .easy, status: .released, offset: 0.0)
        let close = makeTemplate(id: "close", difficulty: .hard, status: .released, offset: 0.03)
        let far = makeTemplate(id: "far", difficulty: .easy, status: .released, offset: 0.25)

        let state = resolver.selecting(
            selected,
            templates: [far, selected, close],
            currentPose: selected.pose
        )

        XCTAssertEqual(state.selectedTemplate?.id, "selected")
        XCTAssertEqual(state.recommendations.map(\.id), ["close", "far"])
    }

    func testImportingPoseSelectsClosestTemplateAndBuildsAlternatives() {
        let resolver = CameraGuidanceTemplateStateResolver(recommendationService: RecommendationService())
        let close = makeTemplate(id: "close", difficulty: .easy, status: .released, offset: 0.01)
        let medium = makeTemplate(id: "medium", difficulty: .medium, status: .released, offset: 0.12)
        let far = makeTemplate(id: "far", difficulty: .hard, status: .released, offset: 0.3)

        let state = resolver.importingPose(close.pose, templates: [far, medium, close])

        XCTAssertEqual(state.selectedTemplate?.id, "close")
        XCTAssertEqual(state.recommendations.map(\.id), ["medium", "far"])
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
