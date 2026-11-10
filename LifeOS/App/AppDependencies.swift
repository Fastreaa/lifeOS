import Foundation
import SwiftData

/// Punto único donde se crean las piezas compartidas de la app
/// (base de datos, repositorios). Las vistas reciben lo que necesitan desde aquí.
///
/// Es un `struct` a propósito: no tiene `deinit`, así que liberarlo no anida
/// deinits aislados (ver D-012).
struct AppDependencies {
    let modelContainer: ModelContainer
    let taskRepository: any TaskRepository

    /// - Parameter inMemory: `true` en pruebas: la base de datos vive solo en
    ///   memoria y desaparece al terminar.
    init(inMemory: Bool = false) throws {
        let schema = Schema([TaskRecord.self])
        let configuration = ModelConfiguration(
            inMemory ? UUID().uuidString : nil,
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        taskRepository = SwiftDataTaskRepository(container: modelContainer)
    }
}
