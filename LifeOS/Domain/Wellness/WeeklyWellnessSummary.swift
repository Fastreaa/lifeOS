import Foundation

/// Un día de la ventana semanal, con su registro si existe.
nonisolated struct WellnessDayPoint: Identifiable, Equatable, Sendable {
    let day: LocalDay
    let checkIn: WellnessCheckIn?
    var id: Int { day.storageValue }
}

/// Resumen de los últimos 7 días (hoy incluido). Solo describe: no saca
/// conclusiones ni hace diagnósticos.
nonisolated struct WeeklyWellnessSummary: Equatable, Sendable {
    /// Siete días, del más antiguo a hoy.
    let points: [WellnessDayPoint]
    let loggedDays: Int
    let averageEnergy: Double?
    let averageMood: Double?
    let averageStress: Double?
    let averageSleepHours: Double?

    init(checkIns: [WellnessCheckIn], today: LocalDay, calendar: Calendar) {
        let byDay = Dictionary(
            checkIns.filter { !$0.isDeleted }.map { ($0.day, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let days = (0..<7).reversed().compactMap { today.adding(days: -$0, calendar: calendar) }
        points = days.map { WellnessDayPoint(day: $0, checkIn: byDay[$0]) }

        let logged = points.compactMap(\.checkIn)
        loggedDays = logged.count
        averageEnergy = Self.average(logged.map { Double($0.energy) })
        averageMood = Self.average(logged.map { Double($0.mood) })
        averageStress = Self.average(logged.map { Double($0.stress) })
        averageSleepHours = Self.average(logged.compactMap(\.sleepHours))
    }

    private static func average(_ values: [Double]) -> Double? {
        values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }
}
