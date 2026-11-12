import XCTest
@testable import LifeOS

@MainActor
final class ProjectsViewModelTests: XCTestCase {
    private func makeSUT() throws -> (ProjectsViewModel, TaskListViewModel, any TaskRepository) {
        let dependencies = try AppDependencies(inMemory: true)
        let projects = ProjectsViewModel(
            repository: dependencies.projectRepository,
            taskRepository: dependencies.taskRepository
        )
        let tasks = TaskListViewModel(repository: dependencies.taskRepository)
        return (projects, tasks, dependencies.taskRepository)
    }

    private func projectDraft(_ name: String) -> ProjectDraft {
        var draft = ProjectDraft()
        draft.name = name
        return draft
    }

    private func taskDraft(_ title: String, projectID: UUID?) -> TaskDraft {
        var draft = TaskDraft(projectID: projectID)
        draft.title = title
        return draft
    }

    func test_create_addsProject() throws {
        let (projects, _, _) = try makeSUT()

        try projects.create(projectDraft("Universidad"))

        XCTAssertEqual(projects.projects.map(\.name), ["Universidad"])
    }

    func test_create_withBlankName_throws() throws {
        let (projects, _, _) = try makeSUT()

        XCTAssertThrowsError(try projects.create(projectDraft("  "))) {
            XCTAssertEqual($0 as? ProjectValidationError, .emptyName)
        }
        XCTAssertTrue(projects.isEmpty)
    }

    func test_tasksCanBeCreatedAndMovedBetweenProjects() throws {
        let (projects, tasks, _) = try makeSUT()
        try projects.create(projectDraft("Universidad"))
        try projects.create(projectDraft("Casa"))
        let university = try XCTUnwrap(projects.projects.first { $0.name == "Universidad" })
        let home = try XCTUnwrap(projects.projects.first { $0.name == "Casa" })

        try tasks.create(taskDraft("Ensayo", projectID: university.id))
        XCTAssertEqual(tasks.pendingTasks(inProject: university.id).map(\.title), ["Ensayo"])

        let task = try XCTUnwrap(tasks.pendingTasks.first)
        try tasks.update(task, with: taskDraft("Ensayo", projectID: home.id))

        XCTAssertTrue(tasks.pendingTasks(inProject: university.id).isEmpty)
        XCTAssertEqual(tasks.pendingTasks(inProject: home.id).map(\.title), ["Ensayo"])
    }

    func test_delete_keepsTasksWithoutProject() throws {
        let (projects, tasks, repository) = try makeSUT()
        try projects.create(projectDraft("Temporal"))
        let project = try XCTUnwrap(projects.projects.first)
        try tasks.create(taskDraft("Sigue viva", projectID: project.id))
        let task = try XCTUnwrap(tasks.pendingTasks.first)

        projects.delete(project)
        tasks.load()

        XCTAssertTrue(projects.isEmpty)
        XCTAssertEqual(tasks.pendingTasks.map(\.title), ["Sigue viva"])
        XCTAssertNil(try repository.task(withID: task.id)?.projectID)
    }
}
