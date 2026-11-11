import Foundation

/// Contrato para guardar y leer bloques de agenda.
@MainActor
protocol TimeBlockRepository {
    /// Bloques activos de ese día, ordenados por hora de inicio.
    func fetchBlocks(on day: LocalDay) throws -> [TimeBlock]

    /// Crea o actualiza según el id. Borrar es guardar con `markDeleted()`.
    func save(_ block: TimeBlock) throws
}
