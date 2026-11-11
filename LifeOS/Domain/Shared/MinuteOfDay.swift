import Foundation

/// Conversión entre una hora del día en minutos (540 = 9:00) y `Date`.
///
/// Los bloques de agenda guardan minutos del día en lugar de instantes: un
/// bloque de 9:00 a 11:00 sigue siéndolo aunque cambie la zona horaria.
/// 1440 representa la medianoche al final del día.
nonisolated enum MinuteOfDay {
    static let endOfDay = 1440

    static func from(_ date: Date, calendar: Calendar) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    /// La fecha de ese minuto en ese día. 1440 es la medianoche siguiente.
    static func date(_ minute: Int, on day: LocalDay, calendar: Calendar) -> Date? {
        guard let midday = day.middayDate(in: calendar) else { return nil }
        if minute >= endOfDay {
            let startOfDay = calendar.startOfDay(for: midday)
            return calendar.date(byAdding: .day, value: 1, to: startOfDay)
        }
        return calendar.date(
            bySettingHour: max(minute, 0) / 60,
            minute: max(minute, 0) % 60,
            second: 0,
            of: midday
        )
    }
}
