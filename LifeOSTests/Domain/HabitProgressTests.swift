import XCTest
@testable import LifeOS

@MainActor
final class HabitProgressTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    /// Jueves 15 de enero de 2026.
    private let today = LocalDay(year: 2026, month: 1, day: 15)

    private func days(_ numbers: Int...) -> Set<LocalDay> {
        Set(numbers.map { LocalDay(year: 2026, month: 1, day: $0) })
    }

    private func daily() throws -> Habit {
        try Habit(name: "Diario", now: Date(timeIntervalSince1970: 0))
    }

    private func progress(_ habit: Habit, _ completed: Set<LocalDay>) -> HabitProgress {
        HabitProgress(habit: habit, completedDays: completed, today: today, calendar: calendar)
    }

    func test_streak_countsConsecutiveDaysIncludingToday() throws {
        let result = progress(try daily(), days(13, 14, 15))

        XCTAssertEqual(result.currentStreak, 3)
        XCTAssertTrue(result.isCompletedToday)
    }

    func test_streak_isNotBrokenByPendingToday() throws {
        let result = progress(try daily(), days(13, 14))

        XCTAssertEqual(result.currentStreak, 2)
        XCTAssertFalse(result.isCompletedToday)
    }

    func test_streak_breaksOnMissedPastDay() throws {
        let result = progress(try daily(), days(12, 13, 15))

        XCTAssertEqual(result.currentStreak, 1)
    }

    func test_streak_skipsRestDays() throws {
        // Lunes, miércoles y viernes. Hoy (jueves) no toca.
        let habit = try Habit(name: "Gimnasio", weekdays: [2, 4, 6], now: Date(timeIntervalSince1970: 0))

        let result = progress(habit, days(9, 12, 14))

        XCTAssertFalse(result.isScheduledToday)
        XCTAssertEqual(result.currentStreak, 3)
    }

    func test_last7Days_countsOnlyTheWindow() throws {
        // Ventana: del 9 al 15. El 8 queda fuera.
        let result = progress(try daily(), days(8, 10, 14, 15))

        XCTAssertEqual(result.scheduledLast7Days, 7)
        XCTAssertEqual(result.completedLast7Days, 3)
    }

    func test_noCompletions_isAllZeros() throws {
        let result = progress(try daily(), [])

        XCTAssertEqual(result.currentStreak, 0)
        XCTAssertEqual(result.completedLast7Days, 0)
        XCTAssertTrue(result.isScheduledToday)
    }
}
