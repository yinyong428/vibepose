import SwiftUI

@main
struct VibePoseApp: App {
    @StateObject private var container = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CameraGuidanceView(
                    viewModel: CameraGuidanceViewModel(container: container)
                )
            }
        }
    }
}

