import XCTest
@testable import LifeOS

/// Minutos del día y "qué bloque toca".
@MainActor
final class AgendaTimeTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    private let day = LocalDay(year: 2026, month: 1, day: 15)

    func test_minuteOfDay_roundTrips() throws {
        let date = try XCTUnwrap(MinuteOfDay.date(570, on: day, calendar: calendar))

        XCTAssertEqual(MinuteOfDay.from(date, calendar: calendar), 570)
        XCTAssertEqual(LocalDay(date, calendar: calendar), day)
    }

    func test_endOfDay_isNextMidnight() throws {
        let date = try XCTUnwrap(MinuteOfDay.date(1440, on: day, calendar: calendar))

        XCTAssertEqual(LocalDay(date, calendar: calendar), LocalDay(year: 2026, month: 1, day: 16))
        XCTAssertEqual(MinuteOfDay.from(date, calendar: calendar), 0)
    }

    private func block(_ title: String, _ start: Int, _ end: Int) throws -> TimeBlock {
        try TimeBlock(day: day, title: title, kind: .study, startMinute: start, endMinute: end,
                      now: Date(timeIntervalSince1970: 0))
    }

    func test_upcoming_findsCurrentThenNext() throws {
        let blocks = [try block("Tarde", 900, 960), try block("Mañana", 540, 660)]

        let current = UpcomingBlock.find(in: blocks, atMinute: 600)
        XCTAssertEqual(current?.block.title, "Mañana")
        XCTAssertEqual(current?.isCurrent, true)

        let next = UpcomingBlock.find(in: blocks, atMinute: 700)
        XCTAssertEqual(next?.block.title, "Tarde")
        XCTAssertEqual(next?.isCurrent, false)

        XCTAssertNil(UpcomingBlock.find(in: blocks, atMinute: 1000))
    }
}
