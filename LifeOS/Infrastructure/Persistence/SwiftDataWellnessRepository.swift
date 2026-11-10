import Foundation
import SwiftData

/// Implementación de `WellnessRepository` con SwiftData (D-009, D-012).
nonisolated final class SwiftDataWellnessRepository: WellnessRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    @MainActor
    private var context: ModelContext { container.mainContext }

    @MainActor
    func fetchCheckIns(since day: LocalDay) throws -> [WellnessCheckIn] {
        let start = day.storageValue
        let descriptor = FetchDescriptor<WellnessCheckInRecord>(
            predicate: #Predicate { $0.deletedAt == nil && $0.dayValue >= start },
            sortBy: [SortDescriptor(\.dayValue)]
        )
        return try context.fetch(descriptor).map { try $0.toDomain() }
    }

    @MainActor
    func checkIn(on day: LocalDay) throws -> WellnessCheckIn? {
        let value = day.storageValue
        var descriptor = FetchDescriptor<WellnessCheckInRecord>(
            predicate: #Predicate { $0.dayValue == value }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.toDomain()
    }

    @MainActor
    func save(_ checkIn: WellnessCheckIn) throws {
        let id = checkIn.id
        var descriptor = FetchDescriptor<WellnessCheckInRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.apply(checkIn)
        } else {
            context.insert(WellnessCheckInRecord(from: checkIn))
        }
        try context.save()
    }
}
