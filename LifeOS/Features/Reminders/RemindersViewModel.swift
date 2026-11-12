import Foundation
import Observation

/// Preferencias de recordatorios, permiso de iOS y programación de avisos.
@Observable
final class RemindersViewModel {
    private(set) var settings: ReminderSettings
    private(set) var authorization: ReminderAuthorization = .notDetermined

    private let store: any ReminderSettingsStore
    private let scheduler: any NotificationScheduler
    private let blockRepository: any TimeBlockRepository
    private let calendar: Calendar
    private let now: () -> Date

    init(
        store: any ReminderSettingsStore,
        scheduler: any NotificationScheduler,
        blockRepository: any TimeBlockRepository,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.settings = store.load()
        self.store = store
        self.scheduler = scheduler
        self.blockRepository = blockRepository
        self.calendar = calendar
        self.now = now
    }

    /// Ver D-013.
    nonisolated deinit {}

    var isDenied: Bool { authorization == .denied }

    // MARK: - Enlaces para la interfaz
    // Cada cambio se refleja al instante y luego se confirma (permiso, guardado
    // y reprogramación) en segundo plano.

    var habitsEnabled: Bool {
        get { settings.habitsEnabled }
        set { change { $0.habitsEnabled = newValue } }
    }

    var habitsTime: Date {
        get { date(for: settings.habitsMinute) }
        set { change { $0.habitsMinute = MinuteOfDay.from(newValue, calendar: calendar) } }
    }

    var checkInEnabled: Bool {
        get { settings.checkInEnabled }
        set { change { $0.checkInEnabled = newValue } }
    }

    var checkInTime: Date {
        get { date(for: settings.checkInMinute) }
        set { change { $0.checkInMinute = MinuteOfDay.from(newValue, calendar: calendar) } }
    }

    var blockAlertsEnabled: Bool {
        get { settings.blockAlertsEnabled }
        set { change { $0.blockAlertsEnabled = newValue } }
    }

    var blockLeadMinutes: Int {
        get { settings.blockLeadMinutes }
        set { change { $0.blockLeadMinutes = newValue } }
    }

    // MARK: - Acciones

    /// Lee las preferencias y el permiso actual (el usuario pudo cambiarlo en
    /// los Ajustes del iPhone) y reprograma los avisos.
    func load() async {
        settings = store.load()
        authorization = await scheduler.authorizationStatus()
        await reschedule()
    }

    /// Aplica unas preferencias nuevas. Si activan algo y no hay permiso, lo
    /// pide; si el usuario lo deniega, todo vuelve a apagado.
    func update(_ newSettings: ReminderSettings) async {
        var next = newSettings
        if next.anyEnabled && authorization != .authorized {
            if authorization == .notDetermined {
                let granted = await scheduler.requestAuthorization()
                authorization = granted ? .authorized : .denied
            }
            if authorization != .authorized {
                next = next.disablingAll()
            }
        }
        settings = next
        store.save(next)
        await reschedule()
    }

    /// Recalcula todos los avisos: hábitos, check-in y bloques de hoy y mañana.
    func reschedule() async {
        guard authorization == .authorized, settings.anyEnabled else {
            await scheduler.replaceAll(with: [])
            return
        }
        let current = now()
        let today = LocalDay(current, calendar: calendar)
        var blocks = (try? blockRepository.fetchBlocks(on: today)) ?? []
        if let tomorrow = today.adding(days: 1, calendar: calendar) {
            blocks += (try? blockRepository.fetchBlocks(on: tomorrow)) ?? []
        }
        let plan = ReminderPlanner(calendar: calendar).plan(settings: settings, blocks: blocks, now: current)
        await scheduler.replaceAll(with: plan)
    }

    // MARK: - Privado

    private func change(_ edit: (inout ReminderSettings) -> Void) {
        var next = settings
        edit(&next)
        settings = next
        Task {
            await update(next)
        }
    }

    private func date(for minute: Int) -> Date {
        let current = now()
        return MinuteOfDay.date(minute, on: LocalDay(current, calendar: calendar), calendar: calendar) ?? current
    }
}
