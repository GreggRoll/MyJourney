import Foundation

struct JourneyEntryMetadata: Identifiable, Codable, Equatable {
    let id: UUID
    let journeyID: UUID
    let createdAt: Date
    var updatedAt: Date
    var imageFilename: String
    var thumbnailFilename: String?

    init(
        id: UUID = UUID(),
        journeyID: UUID,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        imageFilename: String,
        thumbnailFilename: String? = nil
    ) {
        self.id = id
        self.journeyID = journeyID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.imageFilename = imageFilename
        self.thumbnailFilename = thumbnailFilename
    }
}
