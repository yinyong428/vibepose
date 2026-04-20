import Foundation

struct CameraGuidanceFrameEvaluation {
    let score: PoseScore
    let recommendations: [PoseTemplate]
    let decision: AutoCaptureDecision
    let coachCopy: String
}

actor CameraGuidanceFramePipeline {
    private let lowLightThreshold = -1.0
    private let minimumSubjectCoverage = 0.45
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
        environmentBrightness: Double? = nil,
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

        if let environmentBrightness, environmentBrightness < lowLightThreshold {
            await autoCaptureCoordinator.reset()
            let decision = AutoCaptureDecision(state: .lowLight, shouldTriggerCapture: false)
            return CameraGuidanceFrameEvaluation(
                score: PoseScore(value: 0, matchedJoints: 0, coverage: currentPose?.coverage ?? 0),
                recommendations: recommendationService.recommend(
                    currentPose: nil,
                    selectedTemplate: selectedTemplate,
                    templates: templates
                ),
                decision: decision,
                coachCopy: AutoCaptureCoachCopyResolver.resolve(decision.state)
            )
        }

        if let currentPose, currentPose.coverage < minimumSubjectCoverage {
            await autoCaptureCoordinator.reset()
            let decision = AutoCaptureDecision(state: .partialSubject, shouldTriggerCapture: false)
            return CameraGuidanceFrameEvaluation(
                score: PoseScore(value: 0, matchedJoints: 0, coverage: currentPose.coverage),
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
