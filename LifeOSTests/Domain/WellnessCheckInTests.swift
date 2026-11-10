import XCTest
@testable import LifeOS

@MainActor
final class WellnessCheckInTests: XCTestCase {
    private let created = Date(timeIntervalSince1970: 1_800_000_000)
    private let day = LocalDay(year: 2026, month: 1, day: 15)

    private func make(
        energy: Int = 3, mood: Int = 3, stress: Int = 3,
        sleep: Double? = nil, note: String? = nil
    ) throws -> WellnessCheckIn {
        try WellnessCheckIn(day: day, energy: energy, mood: mood, stress: stress,
                            sleepHours: sleep, note: note, now: created)
    }

    func test_init_storesValuesAndTrimsNote() throws {
        let checkIn = try make(energy: 4, mood: 5, stress: 1, sleep: 7.5, note: "  Buen día  ")

        XCTAssertEqual(checkIn.energy, 4)
        XCTAssertEqual(checkIn.mood, 5)
        XCTAssertEqual(checkIn.stress, 1)
        XCTAssertEqual(checkIn.sleepHours, 7.5)
        XCTAssertEqual(checkIn.note, "Buen día")
        XCTAssertEqual(checkIn.day, day)
    }

    func test_init_blankNoteBecomesNil() throws {
        XCTAssertNil(try make(note: "   ").note)
    }

    func test_init_rejectsLevelsOutsideRange() {
        for level in [0, 6] {
            XCTAssertThrowsError(try make(energy: level)) {
                XCTAssertEqual($0 as? WellnessValidationError, .levelOutOfRange(1...5))
            }
            XCTAssertThrowsError(try make(mood: level))
            XCTAssertThrowsError(try make(stress: level))
        }
    }

    func test_init_rejectsInvalidSleepAndLongNote() {
        XCTAssertThrowsError(try make(sleep: -1)) {
            XCTAssertEqual($0 as? WellnessValidationError, .sleepOutOfRange(0...24))
        }
        XCTAssertThrowsError(try make(sleep: 24.5))
        XCTAssertThrowsError(try make(note: String(repeating: "a", count: 501))) {
            XCTAssertEqual($0 as? WellnessValidationError, .noteTooLong(maxLength: 500))
        }
    }

    func test_update_withInvalidData_leavesCheckInUnchanged() throws {
        var checkIn = try make()
        let original = checkIn

        XCTAssertThrowsError(
            try checkIn.update(energy: 9, mood: 3, stress: 3, sleepHours: nil, note: nil, now: created)
        )
        XCTAssertEqual(checkIn, original)
    }

    func test_markDeletedAndRestore() throws {
        var checkIn = try make()

        checkIn.markDeleted(at: created.addingTimeInterval(60))
        XCTAssertTrue(checkIn.isDeleted)

        checkIn.restore(at: created.addingTimeInterval(120))
        XCTAssertFalse(checkIn.isDeleted)
        XCTAssertEqual(checkIn.updatedAt, created.addingTimeInterval(120))
    }
}
