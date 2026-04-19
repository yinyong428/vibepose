import CoreMedia
import Foundation

@MainActor
final class CameraGuidanceViewModel: ObservableObject {
    @Published var featureFlags = FeatureFlags()
    @Published var templates: [PoseTemplate] = []
    @Published var selectedTemplate: PoseTemplate?
    @Published var recommendations: [PoseTemplate] = []
    @Published var detectedPose: CanonicalPose19?
    @Published var poseScore = PoseScore(value: 0, matchedJoints: 0, coverage: 0)
    @Published var autoCaptureState: AutoCaptureState = .idle
    @Published var coachCopy = "coach.idle"
    @Published var pitchText = "0.00"
    @Published var cameraAuthorized = false
    @Published var showsSettings = false
    @Published var showsResult = false

    let cameraController: CameraSessionController

    private let container: DependencyContainer

    init(container: DependencyContainer) {
        self.container = container
        self.cameraController = container.cameraSessionController
        bindCameraFrames()
        loadTemplates()
    }

    func onAppear() {
        Task {
            cameraAuthorized = await cameraController.requestAccess()
            guard cameraAuthorized else { return }
            cameraController.configureSession()
            cameraController.startRunning()
            container.motionService.start { [weak self] pitch in
                self?.pitchText = String(format: "%.2f rad", pitch)
            }
        }
    }

    func onDisappear() {
        cameraController.stopRunning()
        container.motionService.stop()
    }

    func selectTemplate(_ template: PoseTemplate) {
        selectedTemplate = template
    }

    func toggleCamera() {
        cameraController.toggleCamera()
    }

    func captureManual() {
        showsResult = true
    }

    private func bindCameraFrames() {
        cameraController.onSampleBuffer = { [weak self] sampleBuffer in
            Task { @MainActor [weak self] in
                await self?.process(sampleBuffer: sampleBuffer)
            }
        }
    }

    private func loadTemplates() {
        do {
            let loadedTemplates = try container.templateRepository.loadStarterPack()
            templates = loadedTemplates
            selectedTemplate = loadedTemplates.first
            recommendations = container.recommendationService.recommend(
                currentPose: nil,
                selectedTemplate: selectedTemplate,
                templates: loadedTemplates
            )
        } catch {
            templates = []
            recommendations = []
        }
    }

    private func process(sampleBuffer: CMSampleBuffer) async {
        let mirrored = cameraController.currentPosition == .front
        let pose = await container.visionPoseDetector.detectPose(in: sampleBuffer, mirrored: mirrored)
        detectedPose = pose

        let score = await container.scoringActor.score(current: pose, target: selectedTemplate)
        poseScore = score

        recommendations = container.recommendationService.recommend(
            currentPose: pose,
            selectedTemplate: selectedTemplate,
            templates: templates
        )

        autoCaptureState = await container.autoCaptureCoordinator.evaluate(
            score: score,
            target: selectedTemplate,
            autoCaptureEnabled: featureFlags.autoCaptureEnabled,
            timestamp: ProcessInfo.processInfo.systemUptime
        )
        coachCopy = coachKey(for: autoCaptureState)
    }

    private func coachKey(for state: AutoCaptureState) -> String {
        switch state {
        case .idle:
            return "coach.idle"
        case .noPerson:
            return "coach.no_person"
        case .aligning:
            return "coach.aligning"
        case .ready:
            return "coach.ready"
        case .perfect:
            return "coach.perfect"
        case .countdown(let seconds):
            return "coach.countdown_\(seconds)"
        }
    }
}
