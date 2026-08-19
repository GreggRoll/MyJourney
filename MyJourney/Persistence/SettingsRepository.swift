import Foundation

struct SettingsRepository {
    private let fileStore: FileStore
    private let fileName = "settings.json"

    init(fileStore: FileStore) {
        self.fileStore = fileStore
    }

    func load() throws -> AppSettings {
        try fileStore.load(AppSettings.self, from: fileName) ?? .default
    }

    func save(_ settings: AppSettings) throws {
        try fileStore.save(settings, to: fileName)
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var settings: AppSettings
    @Published private(set) var persistenceErrorMessage: String?

    private let repository: SettingsRepository

    init(repository: SettingsRepository) {
        self.repository = repository
        do {
            self.settings = try repository.load()
            self.persistenceErrorMessage = nil
        } catch {
            self.settings = .default
            self.persistenceErrorMessage = error.localizedDescription
        }
    }

    func setOnboardingCompleted() {
        var updatedSettings = settings
        updatedSettings.hasCompletedOnboarding = true
        persist(updatedSettings)
    }

    func setQuickResumeEnabled(_ isEnabled: Bool) {
        var updatedSettings = settings
        updatedSettings.showQuickResume = isEnabled
        persist(updatedSettings)
    }

    func setPhotoReminderEnabled(_ isEnabled: Bool, anchorDate: Date?) {
        var updatedSettings = settings
        updatedSettings.isPhotoReminderEnabled = isEnabled
        updatedSettings.photoReminderRotationAnchorDate = anchorDate
        persist(updatedSettings)
    }

    func setPhotoReminderTime(hour: Int, minute: Int) {
        var updatedSettings = settings
        updatedSettings.photoReminderHour = hour
        updatedSettings.photoReminderMinute = minute
        persist(updatedSettings)
    }

    private func persist(_ updatedSettings: AppSettings) {
        do {
            try repository.save(updatedSettings)
            settings = updatedSettings
            persistenceErrorMessage = nil
        } catch {
            persistenceErrorMessage = error.localizedDescription
        }
    }
}
