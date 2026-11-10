import XCTest
@testable import LifeOS

/// Pruebas del ViewModel contra la base de datos real de SwiftData, en memoria.
@MainActor
final class TaskListViewModelTests: XCTestCase {
    /// Devuelve el ViewModel y el repositorio que usa, para comprobar lo guardado.
    /// El reloj avanza un minuto en cada llamada, para que el orden sea predecible.
    private func makeSUT() throws -> (TaskListViewModel, any TaskRepository) {
        let repository = try AppDependencies(inMemory: true).taskRepository
        var time = Date(timeIntervalSince1970: 1_800_000_000)
        let viewModel = TaskListViewModel(repository: repository) {
            time = time.addingTimeInterval(60)
            return time
        }
        return (viewModel, repository)
    }

    private func draft(
        _ title: String,
        priority: TaskPriority = .medium,
        dueDate: Date? = nil
    ) -> TaskDraft {
        var draft = TaskDraft()
        draft.title = title
        draft.priority = priority
        if let dueDate {
            draft.hasDueDate = true
            draft.dueDate = dueDate
        }
        return draft
    }

    // MARK: - Carga y creación

    func test_load_onEmptyStore_isEmpty() throws {
        let (viewModel, _) = try makeSUT()

        viewModel.load()

        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertFalse(viewModel.isShowingError)
    }

    func test_create_addsTaskToPending() throws {
        let (viewModel, repository) = try makeSUT()

        try viewModel.create(draft("Entregar práctica"))

        XCTAssertEqual(viewModel.pendingTasks.map(\.title), ["Entregar práctica"])
        XCTAssertTrue(viewModel.completedTasks.isEmpty)
        XCTAssertEqual(try repository.fetchTasks().count, 1)
    }

    func test_create_withBlankTitle_throwsAndSavesNothing() throws {
        let (viewModel, repository) = try makeSUT()

        XCTAssertThrowsError(try viewModel.create(draft("   "))) { error in
            XCTAssertEqual(error as? TaskValidationError, .emptyTitle)
        }
        XCTAssertTrue(try repository.fetchTasks().isEmpty)
    }

    func test_tasks_persistForNewViewModel() throws {
        let (viewModel, repository) = try makeSUT()
        try viewModel.create(draft("Persistente"))

        let reopened = TaskListViewModel(repository: repository)
        reopened.load()

        XCTAssertEqual(reopened.pendingTasks.map(\.title), ["Persistente"])
    }

    // MARK: - Edición, completar y borrar

    func test_update_changesTask() throws {
        let (viewModel, repository) = try makeSUT()
        try viewModel.create(draft("Borrador"))
        let task = try XCTUnwrap(viewModel.pendingTasks.first)

        try viewModel.update(task, with: draft("Definitivo", priority: .high))

        XCTAssertEqual(viewModel.pendingTasks.map(\.title), ["Definitivo"])
        XCTAssertEqual(viewModel.pendingTasks.first?.priority, .high)
        XCTAssertEqual(try repository.fetchTasks().count, 1)
    }

    func test_toggleCompletion_movesTaskBetweenSections() throws {
        let (viewModel, _) = try makeSUT()
        try viewModel.create(draft("Lavar ropa"))
        let task = try XCTUnwrap(viewModel.pendingTasks.first)

        viewModel.toggleCompletion(of: task)
        XCTAssertTrue(viewModel.pendingTasks.isEmpty)
        XCTAssertEqual(viewModel.completedTasks.map(\.title), ["Lavar ropa"])

        let completed = try XCTUnwrap(viewModel.completedTasks.first)
        viewModel.toggleCompletion(of: completed)
        XCTAssertEqual(viewModel.pendingTasks.map(\.title), ["Lavar ropa"])
        XCTAssertTrue(viewModel.completedTasks.isEmpty)
    }

    func test_delete_removesTaskButKeepsRecord() throws {
        let (viewModel, repository) = try makeSUT()
        try viewModel.create(draft("Temporal"))
        let task = try XCTUnwrap(viewModel.pendingTasks.first)

        viewModel.delete(task)

        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertEqual(try repository.task(withID: task.id)?.isDeleted, true)
    }

    // MARK: - Orden

    func test_pending_sortedByDueDateThenPriority() throws {
        let (viewModel, _) = try makeSUT()
        let base = Date(timeIntervalSince1970: 1_900_000_000)

        try viewModel.create(draft("Sin fecha, baja", priority: .low))
        try viewModel.create(draft("Vence después", dueDate: base.addingTimeInterval(7_200)))
        try viewModel.create(draft("Sin fecha, alta", priority: .high))
        try viewModel.create(draft("Vence pronto", dueDate: base))

        XCTAssertEqual(
            viewModel.pendingTasks.map(\.title),
            ["Vence pronto", "Vence después", "Sin fecha, alta", "Sin fecha, baja"]
        )
    }

    func test_completed_mostRecentFirst() throws {
        let (viewModel, _) = try makeSUT()
        try viewModel.create(draft("Primera"))
        try viewModel.create(draft("Segunda"))

        for title in ["Primera", "Segunda"] {
            let task = try XCTUnwrap(viewModel.pendingTasks.first { $0.title == title })
            viewModel.toggleCompletion(of: task)
        }

        XCTAssertEqual(viewModel.completedTasks.map(\.title), ["Segunda", "Primera"])
    }
}
