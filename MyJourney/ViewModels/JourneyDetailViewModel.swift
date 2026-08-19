import Combine
import Foundation
import UIKit

struct JourneyTimelineEntry: Identifiable, Equatable {
    let id: UUID
    let metadata: JourneyEntryMetadata
    let sequenceNumber: Int
    let thumbnail: UIImage?

    var title: String {
        "Entry \(sequenceNumber)"
    }

    var subtitle: String {
        metadata.createdAt.formatted(date: .abbreviated, time: .omitted)
    }
}

@MainActor
final class JourneyDetailViewModel: ObservableObject {
    @Published private(set) var journey: Journey
    @Published private(set) var entryCount: Int = 0
    @Published private(set) var latestImage: UIImage?
    @Published private(set) var timelineEntries: [JourneyTimelineEntry] = []
    @Published private(set) var firstEntry: JourneyTimelineEntry?
    @Published private(set) var latestEntry: JourneyTimelineEntry?

    private let journeyID: UUID
    private let journeyStore: JourneyStore
    private let imageStore: JourneyImageStoring
    private let exportService: JourneyExportServing
    private let monetizationService: MonetizationService
    private var cancellables = Set<AnyCancellable>()

    init(
        journeyID: UUID,
        journeyStore: JourneyStore,
        imageStore: JourneyImageStoring,
        exportService: JourneyExportServing,
        monetizationService: MonetizationService
    ) {
        self.journeyID = journeyID
        self.journeyStore = journeyStore
        self.imageStore = imageStore
        self.exportService = exportService
        self.monetizationService = monetizationService
        self.journey = journeyStore.journey(with: journeyID)
            ?? Journey(name: "Journey", preferredCamera: .back, defaultOverlayOpacity: 0.45)

        bind()
        refresh()
    }

    func makeCaptureViewModel(
        authorizationService: CameraAuthorizationProviding,
        onCaptureSaved: (() -> Void)? = nil
    ) -> JourneyCaptureViewModel {
        JourneyCaptureViewModel(
            journey: journey,
            journeyStore: journeyStore,
            imageStore: imageStore,
            authorizationService: authorizationService,
            cameraController: CameraSessionController(),
            onCaptureSaved: onCaptureSaved
        )
    }

    func makeCompareViewModel() -> JourneyCompareViewModel {
        JourneyCompareViewModel(
            journeyID: journeyID,
            journeyStore: journeyStore,
            imageStore: imageStore,
            monetizationService: monetizationService
        )
    }

    func makeExportViewModel() -> JourneyExportViewModel {
        JourneyExportViewModel(
            journey: journey,
            entries: journeyStore.entries(for: journeyID),
            exportService: exportService,
            monetizationService: monetizationService
        )
    }

    private func bind() {
        journeyStore.$journeys
            .combineLatest(journeyStore.$entries)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }

    private func refresh() {
        if let updatedJourney = journeyStore.journey(with: journeyID) {
            journey = updatedJourney
        }

        entryCount = journeyStore.entryCount(for: journeyID)
        let ascendingEntries = journeyStore.entries(for: journeyID).sorted(by: { $0.createdAt < $1.createdAt })
        let mappedEntries = ascendingEntries.enumerated().map { index, entry in
            JourneyTimelineEntry(
                id: entry.id,
                metadata: entry,
                sequenceNumber: index + 1,
                thumbnail: imageStore.loadThumbnail(for: journeyID, filename: entry.thumbnailFilename)
            )
        }

        timelineEntries = mappedEntries.reversed()
        firstEntry = mappedEntries.first
        latestEntry = mappedEntries.last
        if let latestMetadata = mappedEntries.last?.metadata {
            latestImage = imageStore.loadPreview(
                journeyID: journeyID,
                filename: latestMetadata.imageFilename,
                maxDimension: 1_200
            )
        } else {
            latestImage = nil
        }
    }
}
