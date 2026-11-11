import SwiftUI

/// Pestañas de la app.
enum AppTab: Hashable {
    case today
    case agenda
    case habits
    case wellness
}

/// Navegación principal de la app: una pestaña por módulo.
struct RootView: View {
    let models: AppModels

    @State private var selection: AppTab = .today

    var body: some View {
        TabView(selection: $selection) {
            Tab("Hoy", systemImage: "sun.max", value: AppTab.today) {
                DashboardView(
                    viewModel: models.taskList,
                    habits: models.habits,
                    wellness: models.wellness,
                    agenda: models.agenda
                ) { tab in
                    selection = tab
                }
            }
            Tab("Agenda", systemImage: "calendar", value: AppTab.agenda) {
                AgendaView(viewModel: models.agenda, taskList: models.taskList)
            }
            Tab("Hábitos", systemImage: "repeat", value: AppTab.habits) {
                HabitsView(viewModel: models.habits)
            }
            Tab("Bienestar", systemImage: "heart.text.square", value: AppTab.wellness) {
                WellnessView(viewModel: models.wellness)
            }
        }
        .tint(Color.lifeAccent)
    }
}
