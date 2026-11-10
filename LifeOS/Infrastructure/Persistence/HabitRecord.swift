import Foundation
import SwiftData

/// Hábito en SwiftData. `nonisolated` por D-012.
/// Los días de la semana se guardan como máscara de bits: domingo = 1,
/// lunes = 2, martes = 4… Todos los días = 127.
@Model
nonisolated final class HabitRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var symbolName: String
    var weekdayMask: Int
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(from habit: Habit) {
        id = habit.id
        name = habit.name
        symbolName = habit.symbolName
        weekdayMask = HabitRecord.mask(from: habit.weekdays)
        createdAt = habit.createdAt
        updatedAt = habit.updatedAt
        deletedAt = habit.deletedAt
    }

    func apply(_ habit: Habit) {
        name = habit.name
        symbolName = habit.symbolName
        weekdayMask = HabitRecord.mask(from: habit.weekdays)
        createdAt = habit.createdAt
        updatedAt = habit.updatedAt
        deletedAt = habit.deletedAt
    }

    func toDomain() throws -> Habit {
        try Habit(
            restoringID: id,
            name: name,
            symbolName: symbolName,
            weekdays: HabitRecord.weekdays(fromMask: weekdayMask),
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }

    static func mask(from weekdays: Set<Int>) -> Int {
        weekdays.reduce(0) { mask, weekday in mask | (1 << (weekday - 1)) }
    }

    static func weekdays(fromMask mask: Int) -> Set<Int> {
        Set((1...7).filter { mask & (1 << ($0 - 1)) != 0 })
    }
}

/// Registro diario de un hábito en SwiftData. `nonisolated` por D-012.
@Model
nonisolated final class HabitLogRecord {
    @Attribute(.unique) var id: UUID
    var habitID: UUID
    /// `LocalDay.storageValue`, por ejemplo 20261110.
    var dayValue: Int
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(from log: HabitLog) {
        id = log.id
        habitID = log.habitID
        dayValue = log.day.storageValue
        createdAt = log.createdAt
        updatedAt = log.updatedAt
        deletedAt = log.deletedAt
    }

    func apply(_ log: HabitLog) {
        updatedAt = log.updatedAt
        deletedAt = log.deletedAt
    }

    func toDomain() throws -> HabitLog {
        guard let day = LocalDay(storageValue: dayValue) else {
            throw HabitRecordError.invalidDay(dayValue)
        }
        return HabitLog(
            restoringID: id,
            habitID: habitID,
            day: day,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}

nonisolated enum HabitRecordError: Error, Equatable, Sendable {
    case invalidDay(Int)
}
