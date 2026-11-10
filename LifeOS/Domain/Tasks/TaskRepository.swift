import Foundation

/// Contrato para guardar y leer tareas. El dominio y la interfaz dependen de
/// este protocolo, no de SwiftData.
///
/// v1: trabaja en el hilo principal (ver D-009). La sincronización en segundo
/// plano de la etapa 03 tendrá su propio acceso.
@MainActor
protocol TaskRepository {
    /// Todas las tareas no borradas, ordenadas por fecha de creación.
    /// Incluye las completadas.
    func fetchTasks() throws -> [TaskItem]

    /// La tarea con ese id, esté borrada o no. `nil` si no existe.
    func task(withID id: UUID) throws -> TaskItem?

    /// Crea la tarea si no existe o la actualiza si ya existe (mismo id).
    /// Es la única vía de escritura: borrar es guardar una tarea con
    /// `markDeleted()` aplicado.
    func save(_ task: TaskItem) throws
}
