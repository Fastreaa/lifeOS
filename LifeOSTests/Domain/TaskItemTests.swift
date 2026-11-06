import XCTest
@testable import LifeOS

@MainActor
final class TaskItemTests: XCTestCase {
    private let created = Date(timeIntervalSince1970: 1_800_000_000)
    private var later: Date { created.addingTimeInterval(60) }
    private var muchLater: Date { created.addingTimeInterval(3_600) }

    private func makeTask(title: String = "Estudiar cálculo") throws -> TaskItem {
        try TaskItem(title: title, now: created)
    }

    // MARK: - Creación

    func test_init_setsDefaultsAndTimestamps() throws {
        let task = try makeTask()

        XCTAssertEqual(task.title, "Estudiar cálculo")
        XCTAssertEqual(task.priority, .medium)
        XCTAssertEqual(task.createdAt, created)
        XCTAssertEqual(task.updatedAt, created)
        XCTAssertNil(task.notes)
        XCTAssertNil(task.dueDate)
        XCTAssertNil(task.estimatedMinutes)
        XCTAssertFalse(task.isCompleted)
        XCTAssertFalse(task.isDeleted)
    }

    func test_init_trimsTitle() throws {
        let task = try makeTask(title: "  Leer capítulo 3 \n")
        XCTAssertEqual(task.title, "Leer capítulo 3")
    }

    func test_init_generatesUniqueIDs() throws {
        XCTAssertNotEqual(try makeTask().id, try makeTask().id)
    }

    func test_init_rejectsEmptyOrBlankTitle() {
        for title in ["", "   ", "\n\t"] {
            XCTAssertThrowsError(try makeTask(title: title)) { error in
                XCTAssertEqual(error as? TaskValidationError, .emptyTitle)
            }
        }
    }

    func test_init_acceptsTitleAtMaxLength() {
        let title = String(repeating: "a", count: TaskItem.maxTitleLength)
        XCTAssertNoThrow(try makeTask(title: title))
    }

    func test_init_rejectsTitleOverMaxLength() {
        let title = String(repeating: "a", count: TaskItem.maxTitleLength + 1)
        XCTAssertThrowsError(try makeTask(title: title)) { error in
            XCTAssertEqual(
                error as? TaskValidationError,
                .titleTooLong(maxLength: TaskItem.maxTitleLength)
            )
        }
    }

    func test_init_acceptsEstimateAtBoundaries() {
        XCTAssertNoThrow(try TaskItem(title: "x", estimatedMinutes: 5, now: created))
        XCTAssertNoThrow(try TaskItem(title: "x", estimatedMinutes: 1440, now: created))
    }

    func test_init_rejectsEstimateOutsideRange() {
        for minutes in [-10, 0, 4, 1441] {
            XCTAssertThrowsError(
                try TaskItem(title: "x", estimatedMinutes: minutes, now: created)
            ) { error in
                XCTAssertEqual(
                    error as? TaskValidationError,
                    .estimateOutOfRange(TaskItem.estimatedMinutesRange)
                )
            }
        }
    }

    func test_init_blankNotesBecomeNil() throws {
        let task = try TaskItem(title: "x", notes: "   ", now: created)
        XCTAssertNil(task.notes)
    }

    func test_init_allowsPastDueDate() throws {
        let yesterday = created.addingTimeInterval(-86_400)
        let task = try TaskItem(title: "x", dueDate: yesterday, now: created)
        XCTAssertEqual(task.dueDate, yesterday)
    }

    // MARK: - Edición

    func test_update_changesFieldsAndBumpsUpdatedAt() throws {
        var task = try makeTask()
        let due = muchLater

        try task.update(
            title: " Repasar integrales ",
            notes: "Capítulos 4 y 5",
            priority: .high,
            dueDate: due,
            estimatedMinutes: 90,
            now: later
        )

        XCTAssertEqual(task.title, "Repasar integrales")
        XCTAssertEqual(task.notes, "Capítulos 4 y 5")
        XCTAssertEqual(task.priority, .high)
        XCTAssertEqual(task.dueDate, due)
        XCTAssertEqual(task.estimatedMinutes, 90)
        XCTAssertEqual(task.updatedAt, later)
        XCTAssertEqual(task.createdAt, created)
    }

    func test_update_withInvalidData_leavesTaskUnchanged() throws {
        var task = try makeTask()
        let original = task

        XCTAssertThrowsError(
            try task.update(title: "", notes: nil, priority: .high,
                            dueDate: nil, estimatedMinutes: nil, now: later)
        )
        XCTAssertThrowsError(
            try task.update(title: "Válido", notes: nil, priority: .high,
                            dueDate: nil, estimatedMinutes: 2, now: later)
        )
        XCTAssertEqual(task, original)
    }

    // MARK: - Completar y reabrir

    func test_complete_setsCompletedAtAndBumpsUpdatedAt() throws {
        var task = try makeTask()
        task.complete(at: later)

        XCTAssertTrue(task.isCompleted)
        XCTAssertEqual(task.completedAt, later)
        XCTAssertEqual(task.updatedAt, later)
    }

    func test_complete_twice_keepsFirstCompletionDate() throws {
        var task = try makeTask()
        task.complete(at: later)
        task.complete(at: muchLater)

        XCTAssertEqual(task.completedAt, later)
        XCTAssertEqual(task.updatedAt, later)
    }

    func test_reopen_clearsCompletion() throws {
        var task = try makeTask()
        task.complete(at: later)
        task.reopen(at: muchLater)

        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedAt)
        XCTAssertEqual(task.updatedAt, muchLater)
    }

    func test_reopen_onPendingTask_changesNothing() throws {
        var task = try makeTask()
        let original = task
        task.reopen(at: later)

        XCTAssertEqual(task, original)
    }

    // MARK: - Borrado lógico

    func test_markDeleted_setsDeletedAtAndKeepsData() throws {
        var task = try makeTask()
        task.markDeleted(at: later)

        XCTAssertTrue(task.isDeleted)
        XCTAssertEqual(task.deletedAt, later)
        XCTAssertEqual(task.updatedAt, later)
        XCTAssertEqual(task.title, "Estudiar cálculo")
    }

    func test_markDeleted_twice_keepsFirstDeletionDate() throws {
        var task = try makeTask()
        task.markDeleted(at: later)
        task.markDeleted(at: muchLater)

        XCTAssertEqual(task.deletedAt, later)
    }

    // MARK: - Prioridad

    func test_priority_isOrderedLowToHigh() {
        XCTAssertLessThan(TaskPriority.low, .medium)
        XCTAssertLessThan(TaskPriority.medium, .high)
        XCTAssertEqual(TaskPriority.allCases.sorted(), [.low, .medium, .high])
    }
}
