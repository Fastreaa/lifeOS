import Foundation

/// Estado editable del formulario de hábitos.
struct HabitDraft: Equatable {
    var name = ""
    var symbolName = HabitSymbol.defaultName
    var weekdays: Set<Int> = Habit.allWeekdays

    init() {}

    init(habit: Habit) {
        name = habit.name
        symbolName = habit.symbolName
        weekdays = habit.weekdays
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !weekdays.isEmpty
    }
}

/// Iconos disponibles para los hábitos, con su nombre para VoiceOver.
struct HabitSymbol: Identifiable {
    let name: String
    let label: LocalizedStringResource
    var id: String { name }

    static let defaultName = "star"

    static let all: [HabitSymbol] = [
        HabitSymbol(name: "star", label: "Estrella"),
        HabitSymbol(name: "figure.walk", label: "Caminar"),
        HabitSymbol(name: "dumbbell", label: "Ejercicio"),
        HabitSymbol(name: "book", label: "Leer"),
        HabitSymbol(name: "drop", label: "Agua"),
        HabitSymbol(name: "bed.double", label: "Dormir"),
        HabitSymbol(name: "figure.mind.and.body", label: "Meditar"),
        HabitSymbol(name: "fork.knife", label: "Comer bien"),
        HabitSymbol(name: "pencil", label: "Escribir"),
        HabitSymbol(name: "music.note", label: "Música"),
        HabitSymbol(name: "leaf", label: "Naturaleza"),
        HabitSymbol(name: "heart", label: "Cuidarme"),
    ]
}

extension HabitValidationError {
    /// Mensaje para mostrar al usuario: dice qué hacer, sin culpar.
    var userMessage: String {
        switch self {
        case .emptyName:
            String(localized: "Escribe un nombre para el hábito.")
        case .nameTooLong(let maxLength):
            String(localized: "El nombre puede tener como máximo \(maxLength) caracteres.")
        case .missingSymbol:
            String(localized: "Elige un icono.")
        case .noWeekdays:
            String(localized: "Elige al menos un día de la semana.")
        case .invalidWeekday:
            String(localized: "Hay un día de la semana no válido.")
        }
    }
}
