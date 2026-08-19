import Combine
import Foundation
import UIKit

@MainActor
final class JourneyCaptureViewModel: ObservableObject {
    enum PermissionState: Equatable {
        case checking
        case ready
        case denied
        case restricted
        case unavailable(String)
    }

    @Published private(set) var journey: Journey
    @Published private(set) var latestReferenceImage: UIImage?
    @Published private(set) var permissionState: PermissionState = .checking
    @Published private(set) var statusMessage: String?
    @Published private(set) var countdownValue: Int?
    @Published private(set) var isSaving = false
    @Published var overlayOpacity: Double
    @Published var isGridEnabled = false
    @Published var isTimerEnabled = false

    let cameraController: CameraSessionControlling

    private let journeyStore: JourneyStore
    private let imageStore: JourneyImageStoring
    private let authorizationService: CameraAuthorizationProviding
    private let onCaptureSaved: (() -> Void)?
    private var cancellables = Set<AnyCancellable>()

    init(
        journey: Journey,
        journeyStore: JourneyStore,
        imageStore: JourneyImageStoring,
        authorizationService: CameraAuthorizationProviding,
        cameraController: CameraSessionControlling,
        onCaptureSaved: (() -> Void)? = nil
    ) {
        self.journey = journey
        self.journeyStore = journeyStore
        self.imageStore = imageStore
        self.authorizationService = authorizationService
        self.cameraController = cameraController
        self.onCaptureSaved = onCaptureSaved
        self.overlayOpacity = journey.defaultOverlayOpacity

        observeJourneyChanges()
        refreshLatestReferenceImage()
    }

    var opacityPercentageText: String {
        overlayOpacity.formatted(.percent.precision(.fractionLength(0)))
    }

    var canCapture: Bool {
        permissionState == .ready && !isSaving && countdownValue == nil
    }

    func handleAppear() {
        Task {
            await prepareCamera()
        }
    }

    func handleDisappear() {
        cameraController.stopRunning()
    }

    func requestPermissionAgain() {
        Task {
            await prepareCamera()
        }
    }

    func capturePhoto() {
        Task {
            await performCapture()
        }
    }

    private func observeJourneyChanges() {
        journeyStore.$journeys
            .receive(on: RunLoop.main)
            .sink { [weak self] journeys in
                guard
                    let self,
                    let updatedJourney = journeys.first(where: { $0.id == self.journey.id })
                else { return }

                self.journey = updatedJourney
            }
            .store(in: &cancellables)

        journeyStore.$entries
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshLatestReferenceImage()
            }
            .store(in: &cancellables)
    }

    private func refreshLatestReferenceImage() {
        guard let latestEntry = journeyStore.latestEntry(for: journey.id) else {
            latestReferenceImage = nil
            return
        }

        latestReferenceImage = imageStore.loadPreview(
            journeyID: journey.id,
            filename: latestEntry.imageFilename,
            maxDimension: 1_600
        )
    }

    private func prepareCamera() async {
        statusMessage = nil

        let currentStatus = authorizationService.currentStatus()
        switch currentStatus {
        case .authorized:
            await configureAndStartSession()
        case .notDetermined:
            let requestedStatus = await authorizationService.requestAccess()
            await handleAuthorizationResult(requestedStatus)
        case .denied:
            permissionState = .denied
        case .restricted:
            permissionState = .restricted
        }
    }

    private func handleAuthorizationResult(_ state: CameraAuthorizationState) async {
        switch state {
        case .authorized:
            await configureAndStartSession()
        case .denied:
            permissionState = .denied
        case .restricted:
            permissionState = .restricted
        case .notDetermined:
            permissionState = .checking
        }
    }

    private func configureAndStartSession() async {
        do {
            try await cameraController.configure(preferredCamera: journey.preferredCamera)
            cameraController.startRunning()
            permissionState = .ready
        } catch {
            permissionState = .unavailable(error.localizedDescription)
        }
    }

    private func performCapture() async {
        guard canCapture else {
            return
        }

        if isTimerEnabled {
            for value in stride(from: 3, through: 1, by: -1) {
                countdownValue = value
                try? await Task.sleep(for: .seconds(1))
            }
            countdownValue = nil
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let image = try await cameraController.capturePhoto()
            let entryID = UUID()
            let capturedAt = Date()
            let storedAssets = try imageStore.saveImage(
                image,
                for: journey.id,
                entryID: entryID
            )

            let metadata = JourneyEntryMetadata(
                id: entryID,
                journeyID: journey.id,
                createdAt: capturedAt,
                updatedAt: capturedAt,
                imageFilename: storedAssets.imageFilename,
                thumbnailFilename: storedAssets.thumbnailFilename
            )

            guard journeyStore.addEntryMetadata(metadata) else {
                try? imageStore.deleteAssets(for: [metadata])
                statusMessage = journeyStore.persistenceErrorMessage ?? "The photo could not be saved."
                return
            }
            latestReferenceImage = image
            statusMessage = "Saved to \(journey.name)"
            onCaptureSaved?()
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
