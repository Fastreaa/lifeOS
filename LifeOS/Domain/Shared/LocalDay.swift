import Foundation

/// Un día del calendario del usuario (año, mes, día), sin hora ni zona horaria.
///
/// "Martes 10" no es un instante: depende de dónde estés. Por eso los hábitos
/// se registran por `LocalDay` y no por `Date`. Se guarda como el entero
/// `20261110`, fácil de ordenar, comparar y sincronizar.
nonisolated struct LocalDay: Hashable, Comparable, Sendable, CustomStringConvertible {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// El día al que pertenece `date` en el calendario dado.
    init(_ date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        year = components.year ?? 1970
        month = components.month ?? 1
        day = components.day ?? 1
    }

    /// Reconstruye un día desde su valor guardado. `nil` si no es válido.
    init?(storageValue: Int) {
        let year = storageValue / 10_000
        let month = (storageValue / 100) % 100
        let day = storageValue % 100
        guard year > 0, (1...12).contains(month), (1...31).contains(day) else {
            return nil
        }
        self.init(year: year, month: month, day: day)
    }

    /// Ejemplo: 10 de noviembre de 2026 → 20261110.
    var storageValue: Int { year * 10_000 + month * 100 + day }

    var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// Mediodía de ese día. Se usa mediodía y no medianoche porque en algunas
    /// zonas el cambio de horario ocurre a medianoche y esa hora no existe.
    func middayDate(in calendar: Calendar) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))
    }

    func adding(days: Int, calendar: Calendar) -> LocalDay? {
        guard let midday = middayDate(in: calendar),
              let shifted = calendar.date(byAdding: .day, value: days, to: midday) else {
            return nil
        }
        return LocalDay(shifted, calendar: calendar)
    }

    /// Día de la semana según `Calendar`: 1 = domingo … 7 = sábado.
    func weekday(in calendar: Calendar) -> Int? {
        middayDate(in: calendar).map { calendar.component(.weekday, from: $0) }
    }

    static func < (lhs: LocalDay, rhs: LocalDay) -> Bool {
        lhs.storageValue < rhs.storageValue
    }
}
