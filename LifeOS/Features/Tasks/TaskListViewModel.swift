import Foundation
import Observation

/// Estado de la lista de tareas y acciones sobre ella. Las vistas no hablan
/// con el repositorio directamente: todo pasa por aquí.
@Observable
final class TaskListViewModel {
    private(set) var pendingTasks: [TaskItem] = []
    private(set) var completedTasks: [TaskItem] = []
    private(set) var errorMessage: String?
    /// Última tarea borrada, mientras se puede deshacer.
    private(set) var recentlyDeleted: TaskItem?
    /// Texto de búsqueda. Filtra por título y notas.
    var searchText = ""

    private let repository: any TaskRepository
    private let now: () -> Date

    /// - Parameter now: fuente de la hora actual; las pruebas pasan una fija.
    init(repository: any TaskRepository, now: @escaping () -> Date = { Date() }) {
        self.repository = repository
        self.now = now
    }

    /// Deinit explícitamente no aislado (ver D-013). Sin esta línea, el modo
    /// MainActor por defecto lo vuelve aislado y el runtime de Swift 6.2.3
    /// puede cerrarse con SIGABRT al liberar el ViewModel.
    nonisolated deinit {}

    // MARK: - Estado derivado

    var isEmpty: Bool { pendingTasks.isEmpty && completedTasks.isEmpty }

    var isSearching: Bool { !searchQuery.isEmpty }

    var visiblePendingTasks: [TaskItem] { matchingSearch(pendingTasks) }
    var visibleCompletedTasks: [TaskItem] { matchingSearch(completedTasks) }

    var hasNoSearchResults: Bool {
        isSearching && visiblePendingTasks.isEmpty && visibleCompletedTasks.isEmpty
    }

    /// Permite enlazar la alerta de error con `$viewModel.isShowingError`.
    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    func summary(at date: Date, calendar: Calendar = .current) -> DaySummary {
        DaySummary(pending: pendingTasks, now: date, calendar: calendar)
    }

    /// Todas las tareas visibles (pendientes y completadas).
    var allTasks: [TaskItem] { pendingTasks + completedTasks }

    /// Pendientes de un proyecto, con el mismo orden que la lista general.
    func pendingTasks(inProject projectID: UUID) -> [TaskItem] {
        pendingTasks.filter { $0.projectID == projectID }
    }

    /// Completadas de un proyecto, la más reciente arriba.
    func completedTasks(inProject projectID: UUID) -> [TaskItem] {
        completedTasks.filter { $0.projectID == projectID }
    }

    // MARK: - Acciones

    func load() {
        do {
            let tasks = try repository.fetchTasks()
            pendingTasks = Self.sortedPending(tasks.filter { !$0.isCompleted })
            completedTasks = Self.sortedCompleted(tasks.filter(\.isCompleted))
        } catch {
            errorMessage = String(localized: "No se pudieron cargar tus tareas.")
        }
    }

    /// Lanza el error para que el formulario lo muestre junto a los campos.
    func create(_ draft: TaskDraft) throws {
        let task = try TaskItem(
            title: draft.title,
            notes: draft.notes,
            priority: draft.priority,
            dueDate: draft.resolvedDueDate,
            estimatedMinutes: draft.resolvedEstimate,
            projectID: draft.projectID,
            now: now()
        )
        try repository.save(task)
        load()
    }

    /// Lanza el error para que el formulario lo muestre junto a los campos.
    func update(_ task: TaskItem, with draft: TaskDraft) throws {
        var updated = task
        try updated.update(
            title: draft.title,
            notes: draft.notes,
            priority: draft.priority,
            dueDate: draft.resolvedDueDate,
            estimatedMinutes: draft.resolvedEstimate,
            now: now()
        )
        updated.assign(toProject: draft.projectID, at: now())
        try repository.save(updated)
        load()
    }

    func toggleCompletion(of task: TaskItem) {
        var updated = task
        if updated.isCompleted {
            updated.reopen(at: now())
        } else {
            updated.complete(at: now())
        }
        persist(updated)
    }

    func delete(_ task: TaskItem) {
        var updated = task
        updated.markDeleted(at: now())
        if persist(updated) {
            recentlyDeleted = updated
        }
    }

    /// Restaura la última tarea borrada.
    func undoDelete() {
        guard var task = recentlyDeleted else { return }
        recentlyDeleted = nil
        task.restore(at: now())
        persist(task)
    }

    /// Cierra el aviso de deshacer; la tarea sigue borrada.
    func dismissUndo() {
        recentlyDeleted = nil
    }

    // MARK: - Privado

    private var searchQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Ignora mayúsculas y acentos: "calculo" encuentra "Cálculo".
    private func matchingSearch(_ tasks: [TaskItem]) -> [TaskItem] {
        let query = searchQuery
        guard !query.isEmpty else { return tasks }
        return tasks.filter { task in
            task.title.localizedStandardContains(query)
                || (task.notes?.localizedStandardContains(query) ?? false)
        }
    }

    @discardableResult
    private func persist(_ task: TaskItem) -> Bool {
        do {
            try repository.save(task)
            load()
            return true
        } catch {
            errorMessage = String(localized: "No se pudo guardar el cambio. Inténtalo de nuevo.")
            return false
        }
    }

    /// Pendientes: primero las que tienen fecha límite (la más próxima arriba),
    /// luego mayor prioridad, luego las más antiguas.
    static func sortedPending(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks.sorted { a, b in
            switch (a.dueDate, b.dueDate) {
            case let (dueA?, dueB?) where dueA != dueB:
                return dueA < dueB
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            default:
                break
            }
            if a.priority != b.priority {
                return a.priority > b.priority
            }
            return a.createdAt < b.createdAt
        }
    }

    /// Completadas: la más reciente arriba.
    static func sortedCompleted(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks.sorted {
            ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast)
        }
    }
}
