import Foundation

struct CameraGuidanceTemplateState {
    let templates: [PoseTemplate]
    let selectedTemplate: PoseTemplate?
    let recommendations: [PoseTemplate]
}

struct CameraGuidanceTemplateStateResolver {
    private let recommendationService: RecommendationService

    init(recommendationService: RecommendationService) {
        self.recommendationService = recommendationService
    }

    func makeInitialState(from templates: [PoseTemplate]) -> CameraGuidanceTemplateState {
        let selectedTemplate = templates.first
        return makeState(
            templates: templates,
            selectedTemplate: selectedTemplate,
            currentPose: nil
        )
    }

    func selecting(
        _ template: PoseTemplate,
        templates: [PoseTemplate],
        currentPose: CanonicalPose19?
    ) -> CameraGuidanceTemplateState {
        makeState(
            templates: templates,
            selectedTemplate: template,
            currentPose: currentPose
        )
    }

    func importingPose(
        _ importedPose: CanonicalPose19,
        templates: [PoseTemplate]
    ) -> CameraGuidanceTemplateState {
        let selectedTemplate = recommendationService.recommend(
            currentPose: importedPose,
            selectedTemplate: nil,
            templates: templates,
            limit: 1
        ).first ?? templates.first

        return makeState(
            templates: templates,
            selectedTemplate: selectedTemplate,
            currentPose: importedPose
        )
    }

    private func makeState(
        templates: [PoseTemplate],
        selectedTemplate: PoseTemplate?,
        currentPose: CanonicalPose19?
    ) -> CameraGuidanceTemplateState {
        CameraGuidanceTemplateState(
            templates: templates,
            selectedTemplate: selectedTemplate,
            recommendations: recommendationService.recommend(
                currentPose: currentPose,
                selectedTemplate: selectedTemplate,
                templates: templates
            )
        )
    }
}
