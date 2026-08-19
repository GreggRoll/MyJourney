import Combine
import Foundation
import UIKit

struct JourneyCompareEntryOption: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
}

@MainActor
final class JourneyCompareViewModel: ObservableObject {
    @Published private(set) var journey: Journey
    @Published private(set) var entryOptions: [JourneyCompareEntryOption] = []
    @Published var beforeEntryID: UUID?
    @Published var afterEntryID: UUID?
    @Published var sliderPosition: Double = 0.5
    @Published private(set) var beforeImage: UIImage?
    @Published private(set) var afterImage: UIImage?
    @Published private(set) var showsFreeWatermark: Bool

    private let journeyID: UUID
    private let journeyStore: JourneyStore
    private let imageStore: JourneyImageStoring
    private let monetizationService: MonetizationService
    private var cancellables = Set<AnyCancellable>()

    init(
        journeyID: UUID,
        journeyStore: JourneyStore,
        imageStore: JourneyImageStoring,
        monetizationService: MonetizationService
    ) {
        self.journeyID = journeyID
        self.journeyStore = journeyStore
        self.imageStore = imageStore
        self.monetizationService = monetizationService
        self.showsFreeWatermark = !monetizationService.currentState.hasPremium
        self.journey = journeyStore.journey(with: journeyID)
            ?? Journey(name: "Journey", preferredCamera: .back, defaultOverlayOpacity: 0.45)

        bind()
        refresh()
    }

    var canCompare: Bool {
        beforeImage != nil && afterImage != nil
    }

    func setBeforeEntry(_ id: UUID) {
        beforeEntryID = id
        if beforeEntryID == afterEntryID, let fallback = entryOptions.last(where: { $0.id != id })?.id {
            afterEntryID = fallback
        }
        loadSelectedImages()
    }

    func setAfterEntry(_ id: UUID) {
        afterEntryID = id
        if beforeEntryID == afterEntryID, let fallback = entryOptions.first(where: { $0.id != id })?.id {
            beforeEntryID = fallback
        }
        loadSelectedImages()
    }

    private func bind() {
        journeyStore.$journeys
            .combineLatest(journeyStore.$entries)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.refresh()
            }
            .store(in: &cancellables)

        monetizationService.statePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.showsFreeWatermark = !state.hasPremium
            }
            .store(in: &cancellables)
    }

    private func refresh() {
        if let updatedJourney = journeyStore.journey(with: journeyID) {
            journey = updatedJourney
        }

        let ascendingEntries = journeyStore.entries(for: journeyID).sorted(by: { $0.createdAt < $1.createdAt })
        entryOptions = ascendingEntries.enumerated().map { index, entry in
            JourneyCompareEntryOption(
                id: entry.id,
                title: "Entry \(index + 1)",
                subtitle: entry.createdAt.formatted(date: .abbreviated, time: .omitted)
            )
        }

        if beforeEntryID == nil {
            beforeEntryID = ascendingEntries.first?.id
        }

        if afterEntryID == nil {
            afterEntryID = ascendingEntries.last?.id
        }

        if beforeEntryID == afterEntryID, entryOptions.count > 1 {
            afterEntryID = entryOptions.last?.id
            beforeEntryID = entryOptions.first?.id
        }

        loadSelectedImages()
    }

    private func loadSelectedImages() {
        let allEntries = journeyStore.entries(for: journeyID)

        if let beforeEntryID, let beforeEntry = allEntries.first(where: { $0.id == beforeEntryID }) {
            beforeImage = imageStore.loadPreview(
                journeyID: journeyID,
                filename: beforeEntry.imageFilename,
                maxDimension: 1_600
            )
        } else {
            beforeImage = nil
        }

        if let afterEntryID, let afterEntry = allEntries.first(where: { $0.id == afterEntryID }) {
            afterImage = imageStore.loadPreview(
                journeyID: journeyID,
                filename: afterEntry.imageFilename,
                maxDimension: 1_600
            )
        } else {
            afterImage = nil
        }
    }
}
