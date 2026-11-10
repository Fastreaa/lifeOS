import Foundation
import SwiftData

/// Representación de una tarea en SwiftData. Solo la conoce Infrastructure;
/// el resto de la app trabaja con `TaskItem`.
///
/// `nonisolated`: su `deinit` no es aislado (ver D-012) y, en la etapa 03,
/// la sincronización podrá usarlo fuera del hilo principal.
@Model
nonisolated final class TaskRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String?
    var priorityRawValue: Int
    var dueDate: Date?
    var estimatedMinutes: Int?
    var completedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(from task: TaskItem) {
        id = task.id
        title = task.title
        notes = task.notes
        priorityRawValue = task.priority.rawValue
        dueDate = task.dueDate
        estimatedMinutes = task.estimatedMinutes
        completedAt = task.completedAt
        createdAt = task.createdAt
        updatedAt = task.updatedAt
        deletedAt = task.deletedAt
    }

    /// Copia en este registro el estado de la tarea. El id no cambia nunca.
    func apply(_ task: TaskItem) {
        title = task.title
        notes = task.notes
        priorityRawValue = task.priority.rawValue
        dueDate = task.dueDate
        estimatedMinutes = task.estimatedMinutes
        completedAt = task.completedAt
        createdAt = task.createdAt
        updatedAt = task.updatedAt
        deletedAt = task.deletedAt
    }

    /// Convierte el registro en entidad de dominio, revalidando sus datos.
    func toDomain() throws -> TaskItem {
        guard let priority = TaskPriority(rawValue: priorityRawValue) else {
            throw TaskRecordError.invalidPriority(priorityRawValue)
        }
        return try TaskItem(
            restoringID: id,
            title: title,
            notes: notes,
            priority: priority,
            dueDate: dueDate,
            estimatedMinutes: estimatedMinutes,
            completedAt: completedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}

/// Datos guardados que no se pueden convertir en una tarea válida.
nonisolated enum TaskRecordError: Error, Equatable, Sendable {
    case invalidPriority(Int)
}
