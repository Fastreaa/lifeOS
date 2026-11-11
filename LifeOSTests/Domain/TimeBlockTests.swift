import XCTest
@testable import LifeOS

@MainActor
final class TimeBlockTests: XCTestCase {
    private let day = LocalDay(year: 2026, month: 1, day: 15)
    private let created = Date(timeIntervalSince1970: 1_800_000_000)

    private func block(_ start: Int, _ end: Int, title: String = "Bloque", kind: BlockKind = .study) throws -> TimeBlock {
        try TimeBlock(day: day, title: title, kind: kind, startMinute: start, endMinute: end, now: created)
    }

    func test_init_trimsTitleAndComputesDuration() throws {
        let item = try block(540, 660, title: "  Clase  ")

        XCTAssertEqual(item.title, "Clase")
        XCTAssertEqual(item.durationMinutes, 120)
    }

    func test_init_rejectsInvalidRanges() {
        XCTAssertThrowsError(try block(600, 600)) {
            XCTAssertEqual($0 as? TimeBlockValidationError, .invalidTimeRange)
        }
        XCTAssertThrowsError(try block(600, 540))
        XCTAssertThrowsError(try block(-1, 60))
        XCTAssertThrowsError(try block(1400, 1441))
        XCTAssertThrowsError(try block(600, 603)) {
            XCTAssertEqual($0 as? TimeBlockValidationError, .tooShort(minimumMinutes: 5))
        }
    }

    func test_init_allowsBlockUntilMidnight() throws {
        XCTAssertEqual(try block(1380, 1440).durationMinutes, 60)
    }

    func test_init_rejectsBlankTitle() {
        XCTAssertThrowsError(try block(540, 600, title: "  ")) {
            XCTAssertEqual($0 as? TimeBlockValidationError, .emptyTitle)
        }
    }

    func test_overlaps_ignoresTouchingEdges() throws {
        let morning = try block(600, 660)
        XCTAssertTrue(morning.overlaps(try block(630, 700)))
        XCTAssertFalse(morning.overlaps(try block(660, 720)))
        XCTAssertFalse(morning.overlaps(morning))
    }

    func test_update_withInvalidRange_leavesBlockUnchanged() throws {
        var item = try block(540, 600)
        let original = item

        XCTAssertThrowsError(try item.update(title: "Otro", kind: .work, startMinute: 700, endMinute: 650, now: created))
        XCTAssertEqual(item, original)
    }
}
