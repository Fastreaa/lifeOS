import SwiftUI

/// Ajustes: nombre, horario del día, privacidad y versión.
struct SettingsView: View {
    let viewModel: ProfileViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var draft: ProfileDraft
    @State private var errorMessage: String?

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        _draft = State(initialValue: ProfileDraft(profile: viewModel.profile))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Perfil") {
                    TextField("Tu nombre (opcional)", text: $draft.name)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier("settings.name")
                }

                Section {
                    DatePicker("Me levanto", selection: $draft.dayStart, displayedComponents: .hourAndMinute)
                    DatePicker("Me acuesto", selection: $draft.dayEnd, displayedComponents: .hourAndMinute)
                } header: {
                    Text("Tu día")
                } footer: {
                    Text("La agenda calcula tu tiempo libre dentro de este horario.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(Color.red)
                    }
                }

                Section {
                    Label("Tus datos se guardan solo en este iPhone.", systemImage: "lock.shield")
                } header: {
                    Text("Privacidad")
                } footer: {
                    Text("Por ahora LifeOS no sincroniza ni envía nada a internet.")
                }

                Section("Acerca de") {
                    LabeledContent("Versión", value: appVersion)
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar", action: save)
                        .accessibilityIdentifier("settings.save")
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func save() {
        do {
            try viewModel.save(draft)
            dismiss()
        } catch let error as ProfileValidationError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = String(localized: "No se pudo guardar. Inténtalo de nuevo.")
        }
    }
}
