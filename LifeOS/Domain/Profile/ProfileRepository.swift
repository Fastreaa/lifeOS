import Foundation

/// Contrato para guardar y leer el perfil del usuario.
@MainActor
protocol ProfileRepository {
    /// El perfil guardado, o `nil` si todavía no existe.
    func loadProfile() throws -> UserProfile?

    /// Crea o actualiza el perfil según su id.
    func save(_ profile: UserProfile) throws
}
