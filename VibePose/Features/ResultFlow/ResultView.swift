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
            ZStack {
                LinearGradient(
                    colors: [
                        Color.black,
                        heroTint.opacity(0.28),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

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
        ZStack(alignment: .topLeading) {
            Image(uiImage: result.image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(heroHeadline)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text(heroMessage)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.82))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [.black.opacity(0.72), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        ),
                        in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                    )
                }
                .shadow(color: heroTint.opacity(0.35), radius: 18, y: 10)

            VStack(alignment: .leading, spacing: 8) {
                badge(title: result.trigger == .automatic ? "result.trigger_auto" : "result.trigger_manual", tint: heroTint)
                badge(
                    title: result.representation == .stillPhoto ? "result.representation_photo" : "result.representation_fallback",
                    tint: result.representation == .stillPhoto ? .mint : .orange
                )
            }
            .padding(16)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(LocalizedStringKey(result.templateDisplayNameKey))
                .font(.title3.bold())
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                summaryMetric(
                    title: "result.metric_score",
                    value: "\(Int(result.score * 100))"
                )
                summaryMetric(
                    title: "result.metric_source",
                    value: result.representation == .stillPhoto ? NSLocalizedString("result.metric_source_photo", comment: "") : NSLocalizedString("result.metric_source_fallback", comment: "")
                )
            }

            Text("result.note")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
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
            .tint(heroTint)

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

    private var heroHeadline: LocalizedStringKey {
        if result.score >= 0.92 {
            return "result.hero_perfect"
        }
        if result.score >= 0.78 {
            return "result.hero_strong"
        }
        return "result.hero_keep_building"
    }

    private var heroMessage: LocalizedStringKey {
        result.trigger == .automatic ? "result.hero_auto_message" : "result.hero_manual_message"
    }

    private var heroTint: Color {
        if result.score >= 0.92 {
            return .mint
        }
        if result.score >= 0.78 {
            return .yellow
        }
        return .orange
    }

    private func badge(title: LocalizedStringKey, tint: Color) -> some View {
        Text(title)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.88), in: Capsule())
    }

    private func summaryMetric(title: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
