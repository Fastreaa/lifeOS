import SwiftUI
import UIKit

/// Sección "Recordatorios" de Ajustes. Los cambios se aplican al momento.
struct RemindersSection: View {
    @Bindable var viewModel: RemindersViewModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            Toggle("Hábitos", isOn: $viewModel.habitsEnabled)
                .accessibilityIdentifier("reminders.habits")
            if viewModel.habitsEnabled {
                DatePicker("Hora", selection: $viewModel.habitsTime, displayedComponents: .hourAndMinute)
            }

            Toggle("Check-in de bienestar", isOn: $viewModel.checkInEnabled)
                .accessibilityIdentifier("reminders.checkIn")
            if viewModel.checkInEnabled {
                DatePicker("Hora", selection: $viewModel.checkInTime, displayedComponents: .hourAndMinute)
            }

            Toggle("Avisos de la agenda", isOn: $viewModel.blockAlertsEnabled)
                .accessibilityIdentifier("reminders.blocks")
            if viewModel.blockAlertsEnabled {
                Picker("Avisar", selection: $viewModel.blockLeadMinutes) {
                    ForEach(ReminderSettings.leadOptions, id: \.self) { minutes in
                        Text("\(minutes) min antes").tag(minutes)
                    }
                }
            }

            if viewModel.isDenied {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Las notificaciones de LifeOS están desactivadas en tu iPhone.")
                        .font(.subheadline)
                    Button("Abrir Ajustes del iPhone") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Recordatorios")
        } footer: {
            Text("Recordatorios suaves que puedes desactivar cuando quieras. Los avisos de la agenda cubren hoy y mañana.")
        }
    }
}
