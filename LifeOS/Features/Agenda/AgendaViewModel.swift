import Foundation
import Observation

/// Estado de la agenda: el día que se está viendo y, aparte, los bloques de
/// hoy (que usa el dashboard aunque estés mirando otro día).
@Observable
final class AgendaViewModel {
    private(set) var today: LocalDay
    private(set) var selectedDay: LocalDay
    /// Bloques del día que se está viendo.
    private(set) var blocks: [TimeBlock] = []
    /// Bloques de hoy, siempre actualizados.
    private(set) var todayBlocks: [TimeBlock] = []
    private(set) var errorMessage: String?

    private let repository: any TimeBlockRepository
    private let calendar: Calendar
    private let now: () -> Date

    init(
        repository: any TimeBlockRepository,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        let today = LocalDay(now(), calendar: calendar)
        self.repository = repository
        self.calendar = calendar
        self.now = now
        self.today = today
        self.selectedDay = today
    }

    /// Ver D-013.
    nonisolated deinit {}

    var isShowingToday: Bool { selectedDay == today }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    // MARK: - Análisis

    /// Plan del día que se está viendo. Las tareas solo cuentan si es hoy.
    func plan(taskMinutes: Int) -> DayPlan {
        DayPlan(blocks: blocks, taskMinutes: isShowingToday ? taskMinutes : 0)
    }

    func todayPlan(taskMinutes: Int) -> DayPlan {
        DayPlan(blocks: todayBlocks, taskMinutes: taskMinutes)
    }

    func upcomingToday(at date: Date) -> UpcomingBlock? {
        UpcomingBlock.find(in: todayBlocks, atMinute: MinuteOfDay.from(date, calendar: calendar))
    }

    // MARK: - Navegación

    func load() {
        let currentDay = LocalDay(now(), calendar: calendar)
        // Si estabas viendo "hoy" y cambió el día, seguir en el nuevo hoy.
        if selectedDay == today {
            selectedDay = currentDay
        }
        today = currentDay
        do {
            blocks = try repository.fetchBlocks(on: selectedDay)
            todayBlocks = isShowingToday ? blocks : try repository.fetchBlocks(on: today)
        } catch {
            errorMessage = String(localized: "No se pudo cargar tu agenda.")
        }
    }

    func showDay(offset: Int) {
        guard let day = selectedDay.adding(days: offset, calendar: calendar) else { return }
        selectedDay = day
        load()
    }

    func showToday() {
        selectedDay = today
        load()
    }

    // MARK: - Acciones

    func create(_ draft: BlockDraft) throws {
        let block = try TimeBlock(
            day: selectedDay,
            title: draft.title,
            kind: draft.kind,
            startMinute: MinuteOfDay.from(draft.start, calendar: calendar),
            endMinute: endMinute(for: draft.end),
            now: now()
        )
        try repository.save(block)
        load()
    }

    func update(_ block: TimeBlock, with draft: BlockDraft) throws {
        var updated = block
        try updated.update(
            title: draft.title,
            kind: draft.kind,
            startMinute: MinuteOfDay.from(draft.start, calendar: calendar),
            endMinute: endMinute(for: draft.end),
            now: now()
        )
        try repository.save(updated)
        load()
    }

    func delete(_ block: TimeBlock) {
        var updated = block
        updated.markDeleted(at: now())
        do {
            try repository.save(updated)
            load()
        } catch {
            errorMessage = String(localized: "No se pudo borrar el bloque. Inténtalo de nuevo.")
        }
    }

    /// Elegir 00:00 como fin significa "hasta medianoche".
    private func endMinute(for date: Date) -> Int {
        let minute = MinuteOfDay.from(date, calendar: calendar)
        return minute == 0 ? MinuteOfDay.endOfDay : minute
    }
}
