import SwiftUI

/// Pestañas de la app.
enum AppTab: Hashable {
    case today
    case habits
    case wellness
}

/// Navegación principal de la app: una pestaña por módulo.
struct RootView: View {
    let taskList: TaskListViewModel
    let habits: HabitsViewModel
    let wellness: WellnessViewModel

    @State private var selection: AppTab = .today

    var body: some View {
        TabView(selection: $selection) {
            Tab("Hoy", systemImage: "sun.max", value: AppTab.today) {
                DashboardView(viewModel: taskList, habits: habits, wellness: wellness) { tab in
                    selection = tab
                }
            }
            Tab("Hábitos", systemImage: "repeat", value: AppTab.habits) {
                HabitsView(viewModel: habits)
            }
            Tab("Bienestar", systemImage: "heart.text.square", value: AppTab.wellness) {
                WellnessView(viewModel: wellness)
            }
        }
        .tint(Color.lifeAccent)
    }
}
