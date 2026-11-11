import XCTest
@testable import LifeOS

@MainActor
final class SwiftDataProfileRepositoryTests: XCTestCase {
    private let created = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeRepository() throws -> any ProfileRepository {
        try AppDependencies(inMemory: true).profileRepository
    }

    func test_load_onEmptyStore_returnsNil() throws {
        XCTAssertNil(try makeRepository().loadProfile())
    }

    func test_save_roundTripsAllFields() throws {
        let repository = try makeRepository()
        var profile = UserProfile.makeDefault(now: created)
        try profile.update(displayName: "Ana", dayStartMinute: 390, dayEndMinute: 1410, now: created)
        profile.markOnboardingCompleted(at: created)

        try repository.save(profile)

        XCTAssertEqual(try repository.loadProfile(), profile)
    }

    func test_saveTwice_keepsSingleProfile() throws {
        let repository = try makeRepository()
        var profile = UserProfile.makeDefault(now: created)
        try repository.save(profile)

        try profile.update(displayName: "Leo", dayStartMinute: 480, dayEndMinute: 1440, now: created)
        try repository.save(profile)

        XCTAssertEqual(try repository.loadProfile()?.displayName, "Leo")
        XCTAssertEqual(try repository.loadProfile()?.id, profile.id)
    }
}
