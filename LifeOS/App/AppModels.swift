import Foundation

/// Los ViewModels de cada módulo. Se crean una sola vez al arrancar y se
/// comparten entre pestañas: un cambio en una se ve al instante en las demás.
struct AppModels {
    let taskList: TaskListViewModel
    let habits: HabitsViewModel
    let wellness: WellnessViewModel
    let agenda: AgendaViewModel
    let profile: ProfileViewModel
    let reminders: RemindersViewModel
    let projects: ProjectsViewModel

    /// - Parameter usesSystemNotifications: `false` en pruebas de interfaz: ni
    ///   diálogo de permiso ni notificaciones reales.
    init(
        dependencies: AppDependencies,
        suppressesOnboarding: Bool = false,
        usesSystemNotifications: Bool = true
    ) {
        taskList = TaskListViewModel(repository: dependencies.taskRepository)
        habits = HabitsViewModel(repository: dependencies.habitRepository)
        wellness = WellnessViewModel(repository: dependencies.wellnessRepository)
        agenda = AgendaViewModel(repository: dependencies.timeBlockRepository)
        profile = ProfileViewModel(
            repository: dependencies.profileRepository,
            suppressesOnboarding: suppressesOnboarding
        )
        reminders = RemindersViewModel(
            store: usesSystemNotifications
                ? UserDefaultsReminderSettingsStore()
                : InMemoryReminderSettingsStore(),
            scheduler: usesSystemNotifications
                ? UserNotificationScheduler()
                : DisabledNotificationScheduler(),
            blockRepository: dependencies.timeBlockRepository
        )
        projects = ProjectsViewModel(
            repository: dependencies.projectRepository,
            taskRepository: dependencies.taskRepository
        )
    }
}
