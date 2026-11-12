import Foundation

/// Colores disponibles para un proyecto. El valor de texto es el que se guarda.
nonisolated enum ProjectColor: String, CaseIterable, Sendable {
    case teal
    case blue
    case orange
    case purple
    case pink
    case green
    case gray
}

nonisolated enum ProjectValidationError: Error, Equatable, Sendable {
    case emptyName
    case nameTooLong(maxLength: Int)
    case missingSymbol
}

/// Un proyecto agrupa tareas. Sirve tanto para algo con final ("Proyecto
/// final APPS") como para un área permanente ("Universidad", "Casa"): ver D-022.
nonisolated struct Project: Identifiable, Equatable, Sendable {
    static let maxNameLength = 40

    let id: UUID
    private(set) var name: String
    private(set) var symbolName: String
    private(set) var color: ProjectColor
    let createdAt: Date
    private(set) var updatedAt: Date
    private(set) var deletedAt: Date?

    var isDeleted: Bool { deletedAt != nil }

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String = "folder",
        color: ProjectColor = .teal,
        now: Date = .now
    ) throws {
        self.id = id
        self.name = try Self.validatedName(name)
        self.symbolName = try Self.validatedSymbol(symbolName)
        self.color = color
        self.createdAt = now
        self.updatedAt = now
        self.deletedAt = nil
    }

    init(
        restoringID id: UUID,
        name: String,
        symbolName: String,
        color: ProjectColor,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date?
    ) throws {
        self.id = id
        self.name = try Self.validatedName(name)
        self.symbolName = try Self.validatedSymbol(symbolName)
        self.color = color
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    /// Si algún dato es inválido, lanza un error y el proyecto no cambia.
    mutating func update(name: String, symbolName: String, color: ProjectColor, now: Date = .now) throws {
        let validName = try Self.validatedName(name)
        let validSymbol = try Self.validatedSymbol(symbolName)
        self.name = validName
        self.symbolName = validSymbol
        self.color = color
        self.updatedAt = now
    }

    mutating func markDeleted(at now: Date = .now) {
        guard deletedAt == nil else { return }
        deletedAt = now
        updatedAt = now
    }

    private static func validatedName(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ProjectValidationError.emptyName }
        guard trimmed.count <= maxNameLength else {
            throw ProjectValidationError.nameTooLong(maxLength: maxNameLength)
        }
        return trimmed
    }

    private static func validatedSymbol(_ symbol: String) throws -> String {
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ProjectValidationError.missingSymbol }
        return trimmed
    }
}

/// Progreso de un proyecto a partir de sus tareas. Lógica pura.
nonisolated struct ProjectProgress: Equatable, Sendable {
    let pendingCount: Int
    let completedCount: Int
    /// Minutos estimados de las tareas pendientes.
    let pendingMinutes: Int

    var totalCount: Int { pendingCount + completedCount }

    /// De 0 a 1. Un proyecto sin tareas tiene progreso 0.
    var fraction: Double {
        totalCount == 0 ? 0 : Double(completedCount) / Double(totalCount)
    }

    init(projectID: UUID, tasks: [TaskItem]) {
        let own = tasks.filter { $0.projectID == projectID && !$0.isDeleted }
        pendingCount = own.filter { !$0.isCompleted }.count
        completedCount = own.filter(\.isCompleted).count
        pendingMinutes = own.filter { !$0.isCompleted }.compactMap(\.estimatedMinutes).reduce(0, +)
    }
}
