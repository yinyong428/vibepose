import Foundation

enum CameraGuidanceExperienceTone: Equatable {
    case info
    case warning
}

enum CameraGuidanceExperienceAction: Equatable {
    case openSettings
}

struct CameraGuidanceExperienceStatus: Equatable {
    let symbolName: String
    let titleKey: String
    let messageKey: String
    let tone: CameraGuidanceExperienceTone
    let action: CameraGuidanceExperienceAction?
    let actionKey: String?
}

enum CameraGuidanceExperienceStatusResolver {
    static func resolve(
        cameraAuthorized: Bool,
        templates: [PoseTemplate],
        selectedTemplate: PoseTemplate?,
        autoCaptureState: AutoCaptureState
    ) -> CameraGuidanceExperienceStatus? {
        if !cameraAuthorized {
            return CameraGuidanceExperienceStatus(
                symbolName: "camera.fill",
                titleKey: "camera.permission_needed",
                messageKey: "camera.permission_hint",
                tone: .warning,
                action: .openSettings,
                actionKey: "camera.permission_open_settings"
            )
        }

        guard !templates.isEmpty else {
            return CameraGuidanceExperienceStatus(
                symbolName: "square.stack.3d.up.slash",
                titleKey: "camera.template_missing_title",
                messageKey: "camera.template_missing_message",
                tone: .warning,
                action: nil,
                actionKey: nil
            )
        }

        guard selectedTemplate != nil else {
            return CameraGuidanceExperienceStatus(
                symbolName: "figure.stand",
                titleKey: "camera.select_template_title",
                messageKey: "camera.select_template_message",
                tone: .info,
                action: nil,
                actionKey: nil
            )
        }

        if autoCaptureState == .multiPersonUnsupported {
            return CameraGuidanceExperienceStatus(
                symbolName: "person.2.crop.square.stack",
                titleKey: "camera.multi_person_title",
                messageKey: "camera.multi_person_message",
                tone: .warning,
                action: nil,
                actionKey: nil
            )
        }

        if autoCaptureState == .partialSubject {
            return CameraGuidanceExperienceStatus(
                symbolName: "figure.stand.line.dotted.figure.stand",
                titleKey: "camera.partial_subject_title",
                messageKey: "camera.partial_subject_message",
                tone: .warning,
                action: nil,
                actionKey: nil
            )
        }

        guard autoCaptureState == .noPerson else {
            return nil
        }

        return CameraGuidanceExperienceStatus(
            symbolName: "person.crop.rectangle.badge.xmark",
            titleKey: "camera.no_person_title",
            messageKey: "camera.no_person_message",
            tone: .info,
            action: nil,
            actionKey: nil
        )
    }
}
