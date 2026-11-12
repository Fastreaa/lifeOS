import Foundation

/// Preferencias de recordatorios. Son de cada dispositivo: no se sincronizan.
/// Todo empieza desactivado.
nonisolated struct ReminderSettings: Codable, Equatable, Sendable {
    /// Opciones de aviso antes de un bloque, en minutos.
    static let leadOptions = [5, 10, 15, 30]

    var habitsEnabled = false
    /// Hora del recordatorio de hábitos, en minutos del día.
    var habitsMinute = 20 * 60
    var checkInEnabled = false
    var checkInMinute = 21 * 60
    var blockAlertsEnabled = false
    var blockLeadMinutes = 10

    var anyEnabled: Bool {
        habitsEnabled || checkInEnabled || blockAlertsEnabled
    }

    /// Las mismas preferencias con todo apagado (por ejemplo, si se deniega el permiso).
    func disablingAll() -> ReminderSettings {
        var copy = self
        copy.habitsEnabled = false
        copy.checkInEnabled = false
        copy.blockAlertsEnabled = false
        return copy
    }
}

/// Estado del permiso de notificaciones de iOS.
nonisolated enum ReminderAuthorization: Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
}

/// Cuándo se dispara una notificación.
nonisolated enum NotificationTrigger: Equatable, Sendable {
    /// Todos los días a esa hora (minutos del día).
    case daily(minute: Int)
    /// Una sola vez, en ese momento.
    case at(Date)
}

/// Una notificación lista para programar.
nonisolated struct PlannedNotification: Equatable, Sendable {
    let id: String
    let title: String
    let body: String
    let trigger: NotificationTrigger
}

/// Contrato para programar notificaciones. La implementación real usa
/// `UserNotifications`; las pruebas usan una falsa.
nonisolated protocol NotificationScheduler: Sendable {
    func authorizationStatus() async -> ReminderAuthorization
    /// Muestra el diálogo de permiso de iOS (solo la primera vez).
    func requestAuthorization() async -> Bool
    /// Sustituye todas las notificaciones pendientes por estas.
    func replaceAll(with notifications: [PlannedNotification]) async
}

/// Contrato para guardar las preferencias de recordatorios.
@MainActor
protocol ReminderSettingsStore {
    func load() -> ReminderSettings
    func save(_ settings: ReminderSettings)
}
