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
        subjectStatus: CameraGuidanceSubjectStatus,
        selectedTemplate: PoseTemplate?,
        templates: [PoseTemplate],
        autoCaptureEnabled: Bool,
        timestamp: TimeInterval
    ) async -> CameraGuidanceFrameEvaluation {
        if subjectStatus == .multiPersonUnsupported {
            await autoCaptureCoordinator.reset()
            let decision = AutoCaptureDecision(state: .multiPersonUnsupported, shouldTriggerCapture: false)
            return CameraGuidanceFrameEvaluation(
                score: PoseScore(value: 0, matchedJoints: 0, coverage: 0),
                recommendations: recommendationService.recommend(
                    currentPose: nil,
                    selectedTemplate: selectedTemplate,
                    templates: templates
                ),
                decision: decision,
                coachCopy: AutoCaptureCoachCopyResolver.resolve(decision.state)
            )
        }

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
