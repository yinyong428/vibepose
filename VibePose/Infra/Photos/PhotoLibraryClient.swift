import Photos

struct PhotoLibraryClient {
    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    }
}

