import XCTest

final class OnboardingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchWithOnboarding() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-show-onboarding"]
        app.launch()
        return app
    }

    @MainActor
    func test_skipOnboarding_showsDashboard() throws {
        let app = launchWithOnboarding()

        let skip = app.buttons["onboarding.skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.tap()

        XCTAssertTrue(app.buttons["dashboard.addTask"].waitForExistence(timeout: 5))
    }

    @MainActor
    func test_completeOnboarding_greetsByName() throws {
        let app = launchWithOnboarding()

        let welcomeNext = app.buttons["onboarding.next.welcome"]
        XCTAssertTrue(welcomeNext.waitForExistence(timeout: 5))
        welcomeNext.tap()

        let name = app.textFields["onboarding.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Ana")

        let nameNext = app.buttons["onboarding.next.name"]
        XCTAssertTrue(nameNext.waitForExistence(timeout: 5))
        nameNext.tap()

        let finish = app.buttons["onboarding.finish"]
        XCTAssertTrue(finish.waitForExistence(timeout: 5))
        finish.tap()

        let greeting = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Ana"))
            .firstMatch
        XCTAssertTrue(greeting.waitForExistence(timeout: 5))
    }
}
