import Foundation

/// Los ViewModels de cada módulo. Se crean una sola vez al arrancar y se
/// comparten entre pestañas: un cambio en una se ve al instante en las demás.
struct AppModels {
    let taskList: TaskListViewModel
    let habits: HabitsViewModel
    let wellness: WellnessViewModel
    let agenda: AgendaViewModel
    let profile: ProfileViewModel

    init(dependencies: AppDependencies, suppressesOnboarding: Bool = false) {
        taskList = TaskListViewModel(repository: dependencies.taskRepository)
        habits = HabitsViewModel(repository: dependencies.habitRepository)
        wellness = WellnessViewModel(repository: dependencies.wellnessRepository)
        agenda = AgendaViewModel(repository: dependencies.timeBlockRepository)
        profile = ProfileViewModel(
            repository: dependencies.profileRepository,
            suppressesOnboarding: suppressesOnboarding
        )
    }
}
