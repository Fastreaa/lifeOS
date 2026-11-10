import XCTest
@testable import LifeOS

@MainActor
final class HabitTests: XCTestCase {
    private let created = Date(timeIntervalSince1970: 1_800_000_000)
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    func test_init_trimsNameAndDefaultsToDaily() throws {
        let habit = try Habit(name: "  Leer  ", now: created)

        XCTAssertEqual(habit.name, "Leer")
        XCTAssertTrue(habit.isDaily)
        XCTAssertEqual(habit.symbolName, "star")
        XCTAssertEqual(habit.updatedAt, created)
    }

    func test_init_rejectsInvalidData() {
        XCTAssertThrowsError(try Habit(name: "  ", now: created)) {
            XCTAssertEqual($0 as? HabitValidationError, .emptyName)
        }
        XCTAssertThrowsError(try Habit(name: String(repeating: "a", count: 61), now: created)) {
            XCTAssertEqual($0 as? HabitValidationError, .nameTooLong(maxLength: 60))
        }
        XCTAssertThrowsError(try Habit(name: "x", weekdays: [], now: created)) {
            XCTAssertEqual($0 as? HabitValidationError, .noWeekdays)
        }
        XCTAssertThrowsError(try Habit(name: "x", weekdays: [2, 8], now: created)) {
            XCTAssertEqual($0 as? HabitValidationError, .invalidWeekday(8))
        }
        XCTAssertThrowsError(try Habit(name: "x", symbolName: " ", now: created)) {
            XCTAssertEqual($0 as? HabitValidationError, .missingSymbol)
        }
    }

    func test_update_withInvalidData_leavesHabitUnchanged() throws {
        var habit = try Habit(name: "Correr", now: created)
        let original = habit

        XCTAssertThrowsError(
            try habit.update(name: "Correr", symbolName: "star", weekdays: [], now: created.addingTimeInterval(60))
        )
        XCTAssertEqual(habit, original)
    }

    func test_update_changesFieldsAndBumpsUpdatedAt() throws {
        var habit = try Habit(name: "Correr", now: created)

        try habit.update(name: "Caminar", symbolName: "figure.walk", weekdays: [2, 4], now: created.addingTimeInterval(60))

        XCTAssertEqual(habit.name, "Caminar")
        XCTAssertEqual(habit.weekdays, [2, 4])
        XCTAssertFalse(habit.isDaily)
        XCTAssertEqual(habit.updatedAt, created.addingTimeInterval(60))
    }

    func test_isScheduled_respectsWeekdays() throws {
        // Lunes, miércoles y viernes.
        let habit = try Habit(name: "Gimnasio", weekdays: [2, 4, 6], now: created)

        XCTAssertTrue(habit.isScheduled(on: LocalDay(year: 2026, month: 1, day: 12), calendar: calendar))
        XCTAssertFalse(habit.isScheduled(on: LocalDay(year: 2026, month: 1, day: 13), calendar: calendar))
    }

    func test_logMarkDeletedAndRestore() {
        var log = HabitLog(habitID: UUID(), day: LocalDay(year: 2026, month: 1, day: 12), now: created)

        log.markDeleted(at: created.addingTimeInterval(60))
        XCTAssertFalse(log.isActive)

        log.restore(at: created.addingTimeInterval(120))
        XCTAssertTrue(log.isActive)
        XCTAssertEqual(log.updatedAt, created.addingTimeInterval(120))
    }
}
