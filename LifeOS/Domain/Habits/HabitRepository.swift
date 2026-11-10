import Foundation

/// Contrato para guardar y leer hábitos y sus registros diarios.
@MainActor
protocol HabitRepository {
    /// Hábitos no borrados, ordenados por fecha de creación.
    func fetchHabits() throws -> [Habit]

    /// Crea o actualiza según el id. Borrar es guardar con `markDeleted()`.
    func save(_ habit: Habit) throws

    /// Registros activos (no borrados) desde ese día, incluido.
    func fetchLogs(since day: LocalDay) throws -> [HabitLog]

    /// El registro de ese hábito ese día, activo o no. `nil` si no existe.
    func log(habitID: UUID, day: LocalDay) throws -> HabitLog?

    /// Crea o actualiza el registro según su id.
    func save(_ log: HabitLog) throws
}
