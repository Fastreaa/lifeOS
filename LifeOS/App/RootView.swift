import SwiftUI

/// Navegación principal de la app: una pestaña por módulo.
struct RootView: View {
    let taskList: TaskListViewModel
    let habits: HabitsViewModel
    let wellness: WellnessViewModel

    var body: some View {
        TabView {
            Tab("Hoy", systemImage: "sun.max") {
                DashboardView(viewModel: taskList)
            }
            Tab("Hábitos", systemImage: "repeat") {
                HabitsView(viewModel: habits)
            }
            Tab("Bienestar", systemImage: "heart.text.square") {
                WellnessView(viewModel: wellness)
            }
        }
    }
}
