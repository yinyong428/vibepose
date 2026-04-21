import CoreMedia
import Foundation
import ImageIO

struct CameraGuidanceAlert: Identifiable, Equatable {
    let titleKey: String
    let messageKey: String

    var id: String { "\(titleKey)|\(messageKey)" }
}

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
    @Published var alert: CameraGuidanceAlert?
    @Published var sceneBrightness: Double?
    @Published var importState: CameraGuidanceImportState = .idle
    @Published var importMatch: CameraGuidanceImportMatch?

    let cameraController: CameraSessionController

    private let container: DependencyContainer
    private var captureInFlight = false
    private let previewWarmupDuration: TimeInterval = 1.0
    private var previewStableAfter: TimeInterval?

    init(container: DependencyContainer) {
        self.container = container
        self.cameraController = container.cameraSessionController
        bindCameraFrames()
        loadTemplates()
    }

    func onAppear() {
        Task {
            cameraAuthorized = await container.cameraGuidanceLifecycleCoordinator.start { [weak self] formattedPitch in
                self?.pitchText = formattedPitch
            }
            if cameraAuthorized {
                markPreviewWarmup()
            }
        }
    }

    func onDisappear() {
        container.cameraGuidanceLifecycleCoordinator.stop()
    }

    func selectTemplate(_ template: PoseTemplate) {
        importState = .idle
        let state = container.cameraGuidanceTemplateStateResolver.selecting(
            template,
            templates: templates,
            currentPose: detectedPose
        )
        applyTemplateState(state)
    }

    func toggleCamera() {
        cameraController.toggleCamera()
        markPreviewWarmup()
    }

    func captureManual() {
        Task {
            await captureStillPhoto(trigger: .manual)
        }
    }

    func importPoseImage(data: Data) async {
        guard featureFlags.copyPoseEnabled else { return }
        importState = .importing
        importMatch = nil

        let detection = await container.visionPoseDetector.detectPose(in: data, mirrored: false)
        guard detection.subjectStatus == .clear, let pose = detection.pose else {
            importState = .failed
            return
        }

        importState = .idle
        applyTemplateState(
            container.cameraGuidanceTemplateStateResolver.importingPose(
                pose,
                templates: templates
            )
        )
    }

    func dismissResult() {
        let dismissal = container.cameraGuidanceCaptureCoordinator.makeDismissalState()
        captureResult = dismissal.captureResult
        autoCaptureState = dismissal.autoCaptureState
        coachCopy = dismissal.coachCopy
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

        sceneBrightness = Self.extractBrightness(from: sampleBuffer)
        let mirrored = cameraController.currentPosition == .front
        let detection = await container.visionPoseDetector.detectPose(in: sampleBuffer, mirrored: mirrored)
        detectedPose = detection.pose

        let evaluation = await container.cameraGuidanceFramePipeline.evaluate(
            currentPose: detection.pose,
            subjectStatus: detection.subjectStatus,
            environmentBrightness: sceneBrightness,
            isPreviewStable: isPreviewStable(at: ProcessInfo.processInfo.systemUptime),
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
        alert = nil
        captureInFlight = true
        defer { captureInFlight = false }

        let stillImage = await cameraController.capturePhoto()
        let fallbackImage = stillImage == nil ? await cameraController.captureLatestFrame() : nil
        let completion = container.cameraGuidanceCaptureCoordinator.completeCapture(
            stillImage: stillImage,
            fallbackImage: fallbackImage,
            selectedTemplate: selectedTemplate,
            score: poseScore.value,
            trigger: trigger,
            capturedAt: .now
        )
        captureResult = completion.result
        if let failureTitleKey = completion.failureTitleKey,
           let failureMessageKey = completion.failureMessageKey {
            alert = CameraGuidanceAlert(
                titleKey: failureTitleKey,
                messageKey: failureMessageKey
            )
        }

        guard completion.shouldResetAutoCapture else { return }
        await container.autoCaptureCoordinator.reset()
    }

    private func applyTemplateState(_ state: CameraGuidanceTemplateState) {
        templates = state.templates
        selectedTemplate = state.selectedTemplate
        recommendations = state.recommendations
        importMatch = state.importMatch
    }

    private func markPreviewWarmup() {
        previewStableAfter = ProcessInfo.processInfo.systemUptime + previewWarmupDuration
        autoCaptureState = .stabilizing
        coachCopy = "coach.stabilizing"
    }

    private func isPreviewStable(at timestamp: TimeInterval) -> Bool {
        guard let previewStableAfter else { return true }
        if timestamp >= previewStableAfter {
            self.previewStableAfter = nil
            return true
        }
        return false
    }

    static func extractBrightness(from sampleBuffer: CMSampleBuffer) -> Double? {
        guard let attachments = CMCopyDictionaryOfAttachments(
            allocator: kCFAllocatorDefault,
            target: sampleBuffer,
            attachmentMode: kCMAttachmentMode_ShouldPropagate
        ) as? [String: Any],
        let exif = attachments[kCGImagePropertyExifDictionary as String] as? [String: Any]
        else {
            return nil
        }

        if let brightness = exif[kCGImagePropertyExifBrightnessValue as String] as? NSNumber {
            return brightness.doubleValue
        }

        return exif[kCGImagePropertyExifBrightnessValue as String] as? Double
    }
}
