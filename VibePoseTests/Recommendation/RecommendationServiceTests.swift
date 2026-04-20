import XCTest
@testable import VibePose

final class RecommendationServiceTests: XCTestCase {
    func testPrefersReleasedSinglePersonTemplatesAndOrdersByDifficultyWhenPoseMissing() {
        let service = RecommendationService()
        let hard = makeTemplate(id: "hard", difficulty: .hard, status: .released, subjectCount: 1, offset: 0.3)
        let easy = makeTemplate(id: "easy", difficulty: .easy, status: .released, subjectCount: 1, offset: 0.1)
        let multi = makeTemplate(id: "multi", difficulty: .easy, status: .released, subjectCount: 2, offset: 0.15)
        let draft = makeTemplate(id: "draft", difficulty: .easy, status: .draft, subjectCount: 1, offset: 0.2)
        let medium = makeTemplate(id: "medium", difficulty: .medium, status: .released, subjectCount: 1, offset: 0.25)

        let recommendations = service.recommend(
            currentPose: nil,
            selectedTemplate: hard,
            templates: [hard, easy, multi, draft, medium]
        )

        XCTAssertEqual(recommendations.map(\.id), ["easy", "medium", "hard"])
    }

    func testSortsByPoseDistanceAndExcludesSelectedTemplate() {
        let service = RecommendationService()
        let selected = makeTemplate(id: "selected", difficulty: .easy, status: .released, subjectCount: 1, offset: 0.0)
        let closest = makeTemplate(id: "closest", difficulty: .medium, status: .released, subjectCount: 1, offset: 0.02)
        let furthest = makeTemplate(id: "furthest", difficulty: .hard, status: .released, subjectCount: 1, offset: 0.2)

        let recommendations = service.recommend(
            currentPose: selected.pose,
            selectedTemplate: selected,
            templates: [furthest, selected, closest]
        )

        XCTAssertEqual(recommendations.map(\.id), ["closest", "furthest"])
    }

    func testReturnsEmptyWhenNoReleasedSinglePersonTemplatesExist() {
        let service = RecommendationService()
        let draft = makeTemplate(id: "draft", difficulty: .easy, status: .draft, subjectCount: 1, offset: 0.1)
        let multi = makeTemplate(id: "multi", difficulty: .medium, status: .released, subjectCount: 2, offset: 0.2)

        let recommendations = service.recommend(
            currentPose: nil,
            selectedTemplate: nil,
            templates: [draft, multi]
        )

        XCTAssertTrue(recommendations.isEmpty)
    }

    private func makeTemplate(
        id: String,
        difficulty: PoseDifficulty,
        status: TemplateStatus,
        subjectCount: Int,
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
            subjectCount: subjectCount,
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
