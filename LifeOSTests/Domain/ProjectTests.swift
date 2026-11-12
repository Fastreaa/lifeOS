import XCTest
@testable import LifeOS

@MainActor
final class ProjectTests: XCTestCase {
    private let created = Date(timeIntervalSince1970: 1_800_000_000)

    func test_init_trimsNameAndUsesDefaults() throws {
        let project = try Project(name: "  Universidad  ", now: created)

        XCTAssertEqual(project.name, "Universidad")
        XCTAssertEqual(project.symbolName, "folder")
        XCTAssertEqual(project.color, .teal)
    }

    func test_init_rejectsInvalidData() {
        XCTAssertThrowsError(try Project(name: "  ", now: created)) {
            XCTAssertEqual($0 as? ProjectValidationError, .emptyName)
        }
        XCTAssertThrowsError(try Project(name: String(repeating: "a", count: 41), now: created)) {
            XCTAssertEqual($0 as? ProjectValidationError, .nameTooLong(maxLength: 40))
        }
        XCTAssertThrowsError(try Project(name: "x", symbolName: " ", now: created)) {
            XCTAssertEqual($0 as? ProjectValidationError, .missingSymbol)
        }
    }

    func test_update_withInvalidName_leavesProjectUnchanged() throws {
        var project = try Project(name: "Casa", now: created)
        let original = project

        XCTAssertThrowsError(try project.update(name: "", symbolName: "house", color: .green, now: created))
        XCTAssertEqual(project, original)
    }

    func test_progress_countsOnlyTasksOfThatProject() throws {
        let projectID = UUID()
        var done = try TaskItem(title: "Hecha", estimatedMinutes: 30, projectID: projectID, now: created)
        done.complete(at: created)
        let tasks = [
            try TaskItem(title: "Pendiente", estimatedMinutes: 45, projectID: projectID, now: created),
            done,
            try TaskItem(title: "Otro proyecto", projectID: UUID(), now: created),
            try TaskItem(title: "Sin proyecto", now: created),
        ]

        let progress = ProjectProgress(projectID: projectID, tasks: tasks)

        XCTAssertEqual(progress.pendingCount, 1)
        XCTAssertEqual(progress.completedCount, 1)
        XCTAssertEqual(progress.pendingMinutes, 45)
        XCTAssertEqual(progress.fraction, 0.5)
    }

    func test_progress_withoutTasks_isZero() {
        let progress = ProjectProgress(projectID: UUID(), tasks: [])

        XCTAssertEqual(progress.totalCount, 0)
        XCTAssertEqual(progress.fraction, 0)
    }
}
