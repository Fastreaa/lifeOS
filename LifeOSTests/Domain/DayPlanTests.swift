import XCTest
@testable import LifeOS

@MainActor
final class DayPlanTests: XCTestCase {
    private let day = LocalDay(year: 2026, month: 1, day: 15)

    private func block(_ start: Int, _ end: Int, kind: BlockKind = .study) throws -> TimeBlock {
        try TimeBlock(day: day, title: "B", kind: kind, startMinute: start, endMinute: end,
                      now: Date(timeIntervalSince1970: 0))
    }

    /// La ventana por defecto, de 7:00 a 23:00, son 960 minutos.
    func test_emptyDay_isAllFree() {
        let plan = DayPlan(blocks: [], taskMinutes: 0)

        XCTAssertEqual(plan.freeMinutes, 960)
        XCTAssertEqual(plan.busyMinutes, 0)
        XCTAssertEqual(plan.fit, .nothingPending)
    }

    func test_overlappingBlocks_areNotCountedTwice() throws {
        // 9:00–11:00 y 10:00–12:00 ocupan 3 h, no 4.
        let plan = DayPlan(blocks: [try block(540, 660), try block(600, 720)], taskMinutes: 0)

        XCTAssertEqual(plan.busyMinutes, 180)
        XCTAssertEqual(plan.freeMinutes, 780)
        XCTAssertEqual(plan.conflicts.count, 1)
        XCTAssertEqual(plan.conflictingBlockIDs.count, 2)
    }

    func test_blocksOutsideWindow_areClipped() throws {
        // 6:00–8:00: solo cuenta la hora dentro de la ventana (7:00–8:00).
        let plan = DayPlan(blocks: [try block(360, 480)], taskMinutes: 0)

        XCTAssertEqual(plan.busyMinutes, 60)
    }

    func test_restIsSeparatedFromBusyTime() throws {
        let plan = DayPlan(blocks: [try block(540, 600), try block(600, 660, kind: .rest)], taskMinutes: 0)

        XCTAssertEqual(plan.busyMinutes, 60)
        XCTAssertEqual(plan.restMinutes, 60)
        XCTAssertEqual(plan.freeMinutes, 840)
        XCTAssertTrue(plan.conflicts.isEmpty)
    }

    func test_fit_classifiesByFreeTime() throws {
        // Bloque de 7:00 a 21:00: quedan 120 minutos libres.
        let blocks = [try block(420, 1260)]

        XCTAssertEqual(DayPlan(blocks: blocks, taskMinutes: 60).fit, .fits)
        XCTAssertEqual(DayPlan(blocks: blocks, taskMinutes: 110).fit, .tight)
        XCTAssertEqual(DayPlan(blocks: blocks, taskMinutes: 150).fit, .overloaded(excessMinutes: 30))
    }

    func test_unionLength_mergesIntervals() {
        XCTAssertEqual(DayPlan.unionLength([(0, 10), (5, 15), (20, 30)]), 25)
        XCTAssertEqual(DayPlan.unionLength([]), 0)
    }
}
