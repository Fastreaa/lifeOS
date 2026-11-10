import XCTest
@testable import LifeOS

/// Búsqueda, deshacer y resumen del ViewModel.
@MainActor
final class TaskListViewModelPolishTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeSUT() throws -> (TaskListViewModel, any TaskRepository) {
        let repository = try AppDependencies(inMemory: true).taskRepository
        var time = start
        let viewModel = TaskListViewModel(repository: repository) {
            time = time.addingTimeInterval(60)
            return time
        }
        return (viewModel, repository)
    }

    private func draft(_ title: String, notes: String = "", dueDate: Date? = nil) -> TaskDraft {
        var draft = TaskDraft()
        draft.title = title
        draft.notes = notes
        if let dueDate {
            draft.hasDueDate = true
            draft.dueDate = dueDate
        }
        return draft
    }

    // MARK: - Búsqueda

    func test_search_ignoresCaseAndAccents() throws {
        let (viewModel, _) = try makeSUT()
        try viewModel.create(draft("Cálculo integral"))
        try viewModel.create(draft("Leer novela"))

        viewModel.searchText = "CALCULO"

        XCTAssertTrue(viewModel.isSearching)
        XCTAssertEqual(viewModel.visiblePendingTasks.map(\.title), ["Cálculo integral"])
    }

    func test_search_matchesNotes() throws {
        let (viewModel, _) = try makeSUT()
        try viewModel.create(draft("Proyecto", notes: "Reunión con el equipo"))
        try viewModel.create(draft("Otra cosa"))

        viewModel.searchText = "reunion"

        XCTAssertEqual(viewModel.visiblePendingTasks.map(\.title), ["Proyecto"])
    }

    func test_search_blankText_showsEverything() throws {
        let (viewModel, _) = try makeSUT()
        try viewModel.create(draft("Una"))
        try viewModel.create(draft("Dos"))

        viewModel.searchText = "   "

        XCTAssertFalse(viewModel.isSearching)
        XCTAssertEqual(viewModel.visiblePendingTasks.count, 2)
    }

    func test_search_withoutMatches_reportsNoResults() throws {
        let (viewModel, _) = try makeSUT()
        try viewModel.create(draft("Comprar pan"))

        viewModel.searchText = "gimnasio"

        XCTAssertTrue(viewModel.hasNoSearchResults)
        XCTAssertFalse(viewModel.isEmpty)
    }

    // MARK: - Deshacer

    func test_delete_thenUndo_restoresTask() throws {
        let (viewModel, repository) = try makeSUT()
        try viewModel.create(draft("Importante"))
        let task = try XCTUnwrap(viewModel.pendingTasks.first)

        viewModel.delete(task)
        XCTAssertEqual(viewModel.recentlyDeleted?.id, task.id)
        XCTAssertTrue(viewModel.isEmpty)

        viewModel.undoDelete()

        XCTAssertNil(viewModel.recentlyDeleted)
        XCTAssertEqual(viewModel.pendingTasks.map(\.title), ["Importante"])
        XCTAssertEqual(try repository.task(withID: task.id)?.isDeleted, false)
    }

    func test_dismissUndo_keepsTaskDeleted() throws {
        let (viewModel, repository) = try makeSUT()
        try viewModel.create(draft("Descartable"))
        let task = try XCTUnwrap(viewModel.pendingTasks.first)

        viewModel.delete(task)
        viewModel.dismissUndo()

        XCTAssertNil(viewModel.recentlyDeleted)
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertEqual(try repository.task(withID: task.id)?.isDeleted, true)
    }

    // MARK: - Resumen

    func test_summary_ignoresCompletedTasks() throws {
        let (viewModel, _) = try makeSUT()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let dueToday = start.addingTimeInterval(3_600)

        try viewModel.create(draft("Pendiente", dueDate: dueToday))
        try viewModel.create(draft("Hecha", dueDate: dueToday))
        let done = try XCTUnwrap(viewModel.pendingTasks.first { $0.title == "Hecha" })
        viewModel.toggleCompletion(of: done)

        let summary = viewModel.summary(at: start, calendar: calendar)

        XCTAssertEqual(summary.pendingCount, 1)
        XCTAssertEqual(summary.dueTodayCount, 1)
    }
}
