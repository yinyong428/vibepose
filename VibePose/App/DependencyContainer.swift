import Foundation

@MainActor
final class DependencyContainer: ObservableObject {
    let templateRepository = TemplateRepository()
    let scoringActor = ScoringActor()
    let recommendationService = RecommendationService()
    let autoCaptureCoordinator = AutoCaptureCoordinator()
    let cameraGuidanceFramePipeline: CameraGuidanceFramePipeline
    let motionService = MotionService()
    let photoLibraryClient = PhotoLibraryClient()
    let cameraSessionController = CameraSessionController()
    let visionPoseDetector = VisionPoseDetector()

    init() {
        cameraGuidanceFramePipeline = CameraGuidanceFramePipeline(
            scoringActor: scoringActor,
            recommendationService: recommendationService,
            autoCaptureCoordinator: autoCaptureCoordinator
        )
    }
}
