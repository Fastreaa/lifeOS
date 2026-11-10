import Foundation
import SwiftData

/// Implementación de `TaskRepository` con SwiftData.
final class SwiftDataTaskRepository: TaskRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchTasks() throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskRecord>(
            predicate: #Predicate { $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor).map { try $0.toDomain() }
    }

    func task(withID id: UUID) throws -> TaskItem? {
        try record(withID: id)?.toDomain()
    }

    func save(_ task: TaskItem) throws {
        if let existing = try record(withID: task.id) {
            existing.apply(task)
        } else {
            context.insert(TaskRecord(from: task))
        }
        try context.save()
    }

    private func record(withID id: UUID) throws -> TaskRecord? {
        var descriptor = FetchDescriptor<TaskRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
