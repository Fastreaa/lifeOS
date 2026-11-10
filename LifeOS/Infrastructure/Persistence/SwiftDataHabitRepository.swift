import Foundation
import SwiftData

/// Implementación de `HabitRepository` con SwiftData.
/// Mismo diseño que `SwiftDataTaskRepository` (D-009, D-012).
nonisolated final class SwiftDataHabitRepository: HabitRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    @MainActor
    private var context: ModelContext { container.mainContext }

    // MARK: - Hábitos

    @MainActor
    func fetchHabits() throws -> [Habit] {
        let descriptor = FetchDescriptor<HabitRecord>(
            predicate: #Predicate { $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor).map { try $0.toDomain() }
    }

    @MainActor
    func save(_ habit: Habit) throws {
        let id = habit.id
        var descriptor = FetchDescriptor<HabitRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.apply(habit)
        } else {
            context.insert(HabitRecord(from: habit))
        }
        try context.save()
    }

    // MARK: - Registros

    @MainActor
    func fetchLogs(since day: LocalDay) throws -> [HabitLog] {
        let start = day.storageValue
        let descriptor = FetchDescriptor<HabitLogRecord>(
            predicate: #Predicate { $0.deletedAt == nil && $0.dayValue >= start }
        )
        return try context.fetch(descriptor).map { try $0.toDomain() }
    }

    @MainActor
    func log(habitID: UUID, day: LocalDay) throws -> HabitLog? {
        let value = day.storageValue
        var descriptor = FetchDescriptor<HabitLogRecord>(
            predicate: #Predicate { $0.habitID == habitID && $0.dayValue == value }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.toDomain()
    }

    @MainActor
    func save(_ log: HabitLog) throws {
        let id = log.id
        var descriptor = FetchDescriptor<HabitLogRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.apply(log)
        } else {
            context.insert(HabitLogRecord(from: log))
        }
        try context.save()
    }
}
