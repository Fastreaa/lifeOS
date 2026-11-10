import XCTest
@testable import LifeOS

@MainActor
final class WeeklyWellnessSummaryTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    private let today = LocalDay(year: 2026, month: 1, day: 15)

    private func checkIn(day: Int, energy: Int, mood: Int, stress: Int, sleep: Double? = nil) throws -> WellnessCheckIn {
        try WellnessCheckIn(
            day: LocalDay(year: 2026, month: 1, day: day),
            energy: energy, mood: mood, stress: stress, sleepHours: sleep,
            now: Date(timeIntervalSince1970: 0)
        )
    }

    func test_points_coverSevenDaysOldestFirst() {
        let summary = WeeklyWellnessSummary(checkIns: [], today: today, calendar: calendar)

        XCTAssertEqual(summary.points.count, 7)
        XCTAssertEqual(summary.points.first?.day, LocalDay(year: 2026, month: 1, day: 9))
        XCTAssertEqual(summary.points.last?.day, today)
    }

    func test_averages_useOnlyLoggedDaysInWindow() throws {
        let checkIns = [
            try checkIn(day: 15, energy: 4, mood: 4, stress: 2, sleep: 8),
            try checkIn(day: 12, energy: 2, mood: 3, stress: 4),
            try checkIn(day: 1, energy: 1, mood: 1, stress: 5, sleep: 3), // fuera de la ventana
        ]

        let summary = WeeklyWellnessSummary(checkIns: checkIns, today: today, calendar: calendar)

        XCTAssertEqual(summary.loggedDays, 2)
        XCTAssertEqual(summary.averageEnergy, 3)
        XCTAssertEqual(summary.averageMood, 3.5)
        XCTAssertEqual(summary.averageStress, 3)
        XCTAssertEqual(summary.averageSleepHours, 8)
    }

    func test_noCheckIns_hasNoAverages() {
        let summary = WeeklyWellnessSummary(checkIns: [], today: today, calendar: calendar)

        XCTAssertEqual(summary.loggedDays, 0)
        XCTAssertNil(summary.averageEnergy)
        XCTAssertNil(summary.averageSleepHours)
    }
}
