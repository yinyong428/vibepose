import Foundation

struct CameraGuidanceFrameEvaluation {
    let score: PoseScore
    let recommendations: [PoseTemplate]
    let decision: AutoCaptureDecision
    let coachCopy: String
}

actor CameraGuidanceFramePipeline {
    private let scoringActor: ScoringActor
    private let recommendationService: RecommendationService
    private let autoCaptureCoordinator: AutoCaptureCoordinator

    init(
        scoringActor: ScoringActor,
        recommendationService: RecommendationService,
        autoCaptureCoordinator: AutoCaptureCoordinator
    ) {
        self.scoringActor = scoringActor
        self.recommendationService = recommendationService
        self.autoCaptureCoordinator = autoCaptureCoordinator
    }

    func evaluate(
        currentPose: CanonicalPose19?,
        selectedTemplate: PoseTemplate?,
        templates: [PoseTemplate],
        autoCaptureEnabled: Bool,
        timestamp: TimeInterval
    ) async -> CameraGuidanceFrameEvaluation {
        let score = await scoringActor.score(current: currentPose, target: selectedTemplate)
        let recommendations = recommendationService.recommend(
            currentPose: currentPose,
            selectedTemplate: selectedTemplate,
            templates: templates
        )
        let decision = await autoCaptureCoordinator.evaluate(
            score: score,
            target: selectedTemplate,
            autoCaptureEnabled: autoCaptureEnabled,
            timestamp: timestamp
        )

        return CameraGuidanceFrameEvaluation(
            score: score,
            recommendations: recommendations,
            decision: decision,
            coachCopy: AutoCaptureCoachCopyResolver.resolve(decision.state)
        )
    }
}
