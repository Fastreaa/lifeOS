import SwiftUI

/// Qué día se está registrando y su registro previo, si existe.
struct CheckInSheet: Identifiable {
    let day: LocalDay
    let existing: WellnessCheckIn?
    let isToday: Bool
    var id: Int { day.storageValue }
}

struct CheckInFormView: View {
    let sheet: CheckInSheet
    let onSave: (CheckInDraft) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: CheckInDraft
    @State private var errorMessage: String?

    init(sheet: CheckInSheet, onSave: @escaping (CheckInDraft) throws -> Void) {
        self.sheet = sheet
        self.onSave = onSave
        _draft = State(initialValue: sheet.existing.map(CheckInDraft.init(checkIn:)) ?? CheckInDraft())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LevelPicker(metric: .energy, level: $draft.energy)
                    LevelPicker(metric: .mood, level: $draft.mood)
                    LevelPicker(metric: .stress, level: $draft.stress)
                }

                Section {
                    Toggle("Registrar horas de sueño", isOn: $draft.hasSleep.animation())
                    if draft.hasSleep {
                        Stepper(value: $draft.sleepHours, in: 0...14, step: 0.5) {
                            Text(WellnessFormat.hours(draft.sleepHours))
                        }
                    }
                }

                Section {
                    TextField("Nota (opcional)", text: $draft.note, axis: .vertical)
                        .lineLimit(2...5)
                } footer: {
                    Text("Tus registros y notas se guardan solo en este iPhone.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(Color.red)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar", action: save)
                        .accessibilityIdentifier("checkInForm.save")
                }
            }
        }
    }

    private var title: String {
        sheet.isToday
            ? String(localized: "¿Cómo estás hoy?")
            : WellnessFormat.dayTitle(sheet.day)
    }

    private func save() {
        do {
            try onSave(draft)
            dismiss()
        } catch let error as WellnessValidationError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = String(localized: "No se pudo guardar. Inténtalo de nuevo.")
        }
    }
}
