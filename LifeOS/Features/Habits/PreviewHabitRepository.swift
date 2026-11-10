#if DEBUG
import Foundation

/// Repositorio en memoria para las vistas previas. Solo en desarrollo.
nonisolated final class PreviewHabitRepository: HabitRepository {
    private var habits: [UUID: Habit] = [:]
    private var logs: [UUID: HabitLog] = [:]

    init(habits: [Habit] = [], logs: [HabitLog] = []) {
        for habit in habits { self.habits[habit.id] = habit }
        for log in logs { self.logs[log.id] = log }
    }

    @MainActor
    func fetchHabits() throws -> [Habit] {
        habits.values.filter { !$0.isDeleted }.sorted { $0.createdAt < $1.createdAt }
    }

    @MainActor
    func save(_ habit: Habit) throws {
        habits[habit.id] = habit
    }

    @MainActor
    func fetchLogs(since day: LocalDay) throws -> [HabitLog] {
        logs.values.filter { $0.isActive && $0.day >= day }
    }

    @MainActor
    func log(habitID: UUID, day: LocalDay) throws -> HabitLog? {
        logs.values.first { $0.habitID == habitID && $0.day == day }
    }

    @MainActor
    func save(_ log: HabitLog) throws {
        logs[log.id] = log
    }

    static var sample: PreviewHabitRepository {
        let calendar = Calendar.current
        let today = LocalDay(.now, calendar: calendar)
        let created = Date.now.addingTimeInterval(-30 * 86_400)
        guard
            let water = try? Habit(name: "Beber 2 litros de agua", symbolName: "drop", now: created),
            let reading = try? Habit(name: "Leer 10 minutos", symbolName: "book", now: created),
            let gym = try? Habit(name: "Gimnasio", symbolName: "dumbbell", weekdays: [2, 4, 6], now: created)
        else {
            return PreviewHabitRepository()
        }
        let logs = (1...4).compactMap { offset -> HabitLog? in
            guard let day = today.adding(days: -offset, calendar: calendar) else { return nil }
            return HabitLog(habitID: water.id, day: day, now: created)
        }
        return PreviewHabitRepository(habits: [water, reading, gym], logs: logs)
    }
}
#endif
