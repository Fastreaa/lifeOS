import XCTest
@testable import LifeOS

@MainActor
final class ReminderPlannerTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    private let day = LocalDay(year: 2026, month: 1, day: 15)

    /// 15 de enero de 2026 a las 10:00 GMT.
    private var now: Date {
        get throws { try XCTUnwrap(MinuteOfDay.date(600, on: day, calendar: calendar)) }
    }

    private func block(_ title: String, at start: Int, on day: LocalDay? = nil, deleted: Bool = false) throws -> TimeBlock {
        var block = try TimeBlock(day: day ?? self.day, title: title, kind: .classSession,
                                  startMinute: start, endMinute: start + 60,
                                  now: Date(timeIntervalSince1970: 0))
        if deleted { block.markDeleted(at: Date(timeIntervalSince1970: 0)) }
        return block
    }

    private var planner: ReminderPlanner { ReminderPlanner(calendar: calendar) }

    func test_disabled_plansNothing() throws {
        let plan = planner.plan(settings: ReminderSettings(), blocks: [try block("Clase", at: 720)], now: try now)

        XCTAssertTrue(plan.isEmpty)
    }

    func test_dailyReminders_useChosenTimes() throws {
        var settings = ReminderSettings()
        settings.habitsEnabled = true
        settings.habitsMinute = 1170
        settings.checkInEnabled = true

        let plan = planner.plan(settings: settings, blocks: [], now: try now)

        XCTAssertEqual(plan.map(\.id), ["lifeos.habits", "lifeos.checkin"])
        XCTAssertEqual(plan.first?.trigger, .daily(minute: 1170))
        XCTAssertEqual(plan.last?.trigger, .daily(minute: 1260))
    }

    func test_blockAlerts_fireBeforeStartAndSkipPastOrDeleted() throws {
        var settings = ReminderSettings()
        settings.blockAlertsEnabled = true
        settings.blockLeadMinutes = 15
        let tomorrow = try XCTUnwrap(day.adding(days: 1, calendar: calendar))
        let blocks = [
            try block("Ya pasó", at: 540),
            try block("Empieza en 5 min", at: 605),
            try block("Comida", at: 840),
            try block("Borrado", at: 900, deleted: true),
            try block("Mañana", at: 480, on: tomorrow),
        ]

        let plan = planner.plan(settings: settings, blocks: blocks, now: try now)

        XCTAssertEqual(plan.map(\.title), ["Comida", "Mañana"])
        let expected = try XCTUnwrap(MinuteOfDay.date(825, on: day, calendar: calendar))
        XCTAssertEqual(plan.first?.trigger, .at(expected))
    }

    func test_plan_isCappedBelowSystemLimit() throws {
        var settings = ReminderSettings()
        settings.blockAlertsEnabled = true
        let blocks = try (0..<80).map { index in
            try block("B\(index)", at: 660 + index * 9)
        }.filter { $0.endMinute <= 1440 }

        let plan = planner.plan(settings: settings, blocks: blocks, now: try now)

        XCTAssertLessThanOrEqual(plan.count, ReminderPlanner.maxNotifications)
    }
}
