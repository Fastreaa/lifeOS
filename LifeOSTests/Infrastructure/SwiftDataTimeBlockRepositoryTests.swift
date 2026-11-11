import XCTest
@testable import LifeOS

@MainActor
final class SwiftDataTimeBlockRepositoryTests: XCTestCase {
    private let created = Date(timeIntervalSince1970: 1_800_000_000)
    private let day = LocalDay(year: 2026, month: 1, day: 15)

    private func makeRepository() throws -> any TimeBlockRepository {
        try AppDependencies(inMemory: true).timeBlockRepository
    }

    private func block(_ title: String, _ start: Int, on day: LocalDay? = nil) throws -> TimeBlock {
        try TimeBlock(day: day ?? self.day, title: title, kind: .classSession,
                      startMinute: start, endMinute: start + 60, now: created)
    }

    func test_save_roundTripsAllFields() throws {
        let repository = try makeRepository()
        let item = try block("Clase", 540)

        try repository.save(item)

        XCTAssertEqual(try repository.fetchBlocks(on: day), [item])
    }

    func test_fetch_filtersByDaySortsAndExcludesDeleted() throws {
        let repository = try makeRepository()
        var deleted = try block("Borrado", 600)
        deleted.markDeleted(at: created)
        let otherDay = try block("Otro día", 480, on: LocalDay(year: 2026, month: 1, day: 16))

        for item in [try block("Tarde", 900), try block("Mañana", 540), deleted, otherDay] {
            try repository.save(item)
        }

        XCTAssertEqual(try repository.fetchBlocks(on: day).map(\.title), ["Mañana", "Tarde"])
    }

    func test_save_existingBlock_updatesWithoutDuplicating() throws {
        let repository = try makeRepository()
        var item = try block("Borrador", 540)
        try repository.save(item)

        try item.update(title: "Definitivo", kind: .work, startMinute: 600, endMinute: 720, now: created)
        try repository.save(item)

        XCTAssertEqual(try repository.fetchBlocks(on: day), [item])
    }
}
