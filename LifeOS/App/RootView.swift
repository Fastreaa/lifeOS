import SwiftUI

/// Navegación principal de la app: una pestaña por módulo.
struct RootView: View {
    let taskList: TaskListViewModel
    let habits: HabitsViewModel

    var body: some View {
        TabView {
            Tab("Hoy", systemImage: "sun.max") {
                DashboardView(viewModel: taskList)
            }
            Tab("Hábitos", systemImage: "repeat") {
                HabitsView(viewModel: habits)
            }
        }
    }
}
