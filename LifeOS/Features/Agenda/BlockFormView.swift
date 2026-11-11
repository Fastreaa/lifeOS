import SwiftUI

enum BlockFormMode: Identifiable {
    case create
    case edit(TimeBlock)

    var id: String {
        switch self {
        case .create: "create"
        case .edit(let block): block.id.uuidString
        }
    }
}

struct BlockFormView: View {
    let mode: BlockFormMode
    let onSave: (BlockDraft) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: BlockDraft
    @State private var errorMessage: String?

    init(mode: BlockFormMode, onSave: @escaping (BlockDraft) throws -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .create:
            _draft = State(initialValue: BlockDraft())
        case .edit(let block):
            _draft = State(initialValue: BlockDraft(block: block))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Título, por ejemplo «Clase de cálculo»", text: $draft.title)
                        .accessibilityIdentifier("blockForm.title")
                }

                Section("Tipo") {
                    Picker("Tipo", selection: $draft.kind) {
                        ForEach(BlockKind.allCases, id: \.self) { kind in
                            Label {
                                Text(kind.label)
                            } icon: {
                                Image(systemName: kind.symbolName)
                            }
                            .tag(kind)
                        }
                    }
                }

                Section {
                    DatePicker("Inicio", selection: $draft.start, displayedComponents: .hourAndMinute)
                    DatePicker("Fin", selection: $draft.end, displayedComponents: .hourAndMinute)
                } header: {
                    Text("Horario")
                } footer: {
                    Text("Para terminar a medianoche, elige 00:00 como hora de fin.")
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
                        .accessibilityIdentifier("blockForm.save")
                }
            }
        }
    }

    private var title: LocalizedStringKey {
        switch mode {
        case .create: "Nuevo bloque"
        case .edit: "Editar bloque"
        }
    }

    private func save() {
        do {
            try onSave(draft)
            dismiss()
        } catch let error as TimeBlockValidationError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = String(localized: "No se pudo guardar. Inténtalo de nuevo.")
        }
    }
}
