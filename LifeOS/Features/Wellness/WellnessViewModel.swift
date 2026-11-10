import Foundation
import Observation

/// Estado de la pantalla de bienestar y acciones sobre ella.
@Observable
final class WellnessViewModel {
    /// Días de historial que se muestran (hoy incluido).
    static let historyDays = 14

    private(set) var today: LocalDay
    private(set) var todayCheckIn: WellnessCheckIn?
    /// Registros recientes, el más nuevo primero.
    private(set) var history: [WellnessCheckIn] = []
    private(set) var weekly: WeeklyWellnessSummary
    private(set) var errorMessage: String?

    private let repository: any WellnessRepository
    private let calendar: Calendar
    private let now: () -> Date

    init(
        repository: any WellnessRepository,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        let today = LocalDay(now(), calendar: calendar)
        self.repository = repository
        self.calendar = calendar
        self.now = now
        self.today = today
        self.weekly = WeeklyWellnessSummary(checkIns: [], today: today, calendar: calendar)
    }

    /// Ver D-013.
    nonisolated deinit {}

    /// Registros anteriores a hoy.
    var pastHistory: [WellnessCheckIn] {
        history.filter { $0.day != today }
    }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    // MARK: - Acciones

    func load() {
        today = LocalDay(now(), calendar: calendar)
        do {
            let since = today.adding(days: -(Self.historyDays - 1), calendar: calendar) ?? today
            let checkIns = try repository.fetchCheckIns(since: since)
            todayCheckIn = checkIns.first { $0.day == today }
            history = checkIns.sorted { $0.day > $1.day }
            weekly = WeeklyWellnessSummary(checkIns: checkIns, today: today, calendar: calendar)
        } catch {
            errorMessage = String(localized: "No se pudieron cargar tus registros.")
        }
    }

    /// Crea el registro de ese día o actualiza el que ya existe (uno por día).
    func save(_ draft: CheckInDraft, for day: LocalDay) throws {
        let timestamp = now()
        if var existing = try repository.checkIn(on: day) {
            existing.restore(at: timestamp)
            try existing.update(
                energy: draft.energy,
                mood: draft.mood,
                stress: draft.stress,
                sleepHours: draft.resolvedSleepHours,
                note: draft.note,
                now: timestamp
            )
            try repository.save(existing)
        } else {
            let checkIn = try WellnessCheckIn(
                day: day,
                energy: draft.energy,
                mood: draft.mood,
                stress: draft.stress,
                sleepHours: draft.resolvedSleepHours,
                note: draft.note,
                now: timestamp
            )
            try repository.save(checkIn)
        }
        load()
    }

    func delete(_ checkIn: WellnessCheckIn) {
        var updated = checkIn
        updated.markDeleted(at: now())
        do {
            try repository.save(updated)
            load()
        } catch {
            errorMessage = String(localized: "No se pudo borrar el registro. Inténtalo de nuevo.")
        }
    }
}
