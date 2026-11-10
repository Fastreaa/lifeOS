import SwiftUI

enum HabitFormMode: Identifiable {
    case create
    case edit(Habit)

    var id: String {
        switch self {
        case .create: "create"
        case .edit(let habit): habit.id.uuidString
        }
    }
}

struct HabitFormView: View {
    let mode: HabitFormMode
    let onSave: (HabitDraft) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: HabitDraft
    @State private var errorMessage: String?

    private let symbolColumns = Array(repeating: GridItem(.flexible()), count: 6)

    init(mode: HabitFormMode, onSave: @escaping (HabitDraft) throws -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .create:
            _draft = State(initialValue: HabitDraft())
        case .edit(let habit):
            _draft = State(initialValue: HabitDraft(habit: habit))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nombre, por ejemplo «Leer 10 minutos»", text: $draft.name)
                        .accessibilityIdentifier("habitForm.name")
                }

                Section("Icono") {
                    LazyVGrid(columns: symbolColumns, spacing: 12) {
                        ForEach(HabitSymbol.all) { symbol in
                            symbolButton(symbol)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    WeekdayPicker(selection: $draft.weekdays)
                        .padding(.vertical, 4)
                    Button("Todos los días") {
                        draft.weekdays = Habit.allWeekdays
                    }
                    .disabled(draft.weekdays == Habit.allWeekdays)
                } header: {
                    Text("Días")
                } footer: {
                    Text("Los días que no elijas son de descanso: no cuentan en contra.")
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
                        .disabled(!draft.canSave)
                        .accessibilityIdentifier("habitForm.save")
                }
            }
        }
    }

    private func symbolButton(_ symbol: HabitSymbol) -> some View {
        let isSelected = draft.symbolName == symbol.name
        return Button {
            draft.symbolName = symbol.name
        } label: {
            Image(systemName: symbol.name)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear, in: Circle())
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(symbol.label))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var title: LocalizedStringKey {
        switch mode {
        case .create: "Nuevo hábito"
        case .edit: "Editar hábito"
        }
    }

    private func save() {
        do {
            try onSave(draft)
            dismiss()
        } catch let error as HabitValidationError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = String(localized: "No se pudo guardar. Inténtalo de nuevo.")
        }
    }
}
