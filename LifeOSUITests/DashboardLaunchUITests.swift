import XCTest

final class DashboardLaunchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Arranca la app con una base de datos vacía en memoria.
    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        return app
    }

    @MainActor
    func test_launch_showsDashboardEmptyState() throws {
        let app = launchApp()

        let emptyState = app.descendants(matching: .any)["dashboard.emptyState"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5))
    }

    @MainActor
    func test_createTask_appearsInList() throws {
        let app = launchApp()

        app.buttons["dashboard.addTask"].tap()

        let titleField = app.textFields["taskForm.title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("Comprar libros")
        app.buttons["taskForm.save"].tap()

        XCTAssertTrue(app.staticTexts["Comprar libros"].waitForExistence(timeout: 5))
    }
}
