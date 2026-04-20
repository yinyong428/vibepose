import Foundation

enum CameraGuidanceExperienceTone: Equatable {
    case info
    case warning
}

struct CameraGuidanceExperienceStatus: Equatable {
    let symbolName: String
    let titleKey: String
    let messageKey: String
    let tone: CameraGuidanceExperienceTone
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
                tone: .warning
            )
        }

        guard !templates.isEmpty else {
            return CameraGuidanceExperienceStatus(
                symbolName: "square.stack.3d.up.slash",
                titleKey: "camera.template_missing_title",
                messageKey: "camera.template_missing_message",
                tone: .warning
            )
        }

        guard selectedTemplate != nil else {
            return CameraGuidanceExperienceStatus(
                symbolName: "figure.stand",
                titleKey: "camera.select_template_title",
                messageKey: "camera.select_template_message",
                tone: .info
            )
        }

        if autoCaptureState == .multiPersonUnsupported {
            return CameraGuidanceExperienceStatus(
                symbolName: "person.2.crop.square.stack",
                titleKey: "camera.multi_person_title",
                messageKey: "camera.multi_person_message",
                tone: .warning
            )
        }

        guard autoCaptureState == .noPerson else {
            return nil
        }

        return CameraGuidanceExperienceStatus(
            symbolName: "person.crop.rectangle.badge.xmark",
            titleKey: "camera.no_person_title",
            messageKey: "camera.no_person_message",
            tone: .info
        )
    }
}
