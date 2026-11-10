import Foundation

/// Contrato para guardar y leer los registros de bienestar.
@MainActor
protocol WellnessRepository {
    /// Registros activos desde ese día (incluido), ordenados por día.
    func fetchCheckIns(since day: LocalDay) throws -> [WellnessCheckIn]

    /// El registro de ese día, activo o borrado. `nil` si no existe.
    func checkIn(on day: LocalDay) throws -> WellnessCheckIn?

    /// Crea o actualiza según el id.
    func save(_ checkIn: WellnessCheckIn) throws
}
