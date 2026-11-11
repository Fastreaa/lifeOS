import Foundation

/// Estado editable del perfil. Las horas se guardan como `Date` para usarlas
/// directamente con `DatePicker`; solo importa la hora.
struct ProfileDraft: Equatable {
    var name: String
    var dayStart: Date
    var dayEnd: Date

    init(profile: UserProfile, calendar: Calendar = .current) {
        let today = LocalDay(.now, calendar: calendar)
        name = profile.displayName ?? ""
        dayStart = MinuteOfDay.date(profile.dayStartMinute, on: today, calendar: calendar) ?? .now
        dayEnd = MinuteOfDay.date(profile.dayEndMinute, on: today, calendar: calendar) ?? .now
    }
}

extension ProfileValidationError {
    var userMessage: String {
        switch self {
        case .nameTooLong(let maxLength):
            String(localized: "El nombre puede tener como máximo \(maxLength) caracteres.")
        case .invalidDayWindow:
            String(localized: "La hora de acostarte debe ser posterior a la de levantarte.")
        case .dayTooShort(let minimum):
            String(localized: "Tu día debe durar al menos \(minimum / 60) horas.")
        }
    }
}
