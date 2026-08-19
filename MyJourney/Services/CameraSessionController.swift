@preconcurrency import AVFoundation
import UIKit

enum CameraSessionError: LocalizedError {
    case cameraUnavailable
    case cannotCreateInput
    case cannotAddInput
    case cannotAddOutput
    case captureInProgress
    case captureFailed
    case invalidPhotoData

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "The selected camera is unavailable on this device."
        case .cannotCreateInput:
            return "The camera input could not be created."
        case .cannotAddInput, .cannotAddOutput:
            return "The camera session could not be configured."
        case .captureInProgress:
            return "A capture is already in progress."
        case .captureFailed, .invalidPhotoData:
            return "The photo could not be captured."
        }
    }
}

protocol CameraSessionControlling: AnyObject {
    var session: AVCaptureSession { get }
    func configure(preferredCamera: JourneyCameraPreference) async throws
    func startRunning()
    func stopRunning()
    func capturePhoto() async throws -> UIImage
}

final class CameraSessionController: NSObject, CameraSessionControlling, @unchecked Sendable {
    let session = AVCaptureSession()
    private let portraitRotationAngle: CGFloat = 90

    private let sessionQueue = DispatchQueue(label: "com.myjourney.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var activeCameraPreference: JourneyCameraPreference = .back
    private var captureContinuation: CheckedContinuation<UIImage, Error>?

    func configure(preferredCamera: JourneyCameraPreference) async throws {
        activeCameraPreference = preferredCamera

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraSessionError.cameraUnavailable)
                    return
                }

                do {
                    try self.configureSession(preferredCamera: preferredCamera)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func startRunning() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopRunning() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func capturePhoto() async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraSessionError.captureFailed)
                    return
                }

                guard self.captureContinuation == nil else {
                    continuation.resume(throwing: CameraSessionError.captureInProgress)
                    return
                }

                self.captureContinuation = continuation

                let settings = AVCapturePhotoSettings()
                settings.photoQualityPrioritization = self.photoOutput.maxPhotoQualityPrioritization

                if let connection = self.photoOutput.connection(with: .video) {
                    if connection.isVideoRotationAngleSupported(self.portraitRotationAngle) {
                        connection.videoRotationAngle = self.portraitRotationAngle
                    }

                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = self.activeCameraPreference == .front
                    }
                }

                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    private func configureSession(preferredCamera: JourneyCameraPreference) throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .photo

        if let currentInput {
            session.removeInput(currentInput)
            self.currentInput = nil
        }

        if session.outputs.contains(where: { $0 === photoOutput }) == false {
            guard session.canAddOutput(photoOutput) else {
                throw CameraSessionError.cannotAddOutput
            }

            session.addOutput(photoOutput)
        }

        photoOutput.maxPhotoQualityPrioritization = .quality

        guard let device = cameraDevice(for: preferredCamera) else {
            throw CameraSessionError.cameraUnavailable
        }

        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch {
            throw CameraSessionError.cannotCreateInput
        }

        guard session.canAddInput(input) else {
            throw CameraSessionError.cannotAddInput
        }

        session.addInput(input)
        currentInput = input
    }

    private func cameraDevice(for preference: JourneyCameraPreference) -> AVCaptureDevice? {
        let preferredPosition: AVCaptureDevice.Position = preference == .front ? .front : .back
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: preferredPosition
        )

        if let device = discoverySession.devices.first {
            return device
        }

        return AVCaptureDevice.default(for: .video)
    }
}

extension CameraSessionController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if let error {
                self.captureContinuation?.resume(throwing: error)
                self.captureContinuation = nil
                return
            }

            guard
                let data = photo.fileDataRepresentation(),
                let image = UIImage(data: data)
            else {
                self.captureContinuation?.resume(throwing: CameraSessionError.invalidPhotoData)
                self.captureContinuation = nil
                return
            }

            self.captureContinuation?.resume(returning: image)
            self.captureContinuation = nil
        }
    }
}
