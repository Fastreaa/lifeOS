import XCTest
@testable import LifeOS

@MainActor
final class TaskDraftTests: XCTestCase {
    func test_canSave_requiresNonBlankTitle() {
        var draft = TaskDraft()
        XCTAssertFalse(draft.canSave)

        draft.title = "   "
        XCTAssertFalse(draft.canSave)

        draft.title = "Estudiar"
        XCTAssertTrue(draft.canSave)
    }

    func test_optionalFields_areNilUnlessEnabled() {
        var draft = TaskDraft()
        XCTAssertNil(draft.resolvedDueDate)
        XCTAssertNil(draft.resolvedEstimate)

        draft.hasDueDate = true
        draft.hasEstimate = true
        XCTAssertEqual(draft.resolvedDueDate, draft.dueDate)
        XCTAssertEqual(draft.resolvedEstimate, draft.estimatedMinutes)
    }

    func test_initFromTask_restoresFields() throws {
        let due = Date(timeIntervalSince1970: 1_800_086_400)
        let task = try TaskItem(
            title: "Proyecto final",
            notes: "Equipo de 3",
            priority: .high,
            dueDate: due,
            estimatedMinutes: 120,
            now: Date(timeIntervalSince1970: 1_800_000_000)
        )

        let draft = TaskDraft(task: task)

        XCTAssertEqual(draft.title, "Proyecto final")
        XCTAssertEqual(draft.notes, "Equipo de 3")
        XCTAssertEqual(draft.priority, .high)
        XCTAssertEqual(draft.resolvedDueDate, due)
        XCTAssertEqual(draft.resolvedEstimate, 120)
    }
}
