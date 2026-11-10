import XCTest
@testable import LifeOS

@MainActor
final class SwiftDataWellnessRepositoryTests: XCTestCase {
    private let created = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeRepository() throws -> any WellnessRepository {
        try AppDependencies(inMemory: true).wellnessRepository
    }

    private func checkIn(day: Int) throws -> WellnessCheckIn {
        try WellnessCheckIn(
            day: LocalDay(year: 2026, month: 1, day: day),
            energy: 3, mood: 4, stress: 2, sleepHours: 7.5, note: "Nota",
            now: created
        )
    }

    func test_save_roundTripsAllFields() throws {
        let repository = try makeRepository()
        let saved = try checkIn(day: 10)

        try repository.save(saved)

        XCTAssertEqual(try repository.checkIn(on: saved.day), saved)
    }

    func test_fetchSince_sortsAndExcludesOldAndDeleted() throws {
        let repository = try makeRepository()
        var deleted = try checkIn(day: 12)
        deleted.markDeleted(at: created)

        for item in [try checkIn(day: 14), try checkIn(day: 2), deleted, try checkIn(day: 11)] {
            try repository.save(item)
        }

        let days = try repository.fetchCheckIns(since: LocalDay(year: 2026, month: 1, day: 5)).map(\.day.day)
        XCTAssertEqual(days, [11, 14])
    }

    func test_checkInOnDay_returnsDeletedToo() throws {
        let repository = try makeRepository()
        var item = try checkIn(day: 10)
        item.markDeleted(at: created)
        try repository.save(item)

        XCTAssertEqual(try repository.checkIn(on: item.day)?.isDeleted, true)
        XCTAssertNil(try repository.checkIn(on: LocalDay(year: 2026, month: 1, day: 11)))
    }
}
