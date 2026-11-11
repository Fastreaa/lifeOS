import XCTest

final class DashboardCardsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        return app
    }

    @MainActor
    func test_checkInFromDashboard_showsSummary() throws {
        let app = launchApp()

        let checkIn = app.buttons["dashboard.checkIn"]
        XCTAssertTrue(app.scrollUntilExists(checkIn))
        checkIn.tap()

        let save = app.buttons["checkInForm.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()

        let summary = app.descendants(matching: .any)["dashboard.wellnessSummary"]
        XCTAssertTrue(app.scrollUntilExists(summary))
    }

    @MainActor
    func test_openHabitsFromDashboard_switchesTab() throws {
        let app = launchApp()

        let openHabits = app.buttons["dashboard.openHabits"]
        XCTAssertTrue(app.scrollUntilExists(openHabits))
        openHabits.tap()

        let emptyHabits = app.descendants(matching: .any)["habits.emptyState"]
        XCTAssertTrue(emptyHabits.waitForExistence(timeout: 5))
    }
}
