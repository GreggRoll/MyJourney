import Foundation

struct AppSettings: Codable, Equatable {
    var hasCompletedOnboarding: Bool
    var showQuickResume: Bool
    var preferredAppIcon: String?
    var isPhotoReminderEnabled: Bool
    var photoReminderHour: Int
    var photoReminderMinute: Int
    var photoReminderRotationAnchorDate: Date?

    private enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding
        case showQuickResume
        case preferredAppIcon
        case isPhotoReminderEnabled
        case photoReminderHour
        case photoReminderMinute
        case photoReminderRotationAnchorDate
    }

    static let `default` = AppSettings(
        hasCompletedOnboarding: false,
        showQuickResume: true,
        preferredAppIcon: nil,
        isPhotoReminderEnabled: false,
        photoReminderHour: 20,
        photoReminderMinute: 0,
        photoReminderRotationAnchorDate: nil
    )

    init(
        hasCompletedOnboarding: Bool,
        showQuickResume: Bool,
        preferredAppIcon: String?,
        isPhotoReminderEnabled: Bool,
        photoReminderHour: Int,
        photoReminderMinute: Int,
        photoReminderRotationAnchorDate: Date?
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.showQuickResume = showQuickResume
        self.preferredAppIcon = preferredAppIcon
        self.isPhotoReminderEnabled = isPhotoReminderEnabled
        self.photoReminderHour = photoReminderHour
        self.photoReminderMinute = photoReminderMinute
        self.photoReminderRotationAnchorDate = photoReminderRotationAnchorDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding)
            ?? AppSettings.default.hasCompletedOnboarding
        showQuickResume = try container.decodeIfPresent(Bool.self, forKey: .showQuickResume)
            ?? AppSettings.default.showQuickResume
        preferredAppIcon = try container.decodeIfPresent(String.self, forKey: .preferredAppIcon)
        isPhotoReminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .isPhotoReminderEnabled)
            ?? AppSettings.default.isPhotoReminderEnabled
        photoReminderHour = try container.decodeIfPresent(Int.self, forKey: .photoReminderHour)
            ?? AppSettings.default.photoReminderHour
        photoReminderMinute = try container.decodeIfPresent(Int.self, forKey: .photoReminderMinute)
            ?? AppSettings.default.photoReminderMinute
        photoReminderRotationAnchorDate = try container.decodeIfPresent(
            Date.self,
            forKey: .photoReminderRotationAnchorDate
        )
    }
}
