import Foundation
import UserNotifications

enum PhotoReminderAuthorizationStatus: Equatable {
    case notDetermined
    case denied
    case authorized

    var canSchedule: Bool {
        self == .authorized
    }
}

protocol PhotoReminderNotificationServing {
    func authorizationStatus() async -> PhotoReminderAuthorizationStatus
    func requestAuthorization() async -> PhotoReminderAuthorizationStatus
    func scheduleDailyReminders(hour: Int, minute: Int, anchorDate: Date) async throws
    func clearPendingDailyReminders() async
}

enum PhotoReminderNotificationServiceError: LocalizedError {
    case notAuthorized
    case invalidTriggerDate

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notifications are not authorized for My Journey."
        case .invalidTriggerDate:
            return "The reminder time could not be scheduled."
        }
    }
}

struct PhotoReminderNotificationService: PhotoReminderNotificationServing {
    private let center: UNUserNotificationCenter
    private let calendar: Calendar
    private let scheduleLength = 14
    private let identifierPrefix = "com.gregadams.myjourney.photo-reminder"
    private let messages = [
        "Your journey is happening right now… don’t miss today’s chapter.",
        "Just one photo today—your future self will see the difference.",
        "Progress isn’t always obvious… until you look back. Take today’s photo.",
        "One photo closer to seeing your progress—take it now.",
        "Future you is counting on today’s photo."
    ]

    init(
        center: UNUserNotificationCenter = .current(),
        calendar: Calendar = .current
    ) {
        self.center = center
        self.calendar = calendar
    }

    func authorizationStatus() async -> PhotoReminderAuthorizationStatus {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async -> PhotoReminderAuthorizationStatus {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted ? .authorized : .denied
        } catch {
            return .denied
        }
    }

    func scheduleDailyReminders(hour: Int, minute: Int, anchorDate: Date) async throws {
        guard await authorizationStatus().canSchedule else {
            throw PhotoReminderNotificationServiceError.notAuthorized
        }

        await clearPendingDailyReminders()

        let now = Date()
        let firstReminderDate = firstReminder(after: now, hour: hour, minute: minute)
        let normalizedAnchorDate = calendar.startOfDay(for: anchorDate)

        for offset in 0..<scheduleLength {
            guard
                let reminderDate = calendar.date(byAdding: .day, value: offset, to: firstReminderDate)
            else {
                throw PhotoReminderNotificationServiceError.invalidTriggerDate
            }

            let identifier = reminderIdentifier(for: reminderDate)
            let content = UNMutableNotificationContent()
            content.title = "My Journey"
            content.body = message(for: reminderDate, anchorDate: normalizedAnchorDate)
            content.sound = .default

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            try await center.add(request)
        }
    }

    func clearPendingDailyReminders() async {
        let requests = await center.pendingNotificationRequests()
        let identifiers = requests
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }

        guard !identifiers.isEmpty else {
            return
        }

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func firstReminder(after date: Date, hour: Int, minute: Int) -> Date {
        let dayStart = calendar.startOfDay(for: date)
        let sameDayReminder = calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: dayStart
        ) ?? date

        if sameDayReminder > date {
            return sameDayReminder
        }

        let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: nextDay
        ) ?? nextDay
    }

    private func message(for reminderDate: Date, anchorDate: Date) -> String {
        let reminderDay = calendar.startOfDay(for: reminderDate)
        let dayOffset = max(0, calendar.dateComponents([.day], from: anchorDate, to: reminderDay).day ?? 0)
        return messages[dayOffset % messages.count]
    }

    private func reminderIdentifier(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return "\(identifierPrefix)-\(year)-\(month)-\(day)"
    }
}
