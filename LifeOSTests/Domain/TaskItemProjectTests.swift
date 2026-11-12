import XCTest
@testable import LifeOS

@MainActor
final class TaskItemProjectTests: XCTestCase {
    private let created = Date(timeIntervalSince1970: 1_800_000_000)

    func test_assign_changesProjectAndBumpsUpdatedAt() throws {
        let projectID = UUID()
        var task = try TaskItem(title: "Ensayo", now: created)

        task.assign(toProject: projectID, at: created.addingTimeInterval(60))

        XCTAssertEqual(task.projectID, projectID)
        XCTAssertEqual(task.updatedAt, created.addingTimeInterval(60))
    }

    func test_assign_sameProject_changesNothing() throws {
        let projectID = UUID()
        var task = try TaskItem(title: "Ensayo", projectID: projectID, now: created)
        let original = task

        task.assign(toProject: projectID, at: created.addingTimeInterval(60))

        XCTAssertEqual(task, original)
    }

    func test_repository_roundTripsProject() throws {
        let repository = try AppDependencies(inMemory: true).taskRepository
        let task = try TaskItem(title: "Con proyecto", projectID: UUID(), now: created)

        try repository.save(task)

        XCTAssertEqual(try repository.task(withID: task.id), task)
    }
}
