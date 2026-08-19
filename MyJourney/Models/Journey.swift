import Foundation

enum JourneyCameraPreference: String, CaseIterable, Codable, Identifiable {
    case front
    case back

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .front:
            return "Front Camera"
        case .back:
            return "Back Camera"
        }
    }
}

struct Journey: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var preferredCamera: JourneyCameraPreference
    var defaultOverlayOpacity: Double
    let createdAt: Date
    var updatedAt: Date
    var latestThumbnailToken: String?

    init(
        id: UUID = UUID(),
        name: String,
        preferredCamera: JourneyCameraPreference,
        defaultOverlayOpacity: Double,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        latestThumbnailToken: String? = nil
    ) {
        self.id = id
        self.name = name
        self.preferredCamera = preferredCamera
        self.defaultOverlayOpacity = defaultOverlayOpacity
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.latestThumbnailToken = latestThumbnailToken
    }
}
