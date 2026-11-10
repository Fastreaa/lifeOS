import Foundation

/// Una tarea de LifeOS. Entidad de dominio: Swift puro, sin SwiftData ni SwiftUI.
///
/// Todas las propiedades son de solo lectura desde fuera. Cualquier cambio pasa
/// por un método que valida los datos y actualiza `updatedAt`, de modo que esas
/// reglas no se pueden saltar.
nonisolated struct TaskItem: Identifiable, Equatable, Sendable {
    static let maxTitleLength = 200
    static let estimatedMinutesRange = 5...1440

    let id: UUID
    private(set) var title: String
    private(set) var notes: String?
    private(set) var priority: TaskPriority
    /// Momento límite. Puede estar en el pasado: la app no lo impide ni lo castiga.
    private(set) var dueDate: Date?
    private(set) var estimatedMinutes: Int?
    private(set) var completedAt: Date?
    let createdAt: Date
    private(set) var updatedAt: Date
    /// Borrado lógico: la tarea se oculta, pero el registro se conserva
    /// para poder sincronizar el borrado con otros dispositivos.
    private(set) var deletedAt: Date?

    var isCompleted: Bool { completedAt != nil }
    var isDeleted: Bool { deletedAt != nil }

    // MARK: - Creación

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        estimatedMinutes: Int? = nil,
        now: Date = .now
    ) throws {
        self.id = id
        self.title = try Self.validatedTitle(title)
        self.notes = Self.normalizedNotes(notes)
        self.priority = priority
        self.dueDate = dueDate
        self.estimatedMinutes = try Self.validatedEstimate(estimatedMinutes)
        self.completedAt = nil
        self.createdAt = now
        self.updatedAt = now
        self.deletedAt = nil
    }

    // MARK: - Reconstrucción

    /// Reconstruye una tarea existente a partir de datos guardados.
    /// Vuelve a aplicar las reglas: si los datos almacenados no las cumplen,
    /// lanza un error en lugar de cargar una tarea inválida.
    init(
        restoringID id: UUID,
        title: String,
        notes: String?,
        priority: TaskPriority,
        dueDate: Date?,
        estimatedMinutes: Int?,
        completedAt: Date?,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date?
    ) throws {
        self.id = id
        self.title = try Self.validatedTitle(title)
        self.notes = Self.normalizedNotes(notes)
        self.priority = priority
        self.dueDate = dueDate
        self.estimatedMinutes = try Self.validatedEstimate(estimatedMinutes)
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    // MARK: - Cambios

    /// Reemplaza los campos editables. Si algún dato es inválido, lanza un
    /// error y la tarea queda exactamente como estaba.
    mutating func update(
        title: String,
        notes: String?,
        priority: TaskPriority,
        dueDate: Date?,
        estimatedMinutes: Int?,
        now: Date = .now
    ) throws {
        let validTitle = try Self.validatedTitle(title)
        let validEstimate = try Self.validatedEstimate(estimatedMinutes)

        self.title = validTitle
        self.notes = Self.normalizedNotes(notes)
        self.priority = priority
        self.dueDate = dueDate
        self.estimatedMinutes = validEstimate
        self.updatedAt = now
    }

    /// Marca la tarea como completada. Si ya lo estaba, no cambia nada.
    mutating func complete(at now: Date = .now) {
        guard completedAt == nil else { return }
        completedAt = now
        updatedAt = now
    }

    /// Vuelve a marcar la tarea como pendiente. Si ya lo estaba, no cambia nada.
    mutating func reopen(at now: Date = .now) {
        guard completedAt != nil else { return }
        completedAt = nil
        updatedAt = now
    }

    /// Borrado lógico. Si ya estaba borrada, no cambia nada.
    mutating func markDeleted(at now: Date = .now) {
        guard deletedAt == nil else { return }
        deletedAt = now
        updatedAt = now
    }

    // MARK: - Reglas

    private static func validatedTitle(_ title: String) throws -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw TaskValidationError.emptyTitle
        }
        guard trimmed.count <= maxTitleLength else {
            throw TaskValidationError.titleTooLong(maxLength: maxTitleLength)
        }
        return trimmed
    }

    private static func validatedEstimate(_ minutes: Int?) throws -> Int? {
        guard let minutes else { return nil }
        guard estimatedMinutesRange.contains(minutes) else {
            throw TaskValidationError.estimateOutOfRange(estimatedMinutesRange)
        }
        return minutes
    }

    private static func normalizedNotes(_ notes: String?) -> String? {
        guard let trimmed = notes?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
