import XCTest
import UIKit
@testable import VibePose

final class CameraGuidanceCaptureCoordinatorTests: XCTestCase {
    func testCompleteCapturePrefersStillPhotoAndResetsAutoCapture() throws {
        let coordinator = CameraGuidanceCaptureCoordinator()
        let template = makeTemplate(id: "selected")
        let stillImage = makeImage(color: .red)
        let fallbackImage = makeImage(color: .blue)

        let completion = coordinator.completeCapture(
            stillImage: stillImage,
            fallbackImage: fallbackImage,
            selectedTemplate: template,
            score: 0.96,
            trigger: .automatic,
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let result = try XCTUnwrap(completion.result)
        XCTAssertTrue(completion.shouldResetAutoCapture)
        XCTAssertNil(completion.failureTitleKey)
        XCTAssertNil(completion.failureMessageKey)
        XCTAssertEqual(result.representation, .stillPhoto)
        XCTAssertEqual(result.trigger, .automatic)
        XCTAssertEqual(result.templateDisplayNameKey, template.displayNameKey)
        XCTAssertEqual(result.image.pngData(), stillImage.pngData())
    }

    func testCompleteCaptureFallsBackToUnknownTemplateAndStillResetsWhenImagesMissing() {
        let coordinator = CameraGuidanceCaptureCoordinator()

        let completion = coordinator.completeCapture(
            stillImage: nil,
            fallbackImage: nil,
            selectedTemplate: nil,
            score: 0.5,
            trigger: .manual,
            capturedAt: Date(timeIntervalSince1970: 200)
        )

        XCTAssertNil(completion.result)
        XCTAssertTrue(completion.shouldResetAutoCapture)
        XCTAssertEqual(completion.failureTitleKey, "camera.capture_failed_title")
        XCTAssertEqual(completion.failureMessageKey, "camera.capture_failed_message")
    }

    func testDismissalStateReturnsIdlePresentation() {
        let coordinator = CameraGuidanceCaptureCoordinator()

        let dismissal = coordinator.makeDismissalState()

        XCTAssertNil(dismissal.captureResult)
        XCTAssertEqual(dismissal.autoCaptureState, .idle)
        XCTAssertEqual(dismissal.coachCopy, "coach.idle")
    }

    private func makeTemplate(id: String) -> PoseTemplate {
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
            templateId: id,
            version: "1.0.0",
            status: .released,
            displayNameKey: "pose.template.\(id).title",
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

    private func makeImage(color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }
}
