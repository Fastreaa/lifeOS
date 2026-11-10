import XCTest
@testable import LifeOS

@MainActor
final class LocalDayTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    func test_initFromDate_usesCalendarDay() throws {
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 9, hour: 23)))
        XCTAssertEqual(LocalDay(date, calendar: calendar), LocalDay(year: 2026, month: 3, day: 9))
    }

    func test_storageValue_roundTrips() {
        let day = LocalDay(year: 2026, month: 11, day: 10)
        XCTAssertEqual(day.storageValue, 20261110)
        XCTAssertEqual(LocalDay(storageValue: 20261110), day)
    }

    func test_invalidStorageValue_returnsNil() {
        XCTAssertNil(LocalDay(storageValue: 20261340))
        XCTAssertNil(LocalDay(storageValue: 20260100))
        XCTAssertNil(LocalDay(storageValue: 0))
    }

    func test_addingDays_crossesMonthsAndYears() {
        let endOfJanuary = LocalDay(year: 2026, month: 1, day: 31)
        XCTAssertEqual(endOfJanuary.adding(days: 1, calendar: calendar), LocalDay(year: 2026, month: 2, day: 1))

        let newYear = LocalDay(year: 2026, month: 1, day: 1)
        XCTAssertEqual(newYear.adding(days: -1, calendar: calendar), LocalDay(year: 2025, month: 12, day: 31))
    }

    func test_ordering_andWeekday() {
        let monday = LocalDay(year: 2026, month: 1, day: 12)
        let tuesday = LocalDay(year: 2026, month: 1, day: 13)
        XCTAssertLessThan(monday, tuesday)
        XCTAssertEqual(monday.weekday(in: calendar), 2)
    }
}
