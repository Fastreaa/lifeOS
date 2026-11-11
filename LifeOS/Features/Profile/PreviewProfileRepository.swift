#if DEBUG
import Foundation

/// Repositorio en memoria para las vistas previas. Solo en desarrollo.
nonisolated final class PreviewProfileRepository: ProfileRepository {
    private var stored: UserProfile?

    init(profile: UserProfile? = nil) {
        stored = profile
    }

    @MainActor
    func loadProfile() throws -> UserProfile? {
        stored
    }

    @MainActor
    func save(_ profile: UserProfile) throws {
        stored = profile
    }
}
#endif
