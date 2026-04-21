import XCTest
@testable import VibePose

final class CameraGuidanceExperienceStatusResolverTests: XCTestCase {
    func testReturnsPermissionStatusWhenCameraUnauthorized() {
        let status = CameraGuidanceExperienceStatusResolver.resolve(
            cameraAuthorized: false,
            templates: [makeTemplate(id: "selected")],
            selectedTemplate: makeTemplate(id: "selected"),
            autoCaptureState: .idle
        )

        XCTAssertEqual(
            status,
            CameraGuidanceExperienceStatus(
                symbolName: "camera.fill",
                titleKey: "camera.permission_needed",
                messageKey: "camera.permission_hint",
                tone: .warning,
                action: .openSettings,
                actionKey: "camera.permission_open_settings"
            )
        )
    }

    func testReturnsTemplateMissingStatusWhenStarterPackIsEmpty() {
        let status = CameraGuidanceExperienceStatusResolver.resolve(
            cameraAuthorized: true,
            templates: [],
            selectedTemplate: nil,
            autoCaptureState: .idle
        )

        XCTAssertEqual(
            status,
            CameraGuidanceExperienceStatus(
                symbolName: "square.stack.3d.up.slash",
                titleKey: "camera.template_missing_title",
                messageKey: "camera.template_missing_message",
                tone: .warning,
                action: nil,
                actionKey: nil
            )
        )
    }

    func testReturnsSelectTemplateStatusWhenNoTemplateChosen() {
        let templates = [makeTemplate(id: "first")]

        let status = CameraGuidanceExperienceStatusResolver.resolve(
            cameraAuthorized: true,
            templates: templates,
            selectedTemplate: nil,
            autoCaptureState: .idle
        )

        XCTAssertEqual(
            status,
            CameraGuidanceExperienceStatus(
                symbolName: "figure.stand",
                titleKey: "camera.select_template_title",
                messageKey: "camera.select_template_message",
                tone: .info,
                action: nil,
                actionKey: nil
            )
        )
    }

    func testReturnsStabilizingStatusWhenPreviewIsWarmingUp() {
        let selected = makeTemplate(id: "selected")

        let status = CameraGuidanceExperienceStatusResolver.resolve(
            cameraAuthorized: true,
            templates: [selected],
            selectedTemplate: selected,
            autoCaptureState: .stabilizing
        )

        XCTAssertEqual(
            status,
            CameraGuidanceExperienceStatus(
                symbolName: "camera.aperture",
                titleKey: "camera.stabilizing_title",
                messageKey: "camera.stabilizing_message",
                tone: .info,
                action: nil,
                actionKey: nil
            )
        )
    }

    func testReturnsNoPersonStatusWhenSubjectLeavesFrame() {
        let selected = makeTemplate(id: "selected")

        let status = CameraGuidanceExperienceStatusResolver.resolve(
            cameraAuthorized: true,
            templates: [selected],
            selectedTemplate: selected,
            autoCaptureState: .noPerson
        )

        XCTAssertEqual(
            status,
            CameraGuidanceExperienceStatus(
                symbolName: "person.crop.rectangle.badge.xmark",
                titleKey: "camera.no_person_title",
                messageKey: "camera.no_person_message",
                tone: .info,
                action: nil,
                actionKey: nil
            )
        )
    }

    func testReturnsLowLightStatusWhenPreviewIsTooDark() {
        let selected = makeTemplate(id: "selected")

        let status = CameraGuidanceExperienceStatusResolver.resolve(
            cameraAuthorized: true,
            templates: [selected],
            selectedTemplate: selected,
            autoCaptureState: .lowLight
        )

        XCTAssertEqual(
            status,
            CameraGuidanceExperienceStatus(
                symbolName: "moon.haze.fill",
                titleKey: "camera.low_light_title",
                messageKey: "camera.low_light_message",
                tone: .warning,
                action: nil,
                actionKey: nil
            )
        )
    }

    func testReturnsMultiPersonUnsupportedStatusWhenSeveralSubjectsDetected() {
        let selected = makeTemplate(id: "selected")

        let status = CameraGuidanceExperienceStatusResolver.resolve(
            cameraAuthorized: true,
            templates: [selected],
            selectedTemplate: selected,
            autoCaptureState: .multiPersonUnsupported
        )

        XCTAssertEqual(
            status,
            CameraGuidanceExperienceStatus(
                symbolName: "person.2.crop.square.stack",
                titleKey: "camera.multi_person_title",
                messageKey: "camera.multi_person_message",
                tone: .warning,
                action: nil,
                actionKey: nil
            )
        )
    }

    func testReturnsPartialSubjectStatusWhenBodyCoverageIsTooLow() {
        let selected = makeTemplate(id: "selected")

        let status = CameraGuidanceExperienceStatusResolver.resolve(
            cameraAuthorized: true,
            templates: [selected],
            selectedTemplate: selected,
            autoCaptureState: .partialSubject
        )

        XCTAssertEqual(
            status,
            CameraGuidanceExperienceStatus(
                symbolName: "figure.stand.line.dotted.figure.stand",
                titleKey: "camera.partial_subject_title",
                messageKey: "camera.partial_subject_message",
                tone: .warning,
                action: nil,
                actionKey: nil
            )
        )
    }

    func testReturnsNilDuringHealthyActiveStates() {
        let selected = makeTemplate(id: "selected")

        let status = CameraGuidanceExperienceStatusResolver.resolve(
            cameraAuthorized: true,
            templates: [selected],
            selectedTemplate: selected,
            autoCaptureState: .ready(0.82)
        )

        XCTAssertNil(status)
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
}
