import SwiftUI

/// Estado editable del formulario de bloques. Las horas se guardan como `Date`
/// para usarlas directamente con `DatePicker`; solo importa la hora.
struct BlockDraft: Equatable {
    var title = ""
    var kind: BlockKind = .study
    var start: Date
    var end: Date

    /// Por defecto: de la próxima hora en punto a una hora después.
    init(defaultStart: Date = .now, calendar: Calendar = .current) {
        let nextHour = min(calendar.component(.hour, from: defaultStart) + 1, 22)
        let start = calendar.date(bySettingHour: nextHour, minute: 0, second: 0, of: defaultStart) ?? defaultStart
        self.start = start
        self.end = start.addingTimeInterval(3_600)
    }

    init(block: TimeBlock, calendar: Calendar = .current) {
        title = block.title
        kind = block.kind
        start = MinuteOfDay.date(block.startMinute, on: block.day, calendar: calendar) ?? .now
        end = MinuteOfDay.date(block.endMinute, on: block.day, calendar: calendar) ?? .now
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension BlockKind {
    var label: LocalizedStringResource {
        switch self {
        case .classSession: "Clase"
        case .work: "Trabajo"
        case .study: "Estudio"
        case .exercise: "Ejercicio"
        case .rest: "Descanso"
        case .personal: "Personal"
        case .other: "Otro"
        }
    }

    var symbolName: String {
        switch self {
        case .classSession: "graduationcap"
        case .work: "briefcase"
        case .study: "book"
        case .exercise: "figure.run"
        case .rest: "cup.and.saucer"
        case .personal: "person"
        case .other: "square.grid.2x2"
        }
    }

    var color: Color {
        switch self {
        case .classSession: .lifeTasks
        case .work: .indigo
        case .study: .lifeAccent
        case .exercise: .lifeHabits
        case .rest: .mint
        case .personal: .pink
        case .other: .gray
        }
    }
}

extension TimeBlockValidationError {
    var userMessage: String {
        switch self {
        case .emptyTitle:
            String(localized: "Escribe un título para el bloque.")
        case .titleTooLong(let maxLength):
            String(localized: "El título puede tener como máximo \(maxLength) caracteres.")
        case .invalidTimeRange:
            String(localized: "La hora de fin debe ser posterior a la de inicio.")
        case .tooShort(let minimum):
            String(localized: "Un bloque debe durar al menos \(minimum) minutos.")
        }
    }
}

enum AgendaFormat {
    static func time(_ minute: Int, on day: LocalDay, calendar: Calendar = .current) -> String {
        guard let date = MinuteOfDay.date(minute, on: day, calendar: calendar) else { return "" }
        return date.formatted(date: .omitted, time: .shortened)
    }

    static func duration(_ minutes: Int) -> String {
        Duration.seconds(minutes * 60)
            .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    static func dayTitle(_ day: LocalDay, today: LocalDay, calendar: Calendar = .current) -> String {
        if day == today { return String(localized: "Hoy") }
        if day == today.adding(days: 1, calendar: calendar) { return String(localized: "Mañana") }
        if day == today.adding(days: -1, calendar: calendar) { return String(localized: "Ayer") }
        guard let date = day.middayDate(in: calendar) else { return day.description }
        return date.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}
