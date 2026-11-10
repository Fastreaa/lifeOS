import XCTest

final class WellnessUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test_checkIn_showsTodayCard() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        app.buttons["Bienestar"].tap()

        let checkInButton = app.buttons["wellness.checkIn"]
        XCTAssertTrue(checkInButton.waitForExistence(timeout: 5))
        checkInButton.tap()

        let save = app.buttons["checkInForm.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()

        XCTAssertTrue(app.buttons["wellness.editToday"].waitForExistence(timeout: 5))
    }
}
