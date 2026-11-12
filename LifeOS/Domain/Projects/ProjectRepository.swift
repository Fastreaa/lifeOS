import Foundation

/// Contrato para guardar y leer proyectos.
@MainActor
protocol ProjectRepository {
    /// Proyectos no borrados, ordenados por fecha de creación.
    func fetchProjects() throws -> [Project]

    /// Crea o actualiza según el id. Borrar es guardar con `markDeleted()`.
    func save(_ project: Project) throws
}
