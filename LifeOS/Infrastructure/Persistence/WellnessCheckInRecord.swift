import Foundation
import SwiftData

/// Registro de bienestar en SwiftData. `nonisolated` por D-012.
@Model
nonisolated final class WellnessCheckInRecord {
    @Attribute(.unique) var id: UUID
    /// `LocalDay.storageValue`, por ejemplo 20261110.
    var dayValue: Int
    var energy: Int
    var mood: Int
    var stress: Int
    var sleepHours: Double?
    var note: String?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(from checkIn: WellnessCheckIn) {
        id = checkIn.id
        dayValue = checkIn.day.storageValue
        energy = checkIn.energy
        mood = checkIn.mood
        stress = checkIn.stress
        sleepHours = checkIn.sleepHours
        note = checkIn.note
        createdAt = checkIn.createdAt
        updatedAt = checkIn.updatedAt
        deletedAt = checkIn.deletedAt
    }

    func apply(_ checkIn: WellnessCheckIn) {
        energy = checkIn.energy
        mood = checkIn.mood
        stress = checkIn.stress
        sleepHours = checkIn.sleepHours
        note = checkIn.note
        updatedAt = checkIn.updatedAt
        deletedAt = checkIn.deletedAt
    }

    func toDomain() throws -> WellnessCheckIn {
        guard let day = LocalDay(storageValue: dayValue) else {
            throw WellnessRecordError.invalidDay(dayValue)
        }
        return try WellnessCheckIn(
            restoringID: id,
            day: day,
            energy: energy,
            mood: mood,
            stress: stress,
            sleepHours: sleepHours,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}

nonisolated enum WellnessRecordError: Error, Equatable, Sendable {
    case invalidDay(Int)
}
