import Foundation

/// Estado editable del formulario de tareas. Puede contener datos inválidos
/// mientras el usuario escribe; la validación real la hace `TaskItem` al guardar.
struct TaskDraft: Equatable {
    var title = ""
    var notes = ""
    var priority: TaskPriority = .medium
    var hasDueDate = false
    var dueDate = TaskDraft.defaultDueDate()
    var hasEstimate = false
    var estimatedMinutes = 30
    var projectID: UUID?

    init() {}

    /// Tarea nueva ya asignada a un proyecto.
    init(projectID: UUID?) {
        self.projectID = projectID
    }

    init(task: TaskItem) {
        title = task.title
        notes = task.notes ?? ""
        priority = task.priority
        projectID = task.projectID
        if let due = task.dueDate {
            hasDueDate = true
            dueDate = due
        }
        if let minutes = task.estimatedMinutes {
            hasEstimate = true
            estimatedMinutes = minutes
        }
    }

    var resolvedDueDate: Date? { hasDueDate ? dueDate : nil }
    var resolvedEstimate: Int? { hasEstimate ? estimatedMinutes : nil }

    /// Solo controla el botón Guardar; no sustituye la validación del dominio.
    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Hoy a las 23:59: un valor razonable al activar la fecha límite.
    static func defaultDueDate(now: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: 23, minute: 59, second: 0, of: now) ?? now
    }
}
