import Foundation

/// Motivos por los que un hábito no cumple las reglas del dominio.
nonisolated enum HabitValidationError: Error, Equatable, Sendable {
    case emptyName
    case nameTooLong(maxLength: Int)
    case missingSymbol
    case noWeekdays
    case invalidWeekday(Int)
}

/// Un hábito: algo que quieres hacer ciertos días de la semana.
/// Entidad de dominio: Swift puro, mismas reglas de diseño que `TaskItem`.
nonisolated struct Habit: Identifiable, Equatable, Sendable {
    static let maxNameLength = 60
    /// Días según `Calendar`: 1 = domingo … 7 = sábado.
    static let allWeekdays: Set<Int> = Set(1...7)

    let id: UUID
    private(set) var name: String
    /// Nombre de un SF Symbol, por ejemplo "book".
    private(set) var symbolName: String
    private(set) var weekdays: Set<Int>
    let createdAt: Date
    private(set) var updatedAt: Date
    private(set) var deletedAt: Date?

    var isDaily: Bool { weekdays == Self.allWeekdays }
    var isDeleted: Bool { deletedAt != nil }

    // MARK: - Creación y reconstrucción

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String = "star",
        weekdays: Set<Int> = Habit.allWeekdays,
        now: Date = .now
    ) throws {
        self.id = id
        self.name = try Self.validatedName(name)
        self.symbolName = try Self.validatedSymbol(symbolName)
        self.weekdays = try Self.validatedWeekdays(weekdays)
        self.createdAt = now
        self.updatedAt = now
        self.deletedAt = nil
    }

    /// Reconstruye un hábito guardado, revalidando sus datos.
    init(
        restoringID id: UUID,
        name: String,
        symbolName: String,
        weekdays: Set<Int>,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date?
    ) throws {
        self.id = id
        self.name = try Self.validatedName(name)
        self.symbolName = try Self.validatedSymbol(symbolName)
        self.weekdays = try Self.validatedWeekdays(weekdays)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    // MARK: - Cambios

    /// Si algún dato es inválido, lanza un error y el hábito no cambia.
    mutating func update(
        name: String,
        symbolName: String,
        weekdays: Set<Int>,
        now: Date = .now
    ) throws {
        let validName = try Self.validatedName(name)
        let validSymbol = try Self.validatedSymbol(symbolName)
        let validWeekdays = try Self.validatedWeekdays(weekdays)

        self.name = validName
        self.symbolName = validSymbol
        self.weekdays = validWeekdays
        self.updatedAt = now
    }

    /// Borrado lógico. Si ya estaba borrado, no cambia nada.
    mutating func markDeleted(at now: Date = .now) {
        guard deletedAt == nil else { return }
        deletedAt = now
        updatedAt = now
    }

    /// ¿Toca este hábito ese día?
    func isScheduled(on day: LocalDay, calendar: Calendar) -> Bool {
        guard let weekday = day.weekday(in: calendar) else { return false }
        return weekdays.contains(weekday)
    }

    // MARK: - Reglas

    private static func validatedName(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw HabitValidationError.emptyName }
        guard trimmed.count <= maxNameLength else {
            throw HabitValidationError.nameTooLong(maxLength: maxNameLength)
        }
        return trimmed
    }

    private static func validatedSymbol(_ symbol: String) throws -> String {
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw HabitValidationError.missingSymbol }
        return trimmed
    }

    private static func validatedWeekdays(_ weekdays: Set<Int>) throws -> Set<Int> {
        guard !weekdays.isEmpty else { throw HabitValidationError.noWeekdays }
        if let invalid = weekdays.sorted().first(where: { !allWeekdays.contains($0) }) {
            throw HabitValidationError.invalidWeekday(invalid)
        }
        return weekdays
    }
}
