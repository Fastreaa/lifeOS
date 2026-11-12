import XCTest

final class HabitsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test_createHabit_appearsInList() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        app.buttons["Hábitos"].tap()
        app.buttons["habits.addHabit"].tap()

        let nameField = app.textFields["habitForm.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tapAndType("Beber agua")
        app.buttons["habitForm.save"].tap()

        XCTAssertTrue(app.staticTexts["Beber agua"].waitForExistence(timeout: 5))
    }
}
