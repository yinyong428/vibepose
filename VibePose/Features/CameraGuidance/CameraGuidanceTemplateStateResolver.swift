import Foundation

struct CameraGuidanceImportMatch: Equatable {
    let templateID: String
    let templateDisplayNameKey: String
    let alternativesCount: Int
}

struct CameraGuidanceTemplateState {
    let templates: [PoseTemplate]
    let selectedTemplate: PoseTemplate?
    let recommendations: [PoseTemplate]
    let importMatch: CameraGuidanceImportMatch?
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

        let recommendations = recommendationService.recommend(
            currentPose: importedPose,
            selectedTemplate: selectedTemplate,
            templates: templates
        )

        let importMatch = selectedTemplate.map {
            CameraGuidanceImportMatch(
                templateID: $0.id,
                templateDisplayNameKey: $0.displayNameKey,
                alternativesCount: recommendations.count
            )
        }

        return CameraGuidanceTemplateState(
            templates: templates,
            selectedTemplate: selectedTemplate,
            recommendations: recommendations,
            importMatch: importMatch
        )
    }

    private func makeState(
        templates: [PoseTemplate],
        selectedTemplate: PoseTemplate?,
        currentPose: CanonicalPose19?,
        importMatch: CameraGuidanceImportMatch? = nil
    ) -> CameraGuidanceTemplateState {
        CameraGuidanceTemplateState(
            templates: templates,
            selectedTemplate: selectedTemplate,
            recommendations: recommendationService.recommend(
                currentPose: currentPose,
                selectedTemplate: selectedTemplate,
                templates: templates
            ),
            importMatch: importMatch
        )
    }
}
