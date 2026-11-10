import SwiftUI

@main
struct LifeOSApp: App {
    @State private var startup = AppStartup.make()

    var body: some Scene {
        WindowGroup {
            switch startup {
            case .ready(_, let taskList, let habits):
                RootView(taskList: taskList, habits: habits)
            case .failed:
                ContentUnavailableView {
                    Label("No se pudieron abrir tus datos", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text("Cierra LifeOS y vuelve a abrirla. Tus datos no se han borrado.")
                }
            }
        }
    }
}

/// Resultado de preparar la app al arrancar.
/// Guarda `AppDependencies` para que la base de datos viva mientras viva la app.
enum AppStartup {
    case ready(AppDependencies, TaskListViewModel, HabitsViewModel)
    case failed

    static func make(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppStartup {
        // Las pruebas de interfaz arrancan con "-ui-testing": base de datos en
        // memoria, así cada prueba empieza vacía y no toca tus datos reales.
        let inMemory = arguments.contains("-ui-testing")
        do {
            let dependencies = try AppDependencies(inMemory: inMemory)
            return .ready(
                dependencies,
                TaskListViewModel(repository: dependencies.taskRepository),
                HabitsViewModel(repository: dependencies.habitRepository)
            )
        } catch {
            return .failed
        }
    }
}
