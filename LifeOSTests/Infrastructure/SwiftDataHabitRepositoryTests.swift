import XCTest
@testable import LifeOS

@MainActor
final class SwiftDataHabitRepositoryTests: XCTestCase {
    private let created = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeRepository() throws -> any HabitRepository {
        try AppDependencies(inMemory: true).habitRepository
    }

    func test_saveHabit_roundTripsAllFields() throws {
        let repository = try makeRepository()
        let habit = try Habit(name: "Gimnasio", symbolName: "dumbbell", weekdays: [2, 4, 6], now: created)

        try repository.save(habit)

        XCTAssertEqual(try repository.fetchHabits(), [habit])
    }

    func test_saveHabit_updatesWithoutDuplicating() throws {
        let repository = try makeRepository()
        var habit = try Habit(name: "Leer", now: created)
        try repository.save(habit)

        try habit.update(name: "Leer 20 minutos", symbolName: "book", weekdays: [1, 7], now: created.addingTimeInterval(60))
        try repository.save(habit)

        XCTAssertEqual(try repository.fetchHabits(), [habit])
    }

    func test_fetchHabits_excludesDeleted() throws {
        let repository = try makeRepository()
        let kept = try Habit(name: "Se queda", now: created)
        var removed = try Habit(name: "Se va", now: created.addingTimeInterval(1))
        try repository.save(kept)
        removed.markDeleted(at: created.addingTimeInterval(60))
        try repository.save(removed)

        XCTAssertEqual(try repository.fetchHabits().map(\.name), ["Se queda"])
    }

    func test_fetchLogs_returnsActiveLogsSinceDay() throws {
        let repository = try makeRepository()
        let habitID = UUID()
        let old = HabitLog(habitID: habitID, day: LocalDay(year: 2026, month: 1, day: 1), now: created)
        let recent = HabitLog(habitID: habitID, day: LocalDay(year: 2026, month: 1, day: 10), now: created)
        var undone = HabitLog(habitID: habitID, day: LocalDay(year: 2026, month: 1, day: 11), now: created)
        undone.markDeleted(at: created)

        for log in [old, recent, undone] {
            try repository.save(log)
        }

        let logs = try repository.fetchLogs(since: LocalDay(year: 2026, month: 1, day: 5))
        XCTAssertEqual(logs, [recent])
    }

    func test_logForDay_returnsInactiveLogToo() throws {
        let repository = try makeRepository()
        let day = LocalDay(year: 2026, month: 1, day: 10)
        var log = HabitLog(habitID: UUID(), day: day, now: created)
        log.markDeleted(at: created)
        try repository.save(log)

        let stored = try repository.log(habitID: log.habitID, day: day)
        XCTAssertEqual(stored?.isActive, false)
        XCTAssertNil(try repository.log(habitID: UUID(), day: day))
    }

    func test_weekdayMask_roundTrips() {
        let weekdays: Set<Int> = [1, 3, 7]
        XCTAssertEqual(HabitRecord.weekdays(fromMask: HabitRecord.mask(from: weekdays)), weekdays)
        XCTAssertEqual(HabitRecord.mask(from: Habit.allWeekdays), 127)
    }
}
