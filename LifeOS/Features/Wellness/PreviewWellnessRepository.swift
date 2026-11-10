#if DEBUG
import Foundation

/// Repositorio en memoria para las vistas previas. Solo en desarrollo.
nonisolated final class PreviewWellnessRepository: WellnessRepository {
    private var storage: [UUID: WellnessCheckIn] = [:]

    init(checkIns: [WellnessCheckIn] = []) {
        for checkIn in checkIns { storage[checkIn.id] = checkIn }
    }

    @MainActor
    func fetchCheckIns(since day: LocalDay) throws -> [WellnessCheckIn] {
        storage.values.filter { !$0.isDeleted && $0.day >= day }.sorted { $0.day < $1.day }
    }

    @MainActor
    func checkIn(on day: LocalDay) throws -> WellnessCheckIn? {
        storage.values.first { $0.day == day }
    }

    @MainActor
    func save(_ checkIn: WellnessCheckIn) throws {
        storage[checkIn.id] = checkIn
    }

    static var sample: PreviewWellnessRepository {
        let calendar = Calendar.current
        let today = LocalDay(.now, calendar: calendar)
        let values: [(Int, Int, Int, Double)] = [(3, 4, 2, 7), (2, 3, 4, 6), (4, 4, 2, 8), (3, 3, 3, 7.5), (4, 5, 1, 8)]
        let checkIns = values.enumerated().compactMap { offset, value -> WellnessCheckIn? in
            guard let day = today.adding(days: -(offset + 1), calendar: calendar) else { return nil }
            return try? WellnessCheckIn(day: day, energy: value.0, mood: value.1, stress: value.2, sleepHours: value.3)
        }
        return PreviewWellnessRepository(checkIns: checkIns)
    }
}
#endif
