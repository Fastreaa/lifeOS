#if DEBUG
import Foundation

/// Repositorio en memoria para las vistas previas de Xcode. Solo existe en
/// compilaciones de desarrollo. `nonisolated` por el mismo motivo que el
/// repositorio real (ver D-012).
nonisolated final class PreviewTaskRepository: TaskRepository {
    private var storage: [UUID: TaskItem]

    init(tasks: [TaskItem] = []) {
        storage = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
    }

    @MainActor
    func fetchTasks() throws -> [TaskItem] {
        storage.values
            .filter { !$0.isDeleted }
            .sorted { $0.createdAt < $1.createdAt }
    }

    @MainActor
    func task(withID id: UUID) throws -> TaskItem? {
        storage[id]
    }

    @MainActor
    func save(_ task: TaskItem) throws {
        storage[task.id] = task
    }

    static var sample: PreviewTaskRepository {
        let tasks = [
            try? TaskItem(
                title: "Entregar práctica de iOS",
                priority: .high,
                dueDate: .now.addingTimeInterval(5 * 3_600),
                estimatedMinutes: 90
            ),
            try? TaskItem(title: "Leer capítulo 4", estimatedMinutes: 45),
            try? TaskItem(title: "Ir al gimnasio", priority: .low),
        ]
        return PreviewTaskRepository(tasks: tasks.compactMap { $0 })
    }
}
#endif
