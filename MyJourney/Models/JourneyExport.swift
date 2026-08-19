import Foundation

enum JourneyExportFormat: String, CaseIterable, Identifiable {
    case gif
    case mp4

    var id: String { rawValue }

    var displayName: String {
        rawValue.uppercased()
    }

    var fileExtension: String {
        rawValue
    }
}

struct JourneyExportOptions: Equatable {
    var totalDuration: Double
    var includesDateOverlay: Bool
    var includesEntryNumberOverlay: Bool

    static let `default` = JourneyExportOptions(
        totalDuration: 2.5,
        includesDateOverlay: true,
        includesEntryNumberOverlay: false
    )
}

struct JourneyExportedAsset: Identifiable, Equatable {
    let id = UUID()
    let format: JourneyExportFormat
    let fileURL: URL
}
