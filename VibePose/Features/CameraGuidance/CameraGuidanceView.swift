import SwiftUI

struct CameraGuidanceView: View {
    @StateObject var viewModel: CameraGuidanceViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.cameraAuthorized {
                CameraPreviewView(session: viewModel.cameraController.session)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                    Text("camera.permission_needed")
                        .font(.headline)
                    Text("camera.permission_hint")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.white)
                .padding()
            }

            overlay
        }
        .navigationTitle("摆个Pose")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.showsSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleCamera()
                } label: {
                    Image(systemName: "camera.rotate")
                }
            }
        }
        .sheet(isPresented: $viewModel.showsSettings) {
            SettingsView(featureFlags: $viewModel.featureFlags)
        }
        .sheet(isPresented: $viewModel.showsResult) {
            ResultView(
                score: viewModel.poseScore.value,
                templateName: LocalizedStringKey(viewModel.selectedTemplate?.displayNameKey ?? "template.unknown")
            )
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    private var overlay: some View {
        VStack(spacing: 0) {
            coachBar
            Spacer()
            poseCanvas
            Spacer()
            recommendationsBar
            controls
        }
    }

    private var coachBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(viewModel.coachCopy))
                    .font(.headline)
                Text("Score \(Int(viewModel.poseScore.value * 100)) · Pitch \(viewModel.pitchText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .padding()
    }

    private var poseCanvas: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                drawPose(viewModel.selectedTemplate?.pose, color: .orange, in: size, context: &context)
                drawPose(viewModel.detectedPose, color: .mint, in: size, context: &context)
            }
            .overlay(alignment: .bottomTrailing) {
                VStack(alignment: .trailing, spacing: 8) {
                    statusBadge
                    Text(viewModel.selectedTemplate.map { LocalizedStringKey($0.displayNameKey) } ?? "template.unknown")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .padding()
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private var statusBadge: some View {
        let text: String = {
            switch viewModel.autoCaptureState {
            case .idle: return "Idle"
            case .noPerson: return "No Person"
            case .aligning: return "Aligning"
            case .ready: return "Ready"
            case .perfect: return "Perfect"
            case .countdown(let seconds): return "Countdown \(seconds)"
            }
        }()

        return Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private var recommendationsBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.recommendations.isEmpty {
                Text("camera.recommendations")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal)
            }

            TemplatePickerView(
                templates: viewModel.recommendations.isEmpty ? viewModel.templates : viewModel.recommendations,
                selectedTemplateID: viewModel.selectedTemplate?.id,
                onSelect: viewModel.selectTemplate
            )
        }
    }

    private var controls: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("camera.cutline")
                    .font(.caption.bold())
                Text("Must Ship: single-person loop, local templates, matching, save/share hooks")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 220, alignment: .leading)
            }

            Spacer()

            Button {
                viewModel.captureManual()
            } label: {
                Circle()
                    .fill(Color.white)
                    .frame(width: 72, height: 72)
                    .overlay {
                        Circle()
                            .stroke(Color.black.opacity(0.25), lineWidth: 4)
                            .padding(6)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func drawPose(_ pose: CanonicalPose19?, color: Color, in size: CGSize, context: inout GraphicsContext) {
        guard let pose else { return }

        for segment in CanonicalPose19.skeletonSegments {
            guard
                let start = pose.point(for: segment.0),
                let end = pose.point(for: segment.1)
            else { continue }

            var path = Path()
            path.move(to: CGPoint(x: start.x * size.width, y: start.y * size.height))
            path.addLine(to: CGPoint(x: end.x * size.width, y: end.y * size.height))
            context.stroke(path, with: .color(color.opacity(0.9)), lineWidth: 3)
        }
    }
}

