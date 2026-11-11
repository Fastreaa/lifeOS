import XCTest
@testable import LifeOS

/// La agenda usa el horario del usuario para calcular el tiempo libre.
@MainActor
final class AgendaWindowTests: XCTestCase {
    func test_plan_usesDayWindow() throws {
        let repository = try AppDependencies(inMemory: true).timeBlockRepository
        let viewModel = AgendaViewModel(repository: repository)
        viewModel.load()

        XCTAssertEqual(viewModel.plan(taskMinutes: 0).freeMinutes, 960)

        viewModel.dayWindow = (8 * 60)...(22 * 60)
        XCTAssertEqual(viewModel.plan(taskMinutes: 0).freeMinutes, 840)
        XCTAssertEqual(viewModel.todayPlan(taskMinutes: 0).window, 480...1320)
    }
}
