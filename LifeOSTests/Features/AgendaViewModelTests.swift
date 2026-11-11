import XCTest
@testable import LifeOS

@MainActor
final class AgendaViewModelTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    /// 15 de enero de 2027, 08:00 GMT. El reloj avanza 1 minuto por llamada.
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeSUT() throws -> (AgendaViewModel, any TimeBlockRepository) {
        let repository = try AppDependencies(inMemory: true).timeBlockRepository
        var time = start
        let viewModel = AgendaViewModel(repository: repository, calendar: calendar) {
            time = time.addingTimeInterval(60)
            return time
        }
        return (viewModel, repository)
    }

    private func draft(_ title: String, from startHour: Int, to endHour: Int) throws -> BlockDraft {
        var draft = BlockDraft(defaultStart: start, calendar: calendar)
        draft.title = title
        draft.start = try XCTUnwrap(calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: start))
        draft.end = try XCTUnwrap(calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: start))
        return draft
    }

    func test_create_addsBlockToSelectedDay() throws {
        let (viewModel, _) = try makeSUT()
        viewModel.load()

        try viewModel.create(try draft("Clase", from: 9, to: 11))

        XCTAssertEqual(viewModel.blocks.map(\.title), ["Clase"])
        XCTAssertEqual(viewModel.blocks.first?.startMinute, 540)
        XCTAssertEqual(viewModel.todayBlocks.count, 1)
    }

    func test_create_withEndBeforeStart_throws() throws {
        let (viewModel, _) = try makeSUT()
        viewModel.load()

        XCTAssertThrowsError(try viewModel.create(try draft("Mal", from: 11, to: 9))) {
            XCTAssertEqual($0 as? TimeBlockValidationError, .invalidTimeRange)
        }
        XCTAssertTrue(viewModel.blocks.isEmpty)
    }

    func test_endAtMidnight_isStoredAsEndOfDay() throws {
        let (viewModel, _) = try makeSUT()
        viewModel.load()

        try viewModel.create(try draft("Noche", from: 22, to: 0))

        XCTAssertEqual(viewModel.blocks.first?.endMinute, 1440)
    }

    func test_otherDay_doesNotChangeTodayBlocks() throws {
        let (viewModel, _) = try makeSUT()
        viewModel.load()
        try viewModel.create(try draft("Hoy", from: 9, to: 10))

        viewModel.showDay(offset: 1)
        XCTAssertFalse(viewModel.isShowingToday)
        XCTAssertTrue(viewModel.blocks.isEmpty)
        try viewModel.create(try draft("Mañana", from: 9, to: 10))

        XCTAssertEqual(viewModel.blocks.map(\.title), ["Mañana"])
        XCTAssertEqual(viewModel.todayBlocks.map(\.title), ["Hoy"])

        viewModel.showToday()
        XCTAssertEqual(viewModel.blocks.map(\.title), ["Hoy"])
    }

    func test_plan_countsTasksOnlyToday() throws {
        let (viewModel, _) = try makeSUT()
        viewModel.load()

        XCTAssertEqual(viewModel.plan(taskMinutes: 60).taskMinutes, 60)

        viewModel.showDay(offset: 1)
        XCTAssertEqual(viewModel.plan(taskMinutes: 60).fit, .nothingPending)
    }

    func test_delete_removesBlock() throws {
        let (viewModel, _) = try makeSUT()
        viewModel.load()
        try viewModel.create(try draft("Temporal", from: 9, to: 10))
        let block = try XCTUnwrap(viewModel.blocks.first)

        viewModel.delete(block)

        XCTAssertTrue(viewModel.blocks.isEmpty)
        XCTAssertTrue(viewModel.todayBlocks.isEmpty)
    }
}
