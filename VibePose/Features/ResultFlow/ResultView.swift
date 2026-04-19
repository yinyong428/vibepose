import SwiftUI

struct ResultView: View {
    let result: CaptureResult
    let onSave: () async -> Bool
    let onRetake: () -> Void

    @State private var isSaving = false
    @State private var didSave = false
    @State private var showsShareSheet = false
    @State private var saveFailed = false
    #if DEBUG
    @State private var showsDebugMeta = true
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    imageCard
                    summaryCard
                    #if DEBUG
                    if showsDebugMeta {
                        debugMetadataCard
                    }
                    #endif
                    actions
                }
                .padding()
            }
            .navigationTitle("result.title")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showsShareSheet) {
                ActivityView(items: [result.image])
            }
            .alert("result.save_failed_title", isPresented: $saveFailed) {
                Button("result.dismiss", role: .cancel) {}
            } message: {
                Text("result.save_failed_message")
            }
            #if DEBUG
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showsDebugMeta.toggle()
                    } label: {
                        Image(systemName: "ladybug")
                    }
                }
            }
            #endif
        }
    }

    private var imageCard: some View {
        VStack(spacing: 0) {
            Image(uiImage: result.image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey(result.templateDisplayNameKey))
                .font(.title3.bold())
            Text("result.score_label \(Int(result.score * 100))")
                .font(.headline)
            Text(result.trigger == .automatic ? "result.trigger_auto" : "result.trigger_manual")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(result.representation == .stillPhoto ? "result.representation_photo" : "result.representation_fallback")
                .font(.subheadline)
                .foregroundStyle(result.representation == .stillPhoto ? .green : .orange)
            Text("result.note")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    #if DEBUG
    private var debugMetadataCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DEBUG METADATA")
                .font(.caption.bold())
                .foregroundStyle(.yellow)
            Group {
                Text("trigger: \(result.trigger.rawValue)")
                Text("representation: \(result.representation.rawValue)")
                Text("template key: \(result.templateDisplayNameKey)")
                Text("captured: \(result.capturedAt.formatted(date: .abbreviated, time: .standard))")
            }
            .font(.caption.monospaced())
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 20))
    }
    #endif

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    isSaving = true
                    let saved = await onSave()
                    didSave = saved
                    saveFailed = !saved
                    isSaving = false
                }
            } label: {
                Label(didSave ? "result.saved" : "result.save", systemImage: didSave ? "checkmark.circle.fill" : "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving || didSave)

            Button {
                showsShareSheet = true
            } label: {
                Label("result.share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                onRetake()
            } label: {
                Label("result.retake", systemImage: "camera")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}
