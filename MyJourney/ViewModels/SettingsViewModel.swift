import Combine
import Foundation
import UIKit

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var settings: AppSettings
    @Published private(set) var monetizationState: MonetizationState
    @Published private(set) var photoReminderAuthorizationStatus: PhotoReminderAuthorizationStatus = .notDetermined
    @Published private(set) var photoReminderStatusMessage: String?
    @Published private(set) var persistenceErrorMessage: String?

    private let settingsStore: SettingsStore
    private let monetizationService: MonetizationService
    private let photoReminderNotificationService: PhotoReminderNotificationServing
    private var cancellables = Set<AnyCancellable>()

    init(
        settingsStore: SettingsStore,
        monetizationService: MonetizationService,
        photoReminderNotificationService: PhotoReminderNotificationServing
    ) {
        self.settingsStore = settingsStore
        self.monetizationService = monetizationService
        self.photoReminderNotificationService = photoReminderNotificationService
        self.settings = settingsStore.settings
        self.monetizationState = monetizationService.currentState
        self.persistenceErrorMessage = settingsStore.persistenceErrorMessage

        settingsStore.$settings
            .receive(on: RunLoop.main)
            .sink { [weak self] settings in
                self?.settings = settings
            }
            .store(in: &cancellables)

        settingsStore.$persistenceErrorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                self?.persistenceErrorMessage = message
            }
            .store(in: &cancellables)

        monetizationService.statePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.monetizationState = state
            }
            .store(in: &cancellables)
    }

    var photoReminderTime: Date {
        let calendar = Calendar.current
        return calendar.date(
            bySettingHour: settings.photoReminderHour,
            minute: settings.photoReminderMinute,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    func setQuickResumeEnabled(_ isEnabled: Bool) {
        settingsStore.setQuickResumeEnabled(isEnabled)
    }

    func handleAppear() async {
        await monetizationService.start()
        await refreshPhotoReminderAuthorizationStatus()
    }

    func setPhotoReminderEnabled(_ isEnabled: Bool) {
        Task {
            await updatePhotoReminderEnabled(isEnabled)
        }
    }

    func setPhotoReminderTime(_ date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? AppSettings.default.photoReminderHour
        let minute = components.minute ?? AppSettings.default.photoReminderMinute
        settingsStore.setPhotoReminderTime(hour: hour, minute: minute)

        Task {
            await syncPhotoReminderSchedule()
        }
    }

    func openSystemNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(url)
    }

    func purchasePremium() {
        Task {
            await monetizationService.purchasePremium()
        }
    }

    func restorePurchases() {
        Task {
            await monetizationService.restorePurchases()
        }
    }

    private func updatePhotoReminderEnabled(_ isEnabled: Bool) async {
        photoReminderStatusMessage = nil

        if !isEnabled {
            settingsStore.setPhotoReminderEnabled(false, anchorDate: nil)
            await photoReminderNotificationService.clearPendingDailyReminders()
            await refreshPhotoReminderAuthorizationStatus()
            return
        }

        let resolvedStatus = await resolvePhotoReminderAuthorizationStatusForEnable()
        photoReminderAuthorizationStatus = resolvedStatus

        guard resolvedStatus.canSchedule else {
            settingsStore.setPhotoReminderEnabled(false, anchorDate: nil)
            photoReminderStatusMessage = "Turn on notifications in iPhone Settings to receive daily reminders."
            return
        }

        let anchorDate = Calendar.current.startOfDay(for: Date())
        settingsStore.setPhotoReminderEnabled(true, anchorDate: anchorDate)
        await syncPhotoReminderSchedule()
    }

    private func resolvePhotoReminderAuthorizationStatusForEnable() async -> PhotoReminderAuthorizationStatus {
        let currentStatus = await photoReminderNotificationService.authorizationStatus()
        guard currentStatus == .notDetermined else {
            return currentStatus
        }

        return await photoReminderNotificationService.requestAuthorization()
    }

    private func refreshPhotoReminderAuthorizationStatus() async {
        photoReminderAuthorizationStatus = await photoReminderNotificationService.authorizationStatus()
    }

    private func syncPhotoReminderSchedule() async {
        await refreshPhotoReminderAuthorizationStatus()
        photoReminderStatusMessage = nil

        guard settings.isPhotoReminderEnabled else {
            await photoReminderNotificationService.clearPendingDailyReminders()
            return
        }

        guard
            photoReminderAuthorizationStatus.canSchedule,
            let anchorDate = settings.photoReminderRotationAnchorDate
        else {
            await photoReminderNotificationService.clearPendingDailyReminders()
            photoReminderStatusMessage = "Turn on notifications in iPhone Settings to receive daily reminders."
            return
        }

        do {
            try await photoReminderNotificationService.scheduleDailyReminders(
                hour: settings.photoReminderHour,
                minute: settings.photoReminderMinute,
                anchorDate: anchorDate
            )
        } catch {
            photoReminderStatusMessage = error.localizedDescription
        }
    }
}
