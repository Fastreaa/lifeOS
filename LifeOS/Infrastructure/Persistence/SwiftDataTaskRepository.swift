import Foundation
import SwiftData

/// Implementación de `TaskRepository` con SwiftData.
///
/// La clase es `nonisolated` para que su `deinit` sea normal y no aislado
/// (ver D-012). Los métodos que usan la base de datos sí son `@MainActor`,
/// porque trabajan con el contexto principal.
nonisolated final class SwiftDataTaskRepository: TaskRepository {
    /// Se guarda el contenedor, no solo el contexto: así la base de datos vive
    /// exactamente lo mismo que el repositorio, sin depender de quien lo creó.
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    @MainActor
    private var context: ModelContext { container.mainContext }

    @MainActor
    func fetchTasks() throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskRecord>(
            predicate: #Predicate { $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor).map { try $0.toDomain() }
    }

    @MainActor
    func task(withID id: UUID) throws -> TaskItem? {
        try record(withID: id)?.toDomain()
    }

    @MainActor
    func save(_ task: TaskItem) throws {
        if let existing = try record(withID: task.id) {
            existing.apply(task)
        } else {
            context.insert(TaskRecord(from: task))
        }
        try context.save()
    }

    @MainActor
    private func record(withID id: UUID) throws -> TaskRecord? {
        var descriptor = FetchDescriptor<TaskRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
