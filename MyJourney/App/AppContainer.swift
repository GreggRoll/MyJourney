import Foundation

@MainActor
final class AppContainer: ObservableObject {
    let journeyStore: JourneyStore
    let settingsStore: SettingsStore
    let monetizationService: MonetizationService
    let imageStore: JourneyImageStoring
    let cameraAuthorizationService: CameraAuthorizationProviding
    let exportService: JourneyExportServing
    let photoReminderNotificationService: PhotoReminderNotificationServing

    init(
        journeyStore: JourneyStore,
        settingsStore: SettingsStore,
        monetizationService: MonetizationService,
        imageStore: JourneyImageStoring,
        cameraAuthorizationService: CameraAuthorizationProviding,
        exportService: JourneyExportServing,
        photoReminderNotificationService: PhotoReminderNotificationServing
    ) {
        self.journeyStore = journeyStore
        self.settingsStore = settingsStore
        self.monetizationService = monetizationService
        self.imageStore = imageStore
        self.cameraAuthorizationService = cameraAuthorizationService
        self.exportService = exportService
        self.photoReminderNotificationService = photoReminderNotificationService
    }

    static func bootstrap() -> AppContainer {
        let launchConfiguration = LaunchConfiguration.current
        launchConfiguration.resetApplicationDataIfRequested()

        let fileStore = FileStore()
        let imageStore = JourneyImageStore()
        let journeyRepository = JourneyRepository(fileStore: fileStore)
        let settingsRepository = SettingsRepository(fileStore: fileStore)

        let journeyStore = JourneyStore(
            repository: journeyRepository,
            imageStore: imageStore
        )
        let settingsStore = SettingsStore(repository: settingsRepository)
        let monetizationService = StoreKitMonetizationService(
            debugPremiumOverride: launchConfiguration.premiumOverride
        )
        let cameraAuthorizationService = CameraAuthorizationService()
        let exportService = JourneyExportService(imageStore: imageStore)
        let photoReminderNotificationService = PhotoReminderNotificationService()
        let sampleJourneySeeder = SampleJourneySeeder(
            journeyStore: journeyStore,
            imageStore: imageStore
        )

        if launchConfiguration.shouldSeedSampleJourney {
            sampleJourneySeeder.seedUITestJourney()
        }

        return AppContainer(
            journeyStore: journeyStore,
            settingsStore: settingsStore,
            monetizationService: monetizationService,
            imageStore: imageStore,
            cameraAuthorizationService: cameraAuthorizationService,
            exportService: exportService,
            photoReminderNotificationService: photoReminderNotificationService
        )
    }

    func syncPhotoReminderSchedule() async {
        let settings = settingsStore.settings

        guard settings.isPhotoReminderEnabled else {
            await photoReminderNotificationService.clearPendingDailyReminders()
            return
        }

        let status = await photoReminderNotificationService.authorizationStatus()
        guard status.canSchedule, let anchorDate = settings.photoReminderRotationAnchorDate else {
            await photoReminderNotificationService.clearPendingDailyReminders()
            return
        }

        try? await photoReminderNotificationService.scheduleDailyReminders(
            hour: settings.photoReminderHour,
            minute: settings.photoReminderMinute,
            anchorDate: anchorDate
        )
    }
}

private struct LaunchConfiguration {
    let shouldResetApplicationData: Bool
    let shouldSeedSampleJourney: Bool
    let premiumOverride: Bool?

    static var current: LaunchConfiguration {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        let isUITesting = arguments.contains("-ui-testing")

        return LaunchConfiguration(
            shouldResetApplicationData: isUITesting && arguments.contains("-ui-testing-reset"),
            shouldSeedSampleJourney: isUITesting && arguments.contains("-ui-testing-sample-data"),
            premiumOverride: isUITesting ? arguments.contains("-ui-testing-premium") : nil
        )
#else
        return LaunchConfiguration(
            shouldResetApplicationData: false,
            shouldSeedSampleJourney: false,
            premiumOverride: nil
        )
#endif
    }

    func resetApplicationDataIfRequested(fileManager: FileManager = .default) {
        guard shouldResetApplicationData else { return }

        let root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let appDirectory = root.appendingPathComponent("MyJourney", isDirectory: true)

        guard appDirectory.lastPathComponent == "MyJourney" else { return }
        try? fileManager.removeItem(at: appDirectory)
    }
}
