import AVFoundation
import Foundation

enum CameraAuthorizationState: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

protocol CameraAuthorizationProviding {
    func currentStatus() -> CameraAuthorizationState
    func requestAccess() async -> CameraAuthorizationState
}

struct CameraAuthorizationService: CameraAuthorizationProviding {
    func currentStatus() -> CameraAuthorizationState {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }

    func requestAccess() async -> CameraAuthorizationState {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        return granted ? .authorized : .denied
    }
}
