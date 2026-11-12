import Foundation
import SwiftData

/// Implementación de `ProjectRepository` con SwiftData (D-009, D-012).
nonisolated final class SwiftDataProjectRepository: ProjectRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    @MainActor
    private var context: ModelContext { container.mainContext }

    @MainActor
    func fetchProjects() throws -> [Project] {
        let descriptor = FetchDescriptor<ProjectRecord>(
            predicate: #Predicate { $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor).map { try $0.toDomain() }
    }

    @MainActor
    func save(_ project: Project) throws {
        let id = project.id
        var descriptor = FetchDescriptor<ProjectRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.apply(project)
        } else {
            context.insert(ProjectRecord(from: project))
        }
        try context.save()
    }
}
