import Foundation

nonisolated enum ProfileValidationError: Error, Equatable, Sendable {
    case nameTooLong(maxLength: Int)
    case invalidDayWindow
    case dayTooShort(minimumMinutes: Int)
}

/// Perfil y preferencias del usuario. Hay uno solo por dispositivo.
nonisolated struct UserProfile: Equatable, Sendable {
    static let maxNameLength = 40
    /// El día activo debe durar al menos 4 horas.
    static let minimumDayMinutes = 4 * 60
    static let defaultDayStart = 7 * 60
    static let defaultDayEnd = 23 * 60

    let id: UUID
    /// Nombre para el saludo. Opcional.
    private(set) var displayName: String?
    /// Hora habitual de levantarse, en minutos del día.
    private(set) var dayStartMinute: Int
    /// Hora habitual de acostarse, en minutos del día (1440 = medianoche).
    private(set) var dayEndMinute: Int
    private(set) var hasCompletedOnboarding: Bool
    let createdAt: Date
    private(set) var updatedAt: Date

    /// Ventana en la que la agenda calcula el tiempo libre.
    var dayWindow: ClosedRange<Int> { dayStartMinute...dayEndMinute }

    /// Perfil por defecto, antes de que el usuario configure nada.
    static func makeDefault(now: Date = .now) -> UserProfile {
        UserProfile(
            uncheckedID: UUID(),
            displayName: nil,
            dayStartMinute: defaultDayStart,
            dayEndMinute: defaultDayEnd,
            hasCompletedOnboarding: false,
            createdAt: now,
            updatedAt: now
        )
    }

    init(
        restoringID id: UUID,
        displayName: String?,
        dayStartMinute: Int,
        dayEndMinute: Int,
        hasCompletedOnboarding: Bool,
        createdAt: Date,
        updatedAt: Date
    ) throws {
        try Self.validateWindow(start: dayStartMinute, end: dayEndMinute)
        self.init(
            uncheckedID: id,
            displayName: try Self.validatedName(displayName),
            dayStartMinute: dayStartMinute,
            dayEndMinute: dayEndMinute,
            hasCompletedOnboarding: hasCompletedOnboarding,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private init(
        uncheckedID id: UUID,
        displayName: String?,
        dayStartMinute: Int,
        dayEndMinute: Int,
        hasCompletedOnboarding: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.displayName = displayName
        self.dayStartMinute = dayStartMinute
        self.dayEndMinute = dayEndMinute
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Si algún dato es inválido, lanza un error y el perfil no cambia.
    mutating func update(
        displayName: String?,
        dayStartMinute: Int,
        dayEndMinute: Int,
        now: Date = .now
    ) throws {
        let validName = try Self.validatedName(displayName)
        try Self.validateWindow(start: dayStartMinute, end: dayEndMinute)

        self.displayName = validName
        self.dayStartMinute = dayStartMinute
        self.dayEndMinute = dayEndMinute
        self.updatedAt = now
    }

    mutating func markOnboardingCompleted(at now: Date = .now) {
        guard !hasCompletedOnboarding else { return }
        hasCompletedOnboarding = true
        updatedAt = now
    }

    // MARK: - Reglas

    private static func validatedName(_ name: String?) throws -> String? {
        guard let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        guard trimmed.count <= maxNameLength else {
            throw ProfileValidationError.nameTooLong(maxLength: maxNameLength)
        }
        return trimmed
    }

    private static func validateWindow(start: Int, end: Int) throws {
        guard start >= 0, end <= MinuteOfDay.endOfDay, end > start else {
            throw ProfileValidationError.invalidDayWindow
        }
        guard end - start >= minimumDayMinutes else {
            throw ProfileValidationError.dayTooShort(minimumMinutes: minimumDayMinutes)
        }
    }
}
