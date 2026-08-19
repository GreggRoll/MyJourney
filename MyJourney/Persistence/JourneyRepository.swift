import Foundation

struct JourneyPersistenceSnapshot: Codable {
    var journeys: [Journey]
    var entries: [JourneyEntryMetadata]

    static let empty = JourneyPersistenceSnapshot(journeys: [], entries: [])
}

struct JourneyRepository {
    private let fileStore: FileStore
    private let fileName = "journeys.json"

    init(fileStore: FileStore) {
        self.fileStore = fileStore
    }

    func load() throws -> JourneyPersistenceSnapshot {
        try fileStore.load(JourneyPersistenceSnapshot.self, from: fileName) ?? .empty
    }

    func save(_ snapshot: JourneyPersistenceSnapshot) throws {
        try fileStore.save(snapshot, to: fileName)
    }
}

@MainActor
final class JourneyStore: ObservableObject {
    @Published private(set) var journeys: [Journey]
    @Published private(set) var entries: [JourneyEntryMetadata]
    @Published private(set) var persistenceErrorMessage: String?

    private let repository: JourneyRepository
    private let imageStore: JourneyImageStoring

    init(repository: JourneyRepository, imageStore: JourneyImageStoring) {
        self.repository = repository
        self.imageStore = imageStore
        let snapshot: JourneyPersistenceSnapshot
        do {
            snapshot = try repository.load()
            self.persistenceErrorMessage = nil
        } catch {
            snapshot = .empty
            self.persistenceErrorMessage = error.localizedDescription
        }
        self.journeys = snapshot.journeys
        self.entries = snapshot.entries
    }

    @discardableResult
    func createJourney(name: String, preferredCamera: JourneyCameraPreference, defaultOverlayOpacity: Double) -> Journey? {
        let now = Date()
        let journey = Journey(
            name: name,
            preferredCamera: preferredCamera,
            defaultOverlayOpacity: defaultOverlayOpacity,
            createdAt: now,
            updatedAt: now
        )

        var updatedJourneys = journeys
        updatedJourneys.insert(journey, at: 0)
        return commit(journeys: updatedJourneys, entries: entries) ? journey : nil
    }

    @discardableResult
    func updateJourney(id: UUID, name: String, preferredCamera: JourneyCameraPreference, defaultOverlayOpacity: Double) -> Bool {
        var updatedJourneys = journeys
        guard let index = updatedJourneys.firstIndex(where: { $0.id == id }) else {
            return false
        }

        updatedJourneys[index].name = name
        updatedJourneys[index].preferredCamera = preferredCamera
        updatedJourneys[index].defaultOverlayOpacity = defaultOverlayOpacity
        updatedJourneys[index].updatedAt = .now
        return commit(journeys: updatedJourneys, entries: entries)
    }

    @discardableResult
    func deleteJourney(id: UUID) -> Bool {
        let removedEntries = entries.filter { $0.journeyID == id }
        let updatedJourneys = journeys.filter { $0.id != id }
        let updatedEntries = entries.filter { $0.journeyID != id }

        guard commit(journeys: updatedJourneys, entries: updatedEntries) else {
            return false
        }

        do {
            try imageStore.deleteAssets(for: removedEntries)
        } catch {
            persistenceErrorMessage = "The journey was deleted, but some local image files could not be cleaned up."
        }
        return true
    }

    func entryCount(for journeyID: UUID) -> Int {
        entries.lazy.filter { $0.journeyID == journeyID }.count
    }

    func mostRecentJourney() -> Journey? {
        journeys.max(by: { $0.updatedAt < $1.updatedAt })
    }

    func journey(with id: UUID) -> Journey? {
        journeys.first(where: { $0.id == id })
    }

    func journey(named name: String) -> Journey? {
        journeys.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })
    }

    func entries(for journeyID: UUID) -> [JourneyEntryMetadata] {
        entries
            .filter { $0.journeyID == journeyID }
            .sorted(by: { $0.createdAt > $1.createdAt })
    }

    func latestEntry(for journeyID: UUID) -> JourneyEntryMetadata? {
        entries(for: journeyID).first
    }

    @discardableResult
    func addEntryMetadata(_ metadata: JourneyEntryMetadata) -> Bool {
        var updatedEntries = entries
        var updatedJourneys = journeys
        updatedEntries.append(metadata)

        if let index = updatedJourneys.firstIndex(where: { $0.id == metadata.journeyID }) {
            updatedJourneys[index].updatedAt = metadata.updatedAt
            updatedJourneys[index].latestThumbnailToken = metadata.thumbnailFilename ?? metadata.imageFilename
        }

        return commit(journeys: updatedJourneys, entries: updatedEntries)
    }

    private func commit(journeys: [Journey], entries: [JourneyEntryMetadata]) -> Bool {
        do {
            try repository.save(
                JourneyPersistenceSnapshot(
                    journeys: journeys,
                    entries: entries
                )
            )
            self.journeys = journeys
            self.entries = entries
            persistenceErrorMessage = nil
            return true
        } catch {
            persistenceErrorMessage = error.localizedDescription
            return false
        }
    }
}
