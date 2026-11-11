import Foundation

/// Tipo de bloque. El valor de texto es el que se guarda.
nonisolated enum BlockKind: String, CaseIterable, Sendable {
    case classSession = "class"
    case work
    case study
    case exercise
    case rest
    case personal
    case other
}

nonisolated enum TimeBlockValidationError: Error, Equatable, Sendable {
    case emptyTitle
    case titleTooLong(maxLength: Int)
    case invalidTimeRange
    case tooShort(minimumMinutes: Int)
}

/// Un bloque de tiempo en la agenda de un día: de `startMinute` a `endMinute`.
/// v1: no cruza la medianoche (ver D-019).
nonisolated struct TimeBlock: Identifiable, Equatable, Sendable {
    static let maxTitleLength = 60
    static let minimumMinutes = 5

    let id: UUID
    let day: LocalDay
    private(set) var title: String
    private(set) var kind: BlockKind
    private(set) var startMinute: Int
    private(set) var endMinute: Int
    let createdAt: Date
    private(set) var updatedAt: Date
    private(set) var deletedAt: Date?

    var durationMinutes: Int { endMinute - startMinute }
    var isDeleted: Bool { deletedAt != nil }

    init(
        id: UUID = UUID(),
        day: LocalDay,
        title: String,
        kind: BlockKind,
        startMinute: Int,
        endMinute: Int,
        now: Date = .now
    ) throws {
        self.id = id
        self.day = day
        self.title = try Self.validatedTitle(title)
        self.kind = kind
        try Self.validateRange(start: startMinute, end: endMinute)
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.createdAt = now
        self.updatedAt = now
        self.deletedAt = nil
    }

    init(
        restoringID id: UUID,
        day: LocalDay,
        title: String,
        kind: BlockKind,
        startMinute: Int,
        endMinute: Int,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date?
    ) throws {
        self.id = id
        self.day = day
        self.title = try Self.validatedTitle(title)
        self.kind = kind
        try Self.validateRange(start: startMinute, end: endMinute)
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    /// Si algún dato es inválido, lanza un error y el bloque no cambia.
    mutating func update(
        title: String,
        kind: BlockKind,
        startMinute: Int,
        endMinute: Int,
        now: Date = .now
    ) throws {
        let validTitle = try Self.validatedTitle(title)
        try Self.validateRange(start: startMinute, end: endMinute)

        self.title = validTitle
        self.kind = kind
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.updatedAt = now
    }

    mutating func markDeleted(at now: Date = .now) {
        guard deletedAt == nil else { return }
        deletedAt = now
        updatedAt = now
    }

    /// Dos bloques se solapan si comparten algún minuto. Que uno termine justo
    /// cuando empieza el otro (10:00–11:00 y 11:00–12:00) no es solaparse.
    func overlaps(_ other: TimeBlock) -> Bool {
        other.id != id
            && other.day == day
            && startMinute < other.endMinute
            && other.startMinute < endMinute
    }

    // MARK: - Reglas

    private static func validatedTitle(_ title: String) throws -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TimeBlockValidationError.emptyTitle }
        guard trimmed.count <= maxTitleLength else {
            throw TimeBlockValidationError.titleTooLong(maxLength: maxTitleLength)
        }
        return trimmed
    }

    private static func validateRange(start: Int, end: Int) throws {
        guard start >= 0, end <= MinuteOfDay.endOfDay, end > start else {
            throw TimeBlockValidationError.invalidTimeRange
        }
        guard end - start >= minimumMinutes else {
            throw TimeBlockValidationError.tooShort(minimumMinutes: minimumMinutes)
        }
    }
}
