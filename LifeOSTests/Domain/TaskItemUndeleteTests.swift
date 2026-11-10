import XCTest
@testable import LifeOS

@MainActor
final class TaskItemUndeleteTests: XCTestCase {
    private let created = Date(timeIntervalSince1970: 1_800_000_000)

    func test_restore_clearsDeletionAndBumpsUpdatedAt() throws {
        var task = try TaskItem(title: "Recuperable", now: created)
        task.markDeleted(at: created.addingTimeInterval(60))

        task.restore(at: created.addingTimeInterval(120))

        XCTAssertFalse(task.isDeleted)
        XCTAssertNil(task.deletedAt)
        XCTAssertEqual(task.updatedAt, created.addingTimeInterval(120))
    }

    func test_restore_onActiveTask_changesNothing() throws {
        var task = try TaskItem(title: "Activa", now: created)
        let original = task

        task.restore(at: created.addingTimeInterval(60))

        XCTAssertEqual(task, original)
    }
}
