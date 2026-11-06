import XCTest
@testable import LifeOS

@MainActor
final class DayPeriodTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    private func date(hour: Int) throws -> Date {
        let components = DateComponents(year: 2026, month: 1, day: 15, hour: hour)
        return try XCTUnwrap(calendar.date(from: components))
    }

    func test_morning_coversFiveToEleven() throws {
        XCTAssertEqual(DayPeriod(date: try date(hour: 5), calendar: calendar), .morning)
        XCTAssertEqual(DayPeriod(date: try date(hour: 11), calendar: calendar), .morning)
    }

    func test_afternoon_coversTwelveToNineteen() throws {
        XCTAssertEqual(DayPeriod(date: try date(hour: 12), calendar: calendar), .afternoon)
        XCTAssertEqual(DayPeriod(date: try date(hour: 19), calendar: calendar), .afternoon)
    }

    func test_night_coversTwentyToFour() throws {
        XCTAssertEqual(DayPeriod(date: try date(hour: 20), calendar: calendar), .night)
        XCTAssertEqual(DayPeriod(date: try date(hour: 0), calendar: calendar), .night)
        XCTAssertEqual(DayPeriod(date: try date(hour: 4), calendar: calendar), .night)
    }
}
