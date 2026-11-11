import SwiftUI

@main
struct LifeOSApp: App {
    @State private var startup = AppStartup.make()

    var body: some Scene {
        WindowGroup {
            switch startup {
            case .ready(_, let models):
                RootView(models: models)
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
    case ready(AppDependencies, AppModels)
    case failed

    static func make(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppStartup {
        // Las pruebas de interfaz arrancan con "-ui-testing": base de datos en
        // memoria, así cada prueba empieza vacía y no toca tus datos reales.
        let inMemory = arguments.contains("-ui-testing")
        // En pruebas, la bienvenida se omite salvo que se pida con "-show-onboarding".
        let suppressesOnboarding = inMemory && !arguments.contains("-show-onboarding")
        do {
            let dependencies = try AppDependencies(inMemory: inMemory)
            let models = AppModels(dependencies: dependencies, suppressesOnboarding: suppressesOnboarding)
            return .ready(dependencies, models)
        } catch {
            return .failed
        }
    }
}
