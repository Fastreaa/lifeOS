import Foundation
import SwiftData

/// Implementación de `TimeBlockRepository` con SwiftData (D-009, D-012).
nonisolated final class SwiftDataTimeBlockRepository: TimeBlockRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    @MainActor
    private var context: ModelContext { container.mainContext }

    @MainActor
    func fetchBlocks(on day: LocalDay) throws -> [TimeBlock] {
        let value = day.storageValue
        let descriptor = FetchDescriptor<TimeBlockRecord>(
            predicate: #Predicate { $0.deletedAt == nil && $0.dayValue == value },
            sortBy: [SortDescriptor(\.startMinute)]
        )
        return try context.fetch(descriptor).map { try $0.toDomain() }
    }

    @MainActor
    func save(_ block: TimeBlock) throws {
        let id = block.id
        var descriptor = FetchDescriptor<TimeBlockRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.apply(block)
        } else {
            context.insert(TimeBlockRecord(from: block))
        }
        try context.save()
    }
}
