import Foundation
import SwiftData

/// Implementación de `ProfileRepository` con SwiftData (D-009, D-012).
nonisolated final class SwiftDataProfileRepository: ProfileRepository {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    @MainActor
    private var context: ModelContext { container.mainContext }

    @MainActor
    func loadProfile() throws -> UserProfile? {
        var descriptor = FetchDescriptor<UserProfileRecord>(sortBy: [SortDescriptor(\.createdAt)])
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.toDomain()
    }

    @MainActor
    func save(_ profile: UserProfile) throws {
        let id = profile.id
        var descriptor = FetchDescriptor<UserProfileRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.apply(profile)
        } else {
            context.insert(UserProfileRecord(from: profile))
        }
        try context.save()
    }
}
