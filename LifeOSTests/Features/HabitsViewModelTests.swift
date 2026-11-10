import XCTest
@testable import LifeOS

@MainActor
final class HabitsViewModelTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    /// 15 de enero de 2027, 08:00 GMT. El reloj avanza 1 minuto por llamada.
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeSUT() throws -> (HabitsViewModel, any HabitRepository) {
        let repository = try AppDependencies(inMemory: true).habitRepository
        var time = start
        let viewModel = HabitsViewModel(repository: repository, calendar: calendar) {
            time = time.addingTimeInterval(60)
            return time
        }
        return (viewModel, repository)
    }

    private func draft(_ name: String, weekdays: Set<Int> = Habit.allWeekdays) -> HabitDraft {
        var draft = HabitDraft()
        draft.name = name
        draft.weekdays = weekdays
        return draft
    }

    private var today: LocalDay { LocalDay(start, calendar: calendar) }

    func test_create_addsHabitScheduledToday() throws {
        let (viewModel, _) = try makeSUT()

        try viewModel.create(draft("Beber agua"))

        XCTAssertEqual(viewModel.items.map(\.habit.name), ["Beber agua"])
        XCTAssertEqual(viewModel.scheduledTodayCount, 1)
        XCTAssertEqual(viewModel.completedTodayCount, 0)
    }

    func test_create_withBlankName_throws() throws {
        let (viewModel, _) = try makeSUT()

        XCTAssertThrowsError(try viewModel.create(draft("   "))) {
            XCTAssertEqual($0 as? HabitValidationError, .emptyName)
        }
        XCTAssertTrue(viewModel.isEmpty)
    }

    func test_toggleToday_marksAndUnmarks() throws {
        let (viewModel, repository) = try makeSUT()
        try viewModel.create(draft("Leer"))
        let habit = try XCTUnwrap(viewModel.items.first?.habit)

        viewModel.toggleToday(habit)
        XCTAssertEqual(viewModel.completedTodayCount, 1)
        XCTAssertEqual(viewModel.items.first?.progress.currentStreak, 1)

        viewModel.toggleToday(habit)
        XCTAssertEqual(viewModel.completedTodayCount, 0)
        XCTAssertEqual(try repository.log(habitID: habit.id, day: today)?.isActive, false)

        viewModel.toggleToday(habit)
        XCTAssertEqual(viewModel.completedTodayCount, 1)
    }

    func test_streak_includesPreviousDays() throws {
        let (viewModel, repository) = try makeSUT()
        try viewModel.create(draft("Caminar"))
        let habit = try XCTUnwrap(viewModel.items.first?.habit)

        for offset in 1...2 {
            let day = try XCTUnwrap(today.adding(days: -offset, calendar: calendar))
            try repository.save(HabitLog(habitID: habit.id, day: day, now: start))
        }
        viewModel.load()
        XCTAssertEqual(viewModel.items.first?.progress.currentStreak, 2)

        viewModel.toggleToday(habit)
        XCTAssertEqual(viewModel.items.first?.progress.currentStreak, 3)
    }

    func test_delete_removesHabit() throws {
        let (viewModel, _) = try makeSUT()
        try viewModel.create(draft("Temporal"))
        let habit = try XCTUnwrap(viewModel.items.first?.habit)

        viewModel.delete(habit)

        XCTAssertTrue(viewModel.isEmpty)
    }

    func test_habitNotScheduledToday_isNotCounted() throws {
        let (viewModel, _) = try makeSUT()
        let todayWeekday = try XCTUnwrap(today.weekday(in: calendar))
        let otherDay = todayWeekday == 1 ? 2 : 1

        try viewModel.create(draft("Solo otro día", weekdays: [otherDay]))

        XCTAssertEqual(viewModel.scheduledTodayCount, 0)
        XCTAssertEqual(viewModel.items.first?.progress.isScheduledToday, false)
    }
}
