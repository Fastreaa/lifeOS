import XCTest

final class DashboardLaunchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test_launch_showsDashboardEmptyState() throws {
        let app = XCUIApplication()
        app.launch()

        let emptyState = app.descendants(matching: .any)["dashboard.emptyState"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5))
    }
}
