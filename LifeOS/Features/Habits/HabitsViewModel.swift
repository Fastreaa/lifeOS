import Foundation
import Observation

/// Un hábito junto con su progreso calculado, listo para mostrar.
nonisolated struct HabitOverview: Identifiable, Equatable, Sendable {
    let habit: Habit
    let progress: HabitProgress
    var id: UUID { habit.id }
}

/// Estado de la pantalla de hábitos y acciones sobre ella.
@Observable
final class HabitsViewModel {
    private(set) var items: [HabitOverview] = []
    private(set) var errorMessage: String?

    private let repository: any HabitRepository
    private let calendar: Calendar
    private let now: () -> Date

    init(
        repository: any HabitRepository,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.repository = repository
        self.calendar = calendar
        self.now = now
    }

    /// Ver D-013.
    nonisolated deinit {}

    // MARK: - Estado derivado

    var isEmpty: Bool { items.isEmpty }

    var scheduledTodayCount: Int {
        items.filter(\.progress.isScheduledToday).count
    }

    var completedTodayCount: Int {
        items.filter { $0.progress.isScheduledToday && $0.progress.isCompletedToday }.count
    }

    /// Hábitos que tocan hoy, para el dashboard.
    var todayItems: [HabitOverview] {
        items.filter(\.progress.isScheduledToday)
    }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    // MARK: - Acciones

    func load() {
        do {
            let today = LocalDay(now(), calendar: calendar)
            let since = today.adding(days: -HabitProgress.streakLookbackDays, calendar: calendar) ?? today
            let habits = try repository.fetchHabits()
            let logs = try repository.fetchLogs(since: since)
            let daysByHabit = Dictionary(grouping: logs, by: \.habitID)
                .mapValues { Set($0.map(\.day)) }

            items = habits.map { habit in
                HabitOverview(
                    habit: habit,
                    progress: HabitProgress(
                        habit: habit,
                        completedDays: daysByHabit[habit.id] ?? [],
                        today: today,
                        calendar: calendar
                    )
                )
            }
        } catch {
            errorMessage = String(localized: "No se pudieron cargar tus hábitos.")
        }
    }

    func create(_ draft: HabitDraft) throws {
        let habit = try Habit(
            name: draft.name,
            symbolName: draft.symbolName,
            weekdays: draft.weekdays,
            now: now()
        )
        try repository.save(habit)
        load()
    }

    func update(_ habit: Habit, with draft: HabitDraft) throws {
        var updated = habit
        try updated.update(
            name: draft.name,
            symbolName: draft.symbolName,
            weekdays: draft.weekdays,
            now: now()
        )
        try repository.save(updated)
        load()
    }

    func delete(_ habit: Habit) {
        var updated = habit
        updated.markDeleted(at: now())
        perform { try repository.save(updated) }
    }

    /// Marca el hábito como hecho hoy o, si ya lo estaba, lo desmarca.
    func toggleToday(_ habit: Habit) {
        let timestamp = now()
        let today = LocalDay(timestamp, calendar: calendar)
        perform {
            if var log = try repository.log(habitID: habit.id, day: today) {
                if log.isActive {
                    log.markDeleted(at: timestamp)
                } else {
                    log.restore(at: timestamp)
                }
                try repository.save(log)
            } else {
                try repository.save(HabitLog(habitID: habit.id, day: today, now: timestamp))
            }
        }
    }

    // MARK: - Privado

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
            load()
        } catch {
            errorMessage = String(localized: "No se pudo guardar el cambio. Inténtalo de nuevo.")
        }
    }
}
