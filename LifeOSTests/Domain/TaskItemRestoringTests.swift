import XCTest
@testable import LifeOS

@MainActor
final class TaskItemRestoringTests: XCTestCase {
    private let created = Date(timeIntervalSince1970: 1_800_000_000)

    private func restore(
        title: String = "Tarea guardada",
        estimatedMinutes: Int? = nil
    ) throws -> TaskItem {
        try TaskItem(
            restoringID: UUID(),
            title: title,
            notes: nil,
            priority: .low,
            dueDate: nil,
            estimatedMinutes: estimatedMinutes,
            completedAt: created.addingTimeInterval(120),
            createdAt: created,
            updatedAt: created.addingTimeInterval(120),
            deletedAt: nil
        )
    }

    func test_restoring_keepsStoredTimestampsAndState() throws {
        let task = try restore()

        XCTAssertEqual(task.createdAt, created)
        XCTAssertEqual(task.updatedAt, created.addingTimeInterval(120))
        XCTAssertTrue(task.isCompleted)
        XCTAssertEqual(task.priority, .low)
    }

    func test_restoring_revalidatesTitle() {
        XCTAssertThrowsError(try restore(title: "  ")) { error in
            XCTAssertEqual(error as? TaskValidationError, .emptyTitle)
        }
    }

    func test_restoring_revalidatesEstimate() {
        XCTAssertThrowsError(try restore(estimatedMinutes: 2))
    }
}
