import Combine
import Foundation
import UIKit

@MainActor
final class JourneyListViewModel: ObservableObject {
    @Published private(set) var journeys: [Journey] = []
    @Published private(set) var quickResumeJourney: Journey?
    @Published private(set) var isQuickResumeEnabled = true

    private let journeyStore: JourneyStore
    private let settingsStore: SettingsStore
    private let imageStore: JourneyImageStoring
    private var cancellables = Set<AnyCancellable>()

    init(
        journeyStore: JourneyStore,
        settingsStore: SettingsStore,
        imageStore: JourneyImageStoring
    ) {
        self.journeyStore = journeyStore
        self.settingsStore = settingsStore
        self.imageStore = imageStore

        journeyStore.$journeys
            .combineLatest(settingsStore.$settings)
            .receive(on: RunLoop.main)
            .sink { [weak self] journeys, settings in
                self?.journeys = journeys.sorted(by: { $0.updatedAt > $1.updatedAt })
                self?.isQuickResumeEnabled = settings.showQuickResume
                self?.quickResumeJourney = settings.showQuickResume
                    ? journeys.max(by: { $0.updatedAt < $1.updatedAt })
                    : nil
            }
            .store(in: &cancellables)

        journeys = journeyStore.journeys.sorted(by: { $0.updatedAt > $1.updatedAt })
        isQuickResumeEnabled = settingsStore.settings.showQuickResume
        quickResumeJourney = isQuickResumeEnabled ? journeyStore.mostRecentJourney() : nil
    }

    func deleteJourneys(at offsets: IndexSet) {
        let ids = offsets.map { journeys[$0].id }
        ids.forEach { id in
            journeyStore.deleteJourney(id: id)
        }
    }

    func entryCount(for journey: Journey) -> Int {
        journeyStore.entryCount(for: journey.id)
    }

    func latestThumbnail(for journey: Journey) -> UIImage? {
        guard let latestEntry = journeyStore.latestEntry(for: journey.id) else {
            return nil
        }

        return imageStore.loadThumbnail(for: journey.id, filename: latestEntry.thumbnailFilename)
            ?? imageStore.loadPreview(
                journeyID: journey.id,
                filename: latestEntry.imageFilename,
                maxDimension: 480
            )
    }
}
