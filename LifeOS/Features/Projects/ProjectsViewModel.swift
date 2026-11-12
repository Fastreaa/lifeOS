import Foundation
import Observation

/// Lista de proyectos y acciones sobre ellos. El progreso de cada proyecto se
/// calcula con las tareas de `TaskListViewModel`.
@Observable
final class ProjectsViewModel {
    private(set) var projects: [Project] = []
    private(set) var errorMessage: String?

    private let repository: any ProjectRepository
    private let taskRepository: any TaskRepository
    private let now: () -> Date

    init(
        repository: any ProjectRepository,
        taskRepository: any TaskRepository,
        now: @escaping () -> Date = { Date() }
    ) {
        self.repository = repository
        self.taskRepository = taskRepository
        self.now = now
    }

    /// Ver D-013.
    nonisolated deinit {}

    var isEmpty: Bool { projects.isEmpty }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    func project(withID id: UUID?) -> Project? {
        guard let id else { return nil }
        return projects.first { $0.id == id }
    }

    // MARK: - Acciones

    func load() {
        do {
            projects = try repository.fetchProjects()
        } catch {
            errorMessage = String(localized: "No se pudieron cargar tus proyectos.")
        }
    }

    func create(_ draft: ProjectDraft) throws {
        let project = try Project(
            name: draft.name,
            symbolName: draft.symbolName,
            color: draft.color,
            now: now()
        )
        try repository.save(project)
        load()
    }

    func update(_ project: Project, with draft: ProjectDraft) throws {
        var updated = project
        try updated.update(name: draft.name, symbolName: draft.symbolName, color: draft.color, now: now())
        try repository.save(updated)
        load()
    }

    /// Borra el proyecto. Sus tareas no se borran: quedan sin proyecto.
    /// Después, quien lo llame debe recargar la lista de tareas.
    func delete(_ project: Project) {
        let timestamp = now()
        var deleted = project
        deleted.markDeleted(at: timestamp)
        do {
            for var task in try taskRepository.fetchTasks() where task.projectID == project.id {
                task.assign(toProject: nil, at: timestamp)
                try taskRepository.save(task)
            }
            try repository.save(deleted)
            load()
        } catch {
            errorMessage = String(localized: "No se pudo borrar el proyecto. Inténtalo de nuevo.")
        }
    }
}
