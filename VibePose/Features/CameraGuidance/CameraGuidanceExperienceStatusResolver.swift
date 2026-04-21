import Foundation

enum CameraGuidanceExperienceTone: Equatable {
    case info
    case warning
}

enum CameraGuidanceExperienceAction: Equatable {
    case openSettings
}

enum CameraGuidanceStageTone: Equatable {
    case neutral
    case progress
    case primed
    case success
    case warning
}

enum CameraGuidanceImportState: Equatable {
    case idle
    case importing
    case failed
}

struct CameraGuidanceExperienceStatus: Equatable {
    let symbolName: String
    let titleKey: String
    let messageKey: String
    let tone: CameraGuidanceExperienceTone
    let action: CameraGuidanceExperienceAction?
    let actionKey: String?
}

struct CameraGuidanceStagePresentation: Equatable {
    let titleKey: String
    let progress: Double
    let tone: CameraGuidanceStageTone
    let emphasisText: String?
    let emphasisCaptionKey: String?
}

enum CameraGuidanceExperienceStatusResolver {
    static func stagePresentation(
        autoCaptureState: AutoCaptureState,
        score: PoseScore
    ) -> CameraGuidanceStagePresentation {
        switch autoCaptureState {
        case .idle:
            return CameraGuidanceStagePresentation(
                titleKey: "camera.stage.idle_title",
                progress: 0.08,
                tone: .neutral,
                emphasisText: nil,
                emphasisCaptionKey: nil
            )
        case .stabilizing:
            return CameraGuidanceStagePresentation(
                titleKey: "camera.stabilizing_title",
                progress: 0.15,
                tone: .neutral,
                emphasisText: nil,
                emphasisCaptionKey: nil
            )
        case .lowLight:
            return CameraGuidanceStagePresentation(
                titleKey: "camera.low_light_title",
                progress: 0.08,
                tone: .warning,
                emphasisText: nil,
                emphasisCaptionKey: nil
            )
        case .noPerson:
            return CameraGuidanceStagePresentation(
                titleKey: "camera.no_person_title",
                progress: 0.08,
                tone: .warning,
                emphasisText: nil,
                emphasisCaptionKey: nil
            )
        case .partialSubject:
            return CameraGuidanceStagePresentation(
                titleKey: "camera.partial_subject_title",
                progress: 0.08,
                tone: .warning,
                emphasisText: nil,
                emphasisCaptionKey: nil
            )
        case .multiPersonUnsupported:
            return CameraGuidanceStagePresentation(
                titleKey: "camera.multi_person_title",
                progress: 0.08,
                tone: .warning,
                emphasisText: nil,
                emphasisCaptionKey: nil
            )
        case .aligning(let value):
            return CameraGuidanceStagePresentation(
                titleKey: "camera.stage.aligning_title",
                progress: normalizedProgress(value),
                tone: .progress,
                emphasisText: scoreText(for: value),
                emphasisCaptionKey: "camera.stage.match_label"
            )
        case .ready(let value):
            return CameraGuidanceStagePresentation(
                titleKey: "camera.stage.ready_title",
                progress: normalizedProgress(value),
                tone: .primed,
                emphasisText: scoreText(for: value),
                emphasisCaptionKey: "camera.stage.match_label"
            )
        case .perfect(let value):
            return CameraGuidanceStagePresentation(
                titleKey: "camera.stage.perfect_title",
                progress: normalizedProgress(value),
                tone: .success,
                emphasisText: scoreText(for: value),
                emphasisCaptionKey: "camera.stage.match_label"
            )
        case .countdown(let seconds):
            return CameraGuidanceStagePresentation(
                titleKey: "camera.stage.countdown_title",
                progress: 1.0,
                tone: .success,
                emphasisText: "\(seconds)",
                emphasisCaptionKey: "camera.stage.seconds_label"
            )
        }
    }

    static func resolve(
        cameraAuthorized: Bool,
        templates: [PoseTemplate],
        selectedTemplate: PoseTemplate?,
        autoCaptureState: AutoCaptureState,
        importState: CameraGuidanceImportState = .idle
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

        if importState == .failed {
            return CameraGuidanceExperienceStatus(
                symbolName: "photo.badge.exclamationmark",
                titleKey: "camera.import_failed_title",
                messageKey: "camera.import_failed_message",
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

        if autoCaptureState == .stabilizing {
            return CameraGuidanceExperienceStatus(
                symbolName: "camera.aperture",
                titleKey: "camera.stabilizing_title",
                messageKey: "camera.stabilizing_message",
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

        if autoCaptureState == .lowLight {
            return CameraGuidanceExperienceStatus(
                symbolName: "moon.haze.fill",
                titleKey: "camera.low_light_title",
                messageKey: "camera.low_light_message",
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

    private static func normalizedProgress(_ value: Double) -> Double {
        min(max(value, 0.08), 1.0)
    }

    private static func scoreText(for value: Double) -> String {
        "\(Int((min(max(value, 0), 1)) * 100))"
    }
}
