#if DEBUG
import Foundation

/// Repositorio en memoria para las vistas previas. Solo en desarrollo.
nonisolated final class PreviewProjectRepository: ProjectRepository {
    private var storage: [UUID: Project] = [:]

    init(projects: [Project] = []) {
        for project in projects { storage[project.id] = project }
    }

    @MainActor
    func fetchProjects() throws -> [Project] {
        storage.values.filter { !$0.isDeleted }.sorted { $0.createdAt < $1.createdAt }
    }

    @MainActor
    func save(_ project: Project) throws {
        storage[project.id] = project
    }
}
#endif
