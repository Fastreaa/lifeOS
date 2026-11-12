import Foundation
import UserNotifications

/// Programa notificaciones locales con `UNUserNotificationCenter`.
/// No guarda estado: es seguro usarla desde cualquier hilo.
nonisolated final class UserNotificationScheduler: NotificationScheduler {
    func authorizationStatus() async -> ReminderAuthorization {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func replaceAll(with notifications: [PlannedNotification]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for item in notifications {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: item.id,
                content: content,
                trigger: Self.trigger(for: item.trigger)
            )
            try? await center.add(request)
        }
    }

    private static func trigger(for trigger: NotificationTrigger) -> UNCalendarNotificationTrigger {
        switch trigger {
        case .daily(let minute):
            var components = DateComponents()
            components.hour = minute / 60
            components.minute = minute % 60
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        case .at(let date):
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }
    }
}

/// Programador que no hace nada. Se usa en las pruebas de interfaz para que
/// no aparezca el diálogo de permiso.
nonisolated final class DisabledNotificationScheduler: NotificationScheduler {
    func authorizationStatus() async -> ReminderAuthorization { .denied }
    func requestAuthorization() async -> Bool { false }
    func replaceAll(with notifications: [PlannedNotification]) async {}
}

/// Permite ver las notificaciones también con la app abierta (por defecto,
/// iOS solo las muestra cuando la app está en segundo plano).
nonisolated final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate, Sendable {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
