import XCTest

final class AgendaUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test_createBlock_appearsInAgenda() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        app.buttons["Agenda"].firstMatch.tap()

        let add = app.buttons["agenda.addBlock"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()

        let title = app.textFields["blockForm.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tapAndType("Clase de cálculo")
        app.buttons["blockForm.save"].tap()

        XCTAssertTrue(app.staticTexts["Clase de cálculo"].waitForExistence(timeout: 5))
    }
}
