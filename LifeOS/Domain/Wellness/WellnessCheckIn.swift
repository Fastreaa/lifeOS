import Foundation

nonisolated enum WellnessValidationError: Error, Equatable, Sendable {
    case levelOutOfRange(ClosedRange<Int>)
    case sleepOutOfRange(ClosedRange<Double>)
    case noteTooLong(maxLength: Int)
}

/// Registro diario de cómo te sientes. Uno por día (`LocalDay`).
///
/// Son datos personales y sensibles: no se envían a ningún sitio ni se
/// escriben en logs. No son un diagnóstico clínico.
nonisolated struct WellnessCheckIn: Identifiable, Equatable, Sendable {
    static let levelRange = 1...5
    static let sleepRange: ClosedRange<Double> = 0...24
    static let maxNoteLength = 500

    let id: UUID
    let day: LocalDay
    private(set) var energy: Int
    private(set) var mood: Int
    private(set) var stress: Int
    private(set) var sleepHours: Double?
    private(set) var note: String?
    let createdAt: Date
    private(set) var updatedAt: Date
    private(set) var deletedAt: Date?

    var isDeleted: Bool { deletedAt != nil }

    init(
        id: UUID = UUID(),
        day: LocalDay,
        energy: Int,
        mood: Int,
        stress: Int,
        sleepHours: Double? = nil,
        note: String? = nil,
        now: Date = .now
    ) throws {
        self.id = id
        self.day = day
        self.energy = try Self.validatedLevel(energy)
        self.mood = try Self.validatedLevel(mood)
        self.stress = try Self.validatedLevel(stress)
        self.sleepHours = try Self.validatedSleep(sleepHours)
        self.note = try Self.validatedNote(note)
        self.createdAt = now
        self.updatedAt = now
        self.deletedAt = nil
    }

    init(
        restoringID id: UUID,
        day: LocalDay,
        energy: Int,
        mood: Int,
        stress: Int,
        sleepHours: Double?,
        note: String?,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date?
    ) throws {
        self.id = id
        self.day = day
        self.energy = try Self.validatedLevel(energy)
        self.mood = try Self.validatedLevel(mood)
        self.stress = try Self.validatedLevel(stress)
        self.sleepHours = try Self.validatedSleep(sleepHours)
        self.note = try Self.validatedNote(note)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    /// Si algún dato es inválido, lanza un error y el registro no cambia.
    mutating func update(
        energy: Int,
        mood: Int,
        stress: Int,
        sleepHours: Double?,
        note: String?,
        now: Date = .now
    ) throws {
        let validEnergy = try Self.validatedLevel(energy)
        let validMood = try Self.validatedLevel(mood)
        let validStress = try Self.validatedLevel(stress)
        let validSleep = try Self.validatedSleep(sleepHours)
        let validNote = try Self.validatedNote(note)

        self.energy = validEnergy
        self.mood = validMood
        self.stress = validStress
        self.sleepHours = validSleep
        self.note = validNote
        self.updatedAt = now
    }

    mutating func markDeleted(at now: Date = .now) {
        guard deletedAt == nil else { return }
        deletedAt = now
        updatedAt = now
    }

    mutating func restore(at now: Date = .now) {
        guard deletedAt != nil else { return }
        deletedAt = nil
        updatedAt = now
    }

    // MARK: - Reglas

    private static func validatedLevel(_ level: Int) throws -> Int {
        guard levelRange.contains(level) else {
            throw WellnessValidationError.levelOutOfRange(levelRange)
        }
        return level
    }

    private static func validatedSleep(_ hours: Double?) throws -> Double? {
        guard let hours else { return nil }
        guard sleepRange.contains(hours) else {
            throw WellnessValidationError.sleepOutOfRange(sleepRange)
        }
        return hours
    }

    private static func validatedNote(_ note: String?) throws -> String? {
        guard let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        guard trimmed.count <= maxNoteLength else {
            throw WellnessValidationError.noteTooLong(maxLength: maxNoteLength)
        }
        return trimmed
    }
}
