import XCTest
@testable import LifeOS

@MainActor
final class DaySummaryTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// 15 de enero de 2026, 10:00 GMT.
    private func date(day: Int = 15, hour: Int, minute: Int = 0, second: Int = 0) throws -> Date {
        let components = DateComponents(
            year: 2026, month: 1, day: day, hour: hour, minute: minute, second: second
        )
        return try XCTUnwrap(calendar.date(from: components))
    }

    private func task(due: Date?, estimate: Int? = nil) throws -> TaskItem {
        try TaskItem(
            title: "Tarea",
            dueDate: due,
            estimatedMinutes: estimate,
            now: try date(day: 1, hour: 8)
        )
    }

    func test_countsTodayPastDueAndEstimates() throws {
        let now = try date(hour: 10)
        let pending = [
            try task(due: try date(hour: 18), estimate: 30),
            try task(due: try date(hour: 9), estimate: 60),   // hoy, aunque ya pasó la hora
            try task(due: try date(day: 14, hour: 12), estimate: 15),
            try task(due: try date(day: 16, hour: 9), estimate: 45),
            try task(due: nil, estimate: 20),
        ]

        let summary = DaySummary(pending: pending, now: now, calendar: calendar)

        XCTAssertEqual(summary.pendingCount, 5)
        XCTAssertEqual(summary.dueTodayCount, 2)
        XCTAssertEqual(summary.pastDueCount, 1)
        XCTAssertEqual(summary.estimatedMinutesDueToday, 90)
    }

    func test_dayBoundaries() throws {
        let now = try date(hour: 10)
        let pending = [
            try task(due: try date(hour: 0)),                         // hoy
            try task(due: try date(day: 16, hour: 0)),                // mañana
            try task(due: try date(day: 14, hour: 23, minute: 59, second: 59)), // ayer
        ]

        let summary = DaySummary(pending: pending, now: now, calendar: calendar)

        XCTAssertEqual(summary.dueTodayCount, 1)
        XCTAssertEqual(summary.pastDueCount, 1)
    }

    func test_emptyList_isAllZeros() throws {
        let summary = DaySummary(pending: [], now: try date(hour: 10), calendar: calendar)

        XCTAssertEqual(summary.pendingCount, 0)
        XCTAssertEqual(summary.dueTodayCount, 0)
        XCTAssertEqual(summary.pastDueCount, 0)
        XCTAssertEqual(summary.estimatedMinutesDueToday, 0)
    }
}
