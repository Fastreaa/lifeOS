import XCTest
@testable import LifeOS

/// Pruebas con una base de datos en memoria: cada prueba crea la suya y
/// desaparece al terminar.
@MainActor
final class SwiftDataTaskRepositoryTests: XCTestCase {
    private let created = Date(timeIntervalSince1970: 1_800_000_000)

    /// Devuelve las dependencias completas: hay que mantenerlas vivas durante
    /// la prueba, porque el repositorio depende del contenedor.
    private func makeDependencies() throws -> AppDependencies {
        try AppDependencies(inMemory: true)
    }

    // MARK: - Guardar y leer

    func test_save_thenFetch_returnsTask() throws {
        let deps = try makeDependencies()
        let task = try TaskItem(title: "Entregar práctica", now: created)

        try deps.taskRepository.save(task)

        XCTAssertEqual(try deps.taskRepository.fetchTasks(), [task])
    }

    func test_roundTrip_preservesAllFields() throws {
        let deps = try makeDependencies()
        var task = try TaskItem(
            title: "Preparar examen",
            notes: "Temas 1 a 4",
            priority: .high,
            dueDate: created.addingTimeInterval(86_400),
            estimatedMinutes: 120,
            now: created
        )
        task.complete(at: created.addingTimeInterval(60))

        try deps.taskRepository.save(task)

        XCTAssertEqual(try deps.taskRepository.task(withID: task.id), task)
    }

    func test_fetch_onEmptyStore_returnsEmptyList() throws {
        let deps = try makeDependencies()
        XCTAssertEqual(try deps.taskRepository.fetchTasks(), [])
    }

    func test_fetch_sortsByCreationDate() throws {
        let deps = try makeDependencies()
        let newer = try TaskItem(title: "Segunda", now: created.addingTimeInterval(60))
        let older = try TaskItem(title: "Primera", now: created)

        try deps.taskRepository.save(newer)
        try deps.taskRepository.save(older)

        let titles = try deps.taskRepository.fetchTasks().map(\.title)
        XCTAssertEqual(titles, ["Primera", "Segunda"])
    }

    // MARK: - Actualizar

    func test_save_existingTask_updatesWithoutDuplicating() throws {
        let deps = try makeDependencies()
        var task = try TaskItem(title: "Borrador", now: created)
        try deps.taskRepository.save(task)

        try task.update(
            title: "Versión final",
            notes: nil,
            priority: .high,
            dueDate: nil,
            estimatedMinutes: 30,
            now: created.addingTimeInterval(60)
        )
        try deps.taskRepository.save(task)

        let tasks = try deps.taskRepository.fetchTasks()
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first, task)
    }

    // MARK: - Borrado lógico

    func test_fetch_excludesDeletedTasks() throws {
        let deps = try makeDependencies()
        let kept = try TaskItem(title: "Se queda", now: created)
        var removed = try TaskItem(title: "Se va", now: created)
        try deps.taskRepository.save(kept)
        try deps.taskRepository.save(removed)

        removed.markDeleted(at: created.addingTimeInterval(60))
        try deps.taskRepository.save(removed)

        XCTAssertEqual(try deps.taskRepository.fetchTasks(), [kept])
    }

    func test_taskWithID_returnsDeletedTask() throws {
        let deps = try makeDependencies()
        var task = try TaskItem(title: "Borrada", now: created)
        task.markDeleted(at: created)
        try deps.taskRepository.save(task)

        let stored = try deps.taskRepository.task(withID: task.id)
        XCTAssertEqual(stored?.isDeleted, true)
    }

    func test_taskWithID_unknownID_returnsNil() throws {
        let deps = try makeDependencies()
        XCTAssertNil(try deps.taskRepository.task(withID: UUID()))
    }

    // MARK: - Datos corruptos

    func test_toDomain_withInvalidPriority_throws() throws {
        let record = TaskRecord(from: try TaskItem(title: "x", now: created))
        record.priorityRawValue = 99

        XCTAssertThrowsError(try record.toDomain()) { error in
            XCTAssertEqual(error as? TaskRecordError, .invalidPriority(99))
        }
    }
}
