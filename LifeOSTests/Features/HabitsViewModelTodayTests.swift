import XCTest
@testable import LifeOS

/// Lo que el dashboard muestra de los hábitos.
@MainActor
final class HabitsViewModelTodayTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeSUT() throws -> HabitsViewModel {
        let repository = try AppDependencies(inMemory: true).habitRepository
        var time = start
        return HabitsViewModel(repository: repository, calendar: calendar) {
            time = time.addingTimeInterval(60)
            return time
        }
    }

    private func draft(_ name: String, weekdays: Set<Int> = Habit.allWeekdays) -> HabitDraft {
        var draft = HabitDraft()
        draft.name = name
        draft.weekdays = weekdays
        return draft
    }

    func test_todayItems_onlyIncludesHabitsScheduledToday() throws {
        let viewModel = try makeSUT()
        let todayWeekday = try XCTUnwrap(LocalDay(start, calendar: calendar).weekday(in: calendar))
        let otherDay = todayWeekday == 1 ? 2 : 1

        try viewModel.create(draft("Todos los días"))
        try viewModel.create(draft("Otro día", weekdays: [otherDay]))

        XCTAssertEqual(viewModel.items.count, 2)
        XCTAssertEqual(viewModel.todayItems.map(\.habit.name), ["Todos los días"])
    }

    func test_todayItems_reflectCompletion() throws {
        let viewModel = try makeSUT()
        try viewModel.create(draft("Leer"))
        let habit = try XCTUnwrap(viewModel.todayItems.first?.habit)

        viewModel.toggleToday(habit)

        XCTAssertEqual(viewModel.todayItems.first?.progress.isCompletedToday, true)
    }
}
