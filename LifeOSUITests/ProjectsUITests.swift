import XCTest

final class ProjectsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test_createProject_appearsInList() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        app.buttons["Proyectos"].firstMatch.tap()

        let add = app.buttons["projects.addProject"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()

        let name = app.textFields["projectForm.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tapAndType("Universidad")
        app.buttons["projectForm.save"].tap()

        XCTAssertTrue(app.scrollUntilExists(app.staticTexts["Universidad"]))
    }
}
