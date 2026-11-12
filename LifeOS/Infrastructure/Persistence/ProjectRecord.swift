import Foundation
import SwiftData

/// Proyecto en SwiftData. `nonisolated` por D-012.
@Model
nonisolated final class ProjectRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var symbolName: String
    var colorRawValue: String
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(from project: Project) {
        id = project.id
        name = project.name
        symbolName = project.symbolName
        colorRawValue = project.color.rawValue
        createdAt = project.createdAt
        updatedAt = project.updatedAt
        deletedAt = project.deletedAt
    }

    func apply(_ project: Project) {
        name = project.name
        symbolName = project.symbolName
        colorRawValue = project.color.rawValue
        updatedAt = project.updatedAt
        deletedAt = project.deletedAt
    }

    /// Un color desconocido (por ejemplo, de una versión futura) se lee como gris.
    func toDomain() throws -> Project {
        try Project(
            restoringID: id,
            name: name,
            symbolName: symbolName,
            color: ProjectColor(rawValue: colorRawValue) ?? .gray,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}
