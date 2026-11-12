import XCTest
@testable import LifeOS

/// Programador falso: registra lo que se le pide en lugar de usar iOS.
nonisolated final class FakeNotificationScheduler: NotificationScheduler, @unchecked Sendable {
    var status: ReminderAuthorization
    var grantsPermission: Bool
    private(set) var permissionRequests = 0
    private(set) var scheduled: [PlannedNotification] = []

    init(status: ReminderAuthorization = .notDetermined, grantsPermission: Bool = true) {
        self.status = status
        self.grantsPermission = grantsPermission
    }

    func authorizationStatus() async -> ReminderAuthorization { status }

    func requestAuthorization() async -> Bool {
        permissionRequests += 1
        status = grantsPermission ? .authorized : .denied
        return grantsPermission
    }

    func replaceAll(with notifications: [PlannedNotification]) async {
        scheduled = notifications
    }
}

@MainActor
final class RemindersViewModelTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    /// 15 de enero de 2027, 08:00 GMT.
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeSUT(
        scheduler: FakeNotificationScheduler = FakeNotificationScheduler(),
        store: InMemoryReminderSettingsStore = InMemoryReminderSettingsStore()
    ) throws -> (RemindersViewModel, FakeNotificationScheduler, any TimeBlockRepository) {
        let blocks = try AppDependencies(inMemory: true).timeBlockRepository
        let fixedNow = start
        let viewModel = RemindersViewModel(
            store: store,
            scheduler: scheduler,
            blockRepository: blocks,
            calendar: calendar
        ) { fixedNow }
        return (viewModel, scheduler, blocks)
    }

    private func enablingHabits(_ settings: ReminderSettings) -> ReminderSettings {
        var copy = settings
        copy.habitsEnabled = true
        return copy
    }

    func test_load_withNothingEnabled_doesNotAskPermission() async throws {
        let (viewModel, scheduler, _) = try makeSUT()

        await viewModel.load()

        XCTAssertEqual(scheduler.permissionRequests, 0)
        XCTAssertTrue(scheduler.scheduled.isEmpty)
    }

    func test_enablingFirstReminder_asksPermissionAndSchedules() async throws {
        let store = InMemoryReminderSettingsStore()
        let (viewModel, scheduler, _) = try makeSUT(store: store)
        await viewModel.load()

        await viewModel.update(enablingHabits(viewModel.settings))

        XCTAssertEqual(scheduler.permissionRequests, 1)
        XCTAssertEqual(viewModel.authorization, .authorized)
        XCTAssertEqual(scheduler.scheduled.map(\.id), ["lifeos.habits"])
        XCTAssertTrue(store.load().habitsEnabled)
    }

    func test_deniedPermission_turnsEverythingOff() async throws {
        let (viewModel, scheduler, _) = try makeSUT(scheduler: FakeNotificationScheduler(grantsPermission: false))
        await viewModel.load()

        await viewModel.update(enablingHabits(viewModel.settings))

        XCTAssertTrue(viewModel.isDenied)
        XCTAssertFalse(viewModel.settings.habitsEnabled)
        XCTAssertTrue(scheduler.scheduled.isEmpty)
    }

    func test_alreadyDenied_doesNotAskAgain() async throws {
        let (viewModel, scheduler, _) = try makeSUT(scheduler: FakeNotificationScheduler(status: .denied))
        await viewModel.load()

        await viewModel.update(enablingHabits(viewModel.settings))

        XCTAssertEqual(scheduler.permissionRequests, 0)
        XCTAssertFalse(viewModel.settings.habitsEnabled)
    }

    func test_blockAlerts_includeTodayAndTomorrow() async throws {
        let (viewModel, scheduler, blocks) = try makeSUT(scheduler: FakeNotificationScheduler(status: .authorized))
        let today = LocalDay(start, calendar: calendar)
        let tomorrow = try XCTUnwrap(today.adding(days: 1, calendar: calendar))
        let dayAfter = try XCTUnwrap(today.adding(days: 2, calendar: calendar))
        for (title, day) in [("Hoy", today), ("Mañana", tomorrow), ("Pasado", dayAfter)] {
            try blocks.save(try TimeBlock(day: day, title: title, kind: .study,
                                          startMinute: 600, endMinute: 660, now: start))
        }
        await viewModel.load()

        var settings = viewModel.settings
        settings.blockAlertsEnabled = true
        await viewModel.update(settings)

        XCTAssertEqual(scheduler.scheduled.map(\.title), ["Hoy", "Mañana"])
    }

    func test_disablingEverything_clearsScheduled() async throws {
        let (viewModel, scheduler, _) = try makeSUT(scheduler: FakeNotificationScheduler(status: .authorized))
        await viewModel.load()
        await viewModel.update(enablingHabits(viewModel.settings))
        XCTAssertFalse(scheduler.scheduled.isEmpty)

        await viewModel.update(viewModel.settings.disablingAll())

        XCTAssertTrue(scheduler.scheduled.isEmpty)
    }
}
