import XCTest

final class SettingsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test_settings_showsRemindersSection() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let settings = app.buttons["dashboard.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()

        let habitsToggle = app.descendants(matching: .any)["reminders.habits"]
        XCTAssertTrue(app.scrollUntilExists(habitsToggle))
    }
}
