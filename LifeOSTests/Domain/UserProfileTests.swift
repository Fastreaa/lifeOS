import XCTest
@testable import LifeOS

@MainActor
final class UserProfileTests: XCTestCase {
    private let created = Date(timeIntervalSince1970: 1_800_000_000)

    func test_default_usesSevenToEleven() {
        let profile = UserProfile.makeDefault(now: created)

        XCTAssertNil(profile.displayName)
        XCTAssertEqual(profile.dayWindow, 420...1380)
        XCTAssertEqual(profile.dayWindow, DayPlan.defaultWindow)
        XCTAssertFalse(profile.hasCompletedOnboarding)
    }

    func test_update_trimsNameAndBlankBecomesNil() throws {
        var profile = UserProfile.makeDefault(now: created)

        try profile.update(displayName: "  Ana  ", dayStartMinute: 360, dayEndMinute: 1320, now: created)
        XCTAssertEqual(profile.displayName, "Ana")
        XCTAssertEqual(profile.dayWindow, 360...1320)

        try profile.update(displayName: "   ", dayStartMinute: 360, dayEndMinute: 1320, now: created)
        XCTAssertNil(profile.displayName)
    }

    func test_update_rejectsInvalidData_andLeavesProfileUnchanged() {
        var profile = UserProfile.makeDefault(now: created)
        let original = profile

        XCTAssertThrowsError(try profile.update(displayName: nil, dayStartMinute: 600, dayEndMinute: 540, now: created)) {
            XCTAssertEqual($0 as? ProfileValidationError, .invalidDayWindow)
        }
        XCTAssertThrowsError(try profile.update(displayName: nil, dayStartMinute: 600, dayEndMinute: 780, now: created)) {
            XCTAssertEqual($0 as? ProfileValidationError, .dayTooShort(minimumMinutes: 240))
        }
        XCTAssertThrowsError(try profile.update(displayName: String(repeating: "a", count: 41),
                                                dayStartMinute: 420, dayEndMinute: 1380, now: created)) {
            XCTAssertEqual($0 as? ProfileValidationError, .nameTooLong(maxLength: 40))
        }
        XCTAssertEqual(profile, original)
    }

    func test_markOnboardingCompleted_isIdempotent() {
        var profile = UserProfile.makeDefault(now: created)

        profile.markOnboardingCompleted(at: created.addingTimeInterval(60))
        profile.markOnboardingCompleted(at: created.addingTimeInterval(120))

        XCTAssertTrue(profile.hasCompletedOnboarding)
        XCTAssertEqual(profile.updatedAt, created.addingTimeInterval(60))
    }
}
