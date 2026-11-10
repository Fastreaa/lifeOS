import Foundation

/// Estado editable del formulario de check-in.
struct CheckInDraft: Equatable {
    var energy = 3
    var mood = 3
    var stress = 3
    var hasSleep = false
    var sleepHours = 7.0
    var note = ""

    init() {}

    init(checkIn: WellnessCheckIn) {
        energy = checkIn.energy
        mood = checkIn.mood
        stress = checkIn.stress
        if let hours = checkIn.sleepHours {
            hasSleep = true
            sleepHours = hours
        }
        note = checkIn.note ?? ""
    }

    var resolvedSleepHours: Double? { hasSleep ? sleepHours : nil }
}

/// Qué se mide en el check-in, con textos neutros (sin género ni juicios).
enum WellnessMetric: CaseIterable {
    case energy
    case mood
    case stress

    var title: LocalizedStringResource {
        switch self {
        case .energy: "Energía"
        case .mood: "Ánimo"
        case .stress: "Estrés"
        }
    }

    var symbolName: String {
        switch self {
        case .energy: "bolt.fill"
        case .mood: "face.smiling"
        case .stress: "waveform.path.ecg"
        }
    }

    func label(for level: Int) -> LocalizedStringResource {
        let labels: [LocalizedStringResource] = switch self {
        case .energy: ["Sin energía", "Poca", "Normal", "Buena", "Mucha"]
        case .mood: ["Muy mal", "Mal", "Regular", "Bien", "Muy bien"]
        case .stress: ["Nada", "Poco", "Algo", "Bastante", "Mucho"]
        }
        let index = level - 1
        return labels.indices.contains(index) ? labels[index] : "—"
    }
}

extension WellnessValidationError {
    var userMessage: String {
        switch self {
        case .levelOutOfRange:
            String(localized: "Elige un valor del 1 al 5.")
        case .sleepOutOfRange:
            String(localized: "Las horas de sueño deben estar entre 0 y 24.")
        case .noteTooLong(let maxLength):
            String(localized: "La nota puede tener como máximo \(maxLength) caracteres.")
        }
    }
}

enum WellnessFormat {
    static func hours(_ value: Double) -> String {
        let number = value.formatted(.number.precision(.fractionLength(0...1)))
        return String(localized: "\(number) h")
    }

    static func average(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }

    static func dayTitle(_ day: LocalDay, calendar: Calendar = .current) -> String {
        guard let date = day.middayDate(in: calendar) else { return day.description }
        return date.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}
