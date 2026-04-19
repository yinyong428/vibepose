import SwiftUI

struct SettingsView: View {
    @Binding var featureFlags: FeatureFlags

    var body: some View {
        NavigationStack {
            Form {
                Section("settings.features") {
                    Toggle("settings.auto_capture", isOn: $featureFlags.autoCaptureEnabled)
                    Toggle("settings.photographer_guidance", isOn: $featureFlags.photographerGuidanceEnabled)
                    Toggle("settings.face_assist", isOn: $featureFlags.faceAssistEnabled)
                    Toggle("settings.copy_pose", isOn: $featureFlags.copyPoseEnabled)
                }

                Section("settings.runtime") {
                    Text("A15+")
                    Text("12-15 FPS Vision")
                    Text("Global-first zh-Hans / en")
                }
            }
            .navigationTitle("settings.title")
        }
    }
}

