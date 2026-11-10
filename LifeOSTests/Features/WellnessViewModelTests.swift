import XCTest
@testable import LifeOS

@MainActor
final class WellnessViewModelTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    /// 15 de enero de 2027, 08:00 GMT. El reloj avanza 1 minuto por llamada.
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeSUT() throws -> (WellnessViewModel, any WellnessRepository) {
        let repository = try AppDependencies(inMemory: true).wellnessRepository
        var time = start
        let viewModel = WellnessViewModel(repository: repository, calendar: calendar) {
            time = time.addingTimeInterval(60)
            return time
        }
        return (viewModel, repository)
    }

    private func draft(energy: Int = 3, mood: Int = 3, stress: Int = 3) -> CheckInDraft {
        var draft = CheckInDraft()
        draft.energy = energy
        draft.mood = mood
        draft.stress = stress
        return draft
    }

    func test_load_withoutData_hasNoTodayCheckIn() throws {
        let (viewModel, _) = try makeSUT()

        viewModel.load()

        XCTAssertNil(viewModel.todayCheckIn)
        XCTAssertEqual(viewModel.weekly.loggedDays, 0)
    }

    func test_saveToday_createsCheckIn() throws {
        let (viewModel, _) = try makeSUT()
        viewModel.load()

        try viewModel.save(draft(energy: 4, mood: 5, stress: 1), for: viewModel.today)

        XCTAssertEqual(viewModel.todayCheckIn?.energy, 4)
        XCTAssertEqual(viewModel.weekly.loggedDays, 1)
    }

    func test_saveTwiceSameDay_updatesWithoutDuplicating() throws {
        let (viewModel, repository) = try makeSUT()
        viewModel.load()

        try viewModel.save(draft(energy: 2), for: viewModel.today)
        try viewModel.save(draft(energy: 5), for: viewModel.today)

        XCTAssertEqual(viewModel.todayCheckIn?.energy, 5)
        XCTAssertEqual(try repository.fetchCheckIns(since: viewModel.today).count, 1)
    }

    func test_savePastDay_appearsInHistoryNotToday() throws {
        let (viewModel, _) = try makeSUT()
        viewModel.load()
        let yesterday = try XCTUnwrap(viewModel.today.adding(days: -1, calendar: calendar))

        try viewModel.save(draft(mood: 2), for: yesterday)

        XCTAssertNil(viewModel.todayCheckIn)
        XCTAssertEqual(viewModel.pastHistory.map(\.day), [yesterday])
    }

    func test_delete_thenSaveAgain_reusesDay() throws {
        let (viewModel, repository) = try makeSUT()
        viewModel.load()
        try viewModel.save(draft(), for: viewModel.today)
        let checkIn = try XCTUnwrap(viewModel.todayCheckIn)

        viewModel.delete(checkIn)
        XCTAssertNil(viewModel.todayCheckIn)

        try viewModel.save(draft(stress: 5), for: viewModel.today)
        XCTAssertEqual(viewModel.todayCheckIn?.id, checkIn.id)
        XCTAssertEqual(viewModel.todayCheckIn?.stress, 5)
        XCTAssertEqual(try repository.checkIn(on: viewModel.today)?.isDeleted, false)
    }
}
