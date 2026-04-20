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
    @Published var captureResult: CaptureResult?

    let cameraController: CameraSessionController

    private let container: DependencyContainer
    private var captureInFlight = false

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
        let state = container.cameraGuidanceTemplateStateResolver.selecting(
            template,
            templates: templates,
            currentPose: detectedPose
        )
        applyTemplateState(state)
    }

    func toggleCamera() {
        cameraController.toggleCamera()
    }

    func captureManual() {
        Task {
            await captureStillPhoto(trigger: .manual)
        }
    }

    func dismissResult() {
        captureResult = nil
        autoCaptureState = .idle
        coachCopy = "coach.idle"
        Task {
            await container.autoCaptureCoordinator.reset()
        }
    }

    func saveCurrentResult() async -> Bool {
        guard let image = captureResult?.image else { return false }

        do {
            try await container.photoLibraryClient.save(image: image)
            return true
        } catch {
            return false
        }
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
            applyTemplateState(container.cameraGuidanceTemplateStateResolver.makeInitialState(from: loadedTemplates))
        } catch {
            applyTemplateState(container.cameraGuidanceTemplateStateResolver.makeInitialState(from: []))
        }
    }

    private func process(sampleBuffer: CMSampleBuffer) async {
        guard captureResult == nil else { return }

        let mirrored = cameraController.currentPosition == .front
        let pose = await container.visionPoseDetector.detectPose(in: sampleBuffer, mirrored: mirrored)
        detectedPose = pose

        let evaluation = await container.cameraGuidanceFramePipeline.evaluate(
            currentPose: pose,
            selectedTemplate: selectedTemplate,
            templates: templates,
            autoCaptureEnabled: featureFlags.autoCaptureEnabled,
            timestamp: ProcessInfo.processInfo.systemUptime
        )
        poseScore = evaluation.score
        recommendations = evaluation.recommendations
        autoCaptureState = evaluation.decision.state
        coachCopy = evaluation.coachCopy

        if evaluation.decision.shouldTriggerCapture {
            await captureStillPhoto(trigger: .automatic)
        }
    }

    private func captureStillPhoto(trigger: CaptureTrigger) async {
        guard !captureInFlight else { return }
        captureInFlight = true
        defer { captureInFlight = false }

        let stillImage = await cameraController.capturePhoto()
        let fallbackImage = stillImage == nil ? await cameraController.captureLatestFrame() : nil
        captureResult = CaptureResultFactory.makeResult(
            stillImage: stillImage,
            fallbackImage: fallbackImage,
            templateDisplayNameKey: selectedTemplate?.displayNameKey ?? "template.unknown",
            score: poseScore.value,
            trigger: trigger,
            capturedAt: .now
        )
        guard captureResult != nil else { return }
        await container.autoCaptureCoordinator.reset()
    }

    private func applyTemplateState(_ state: CameraGuidanceTemplateState) {
        templates = state.templates
        selectedTemplate = state.selectedTemplate
        recommendations = state.recommendations
    }
}
