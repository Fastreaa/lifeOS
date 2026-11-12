import XCTest
@testable import LifeOS

@MainActor
final class ReminderSettingsTests: XCTestCase {
    func test_defaults_areAllDisabled() {
        let settings = ReminderSettings()

        XCTAssertFalse(settings.anyEnabled)
        XCTAssertEqual(settings.habitsMinute, 1200)
        XCTAssertEqual(settings.checkInMinute, 1260)
        XCTAssertEqual(settings.blockLeadMinutes, 10)
    }

    func test_disablingAll_keepsTimes() {
        var settings = ReminderSettings()
        settings.habitsEnabled = true
        settings.blockAlertsEnabled = true
        settings.habitsMinute = 600

        let disabled = settings.disablingAll()

        XCTAssertFalse(disabled.anyEnabled)
        XCTAssertEqual(disabled.habitsMinute, 600)
    }

    func test_userDefaultsStore_roundTrips() throws {
        let suiteName = "lifeos.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsReminderSettingsStore(defaults: defaults)
        var settings = ReminderSettings()
        settings.checkInEnabled = true
        settings.checkInMinute = 1290

        store.save(settings)

        XCTAssertEqual(UserDefaultsReminderSettingsStore(defaults: defaults).load(), settings)
    }
}
