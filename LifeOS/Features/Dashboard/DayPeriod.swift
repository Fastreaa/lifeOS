import Foundation

/// Franja del día usada para el saludo. Lógica pura, sin dependencias de UI.
enum DayPeriod: Equatable {
    case morning
    case afternoon
    case night

    init(date: Date, calendar: Calendar = .current) {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12: self = .morning
        case 12..<20: self = .afternoon
        default: self = .night
        }
    }

    var greeting: LocalizedStringResource {
        switch self {
        case .morning: "Buenos días"
        case .afternoon: "Buenas tardes"
        case .night: "Buenas noches"
        }
    }
}
