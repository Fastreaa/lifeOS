import Foundation
import SwiftData

/// Bloque de agenda en SwiftData. `nonisolated` por D-012.
@Model
nonisolated final class TimeBlockRecord {
    @Attribute(.unique) var id: UUID
    /// `LocalDay.storageValue`, por ejemplo 20261110.
    var dayValue: Int
    var title: String
    var kindRawValue: String
    var startMinute: Int
    var endMinute: Int
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(from block: TimeBlock) {
        id = block.id
        dayValue = block.day.storageValue
        title = block.title
        kindRawValue = block.kind.rawValue
        startMinute = block.startMinute
        endMinute = block.endMinute
        createdAt = block.createdAt
        updatedAt = block.updatedAt
        deletedAt = block.deletedAt
    }

    func apply(_ block: TimeBlock) {
        title = block.title
        kindRawValue = block.kind.rawValue
        startMinute = block.startMinute
        endMinute = block.endMinute
        updatedAt = block.updatedAt
        deletedAt = block.deletedAt
    }

    /// Un tipo desconocido (por ejemplo, creado por una versión futura) se lee
    /// como `.other` en lugar de perder el bloque.
    func toDomain() throws -> TimeBlock {
        guard let day = LocalDay(storageValue: dayValue) else {
            throw TimeBlockRecordError.invalidDay(dayValue)
        }
        return try TimeBlock(
            restoringID: id,
            day: day,
            title: title,
            kind: BlockKind(rawValue: kindRawValue) ?? .other,
            startMinute: startMinute,
            endMinute: endMinute,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}

nonisolated enum TimeBlockRecordError: Error, Equatable, Sendable {
    case invalidDay(Int)
}
