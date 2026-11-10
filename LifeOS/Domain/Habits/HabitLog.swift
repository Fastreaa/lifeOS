import Foundation

/// Registro de que un hábito se cumplió un día concreto.
///
/// Desmarcar no borra el registro: lo marca como borrado, igual que las
/// tareas, para poder sincronizar el cambio más adelante.
nonisolated struct HabitLog: Identifiable, Equatable, Sendable {
    let id: UUID
    let habitID: UUID
    let day: LocalDay
    let createdAt: Date
    private(set) var updatedAt: Date
    private(set) var deletedAt: Date?

    var isActive: Bool { deletedAt == nil }

    init(id: UUID = UUID(), habitID: UUID, day: LocalDay, now: Date = .now) {
        self.id = id
        self.habitID = habitID
        self.day = day
        self.createdAt = now
        self.updatedAt = now
        self.deletedAt = nil
    }

    init(
        restoringID id: UUID,
        habitID: UUID,
        day: LocalDay,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date?
    ) {
        self.id = id
        self.habitID = habitID
        self.day = day
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    mutating func markDeleted(at now: Date = .now) {
        guard deletedAt == nil else { return }
        deletedAt = now
        updatedAt = now
    }

    mutating func restore(at now: Date = .now) {
        guard deletedAt != nil else { return }
        deletedAt = nil
        updatedAt = now
    }
}
