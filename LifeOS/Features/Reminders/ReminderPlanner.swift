import Foundation

/// Convierte las preferencias y los bloques de la agenda en notificaciones.
/// Lógica pura: recibe la hora actual y el calendario para poder probarla.
struct ReminderPlanner {
    /// iOS admite hasta 64 notificaciones pendientes por app; dejamos margen.
    static let maxNotifications = 60

    let calendar: Calendar

    func plan(settings: ReminderSettings, blocks: [TimeBlock], now: Date) -> [PlannedNotification] {
        var result: [PlannedNotification] = []

        if settings.habitsEnabled {
            result.append(PlannedNotification(
                id: "lifeos.habits",
                title: String(localized: "Tus hábitos de hoy"),
                body: String(localized: "Si te apetece, tómate un momento para marcarlos. Un paso pequeño también cuenta."),
                trigger: .daily(minute: settings.habitsMinute)
            ))
        }

        if settings.checkInEnabled {
            result.append(PlannedNotification(
                id: "lifeos.checkin",
                title: String(localized: "¿Cómo estás hoy?"),
                body: String(localized: "Registrar tu energía y tu ánimo toma unos segundos."),
                trigger: .daily(minute: settings.checkInMinute)
            ))
        }

        if settings.blockAlertsEnabled {
            let lead = TimeInterval(settings.blockLeadMinutes * 60)
            let upcoming = blocks
                .filter { !$0.isDeleted }
                .sorted { ($0.day, $0.startMinute) < ($1.day, $1.startMinute) }
            for block in upcoming {
                guard let start = MinuteOfDay.date(block.startMinute, on: block.day, calendar: calendar) else {
                    continue
                }
                let fireDate = start.addingTimeInterval(-lead)
                guard fireDate > now else { continue }
                let time = AgendaFormat.time(block.startMinute, on: block.day, calendar: calendar)
                let kind = String(localized: block.kind.label)
                result.append(PlannedNotification(
                    id: "lifeos.block.\(block.id.uuidString)",
                    title: block.title,
                    body: String(localized: "Empieza a las \(time) · \(kind)"),
                    trigger: .at(fireDate)
                ))
            }
        }

        return Array(result.prefix(Self.maxNotifications))
    }
}
