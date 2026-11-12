import SwiftUI

enum ProjectFormMode: Identifiable {
    case create
    case edit(Project)

    var id: String {
        switch self {
        case .create: "create"
        case .edit(let project): project.id.uuidString
        }
    }
}

struct ProjectFormView: View {
    let mode: ProjectFormMode
    let onSave: (ProjectDraft) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: ProjectDraft
    @State private var errorMessage: String?

    private let symbolColumns = Array(repeating: GridItem(.flexible()), count: 6)

    init(mode: ProjectFormMode, onSave: @escaping (ProjectDraft) throws -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .create:
            _draft = State(initialValue: ProjectDraft())
        case .edit(let project):
            _draft = State(initialValue: ProjectDraft(project: project))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nombre, por ejemplo «Universidad»", text: $draft.name)
                        .accessibilityIdentifier("projectForm.name")
                }

                Section("Color") {
                    HStack(spacing: 10) {
                        ForEach(ProjectColor.allCases, id: \.self) { color in
                            colorButton(color)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Icono") {
                    LazyVGrid(columns: symbolColumns, spacing: 12) {
                        ForEach(ProjectSymbol.all) { symbol in
                            symbolButton(symbol)
                        }
                    }
                    .padding(.vertical, 4)
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
                        .accessibilityIdentifier("projectForm.save")
                }
            }
        }
    }

    private func colorButton(_ color: ProjectColor) -> some View {
        let isSelected = draft.color == color
        return Button {
            draft.color = color
        } label: {
            Circle()
                .fill(color.color)
                .frame(width: 30, height: 30)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.white)
                    }
                }
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(color.label))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func symbolButton(_ symbol: ProjectSymbol) -> some View {
        let isSelected = draft.symbolName == symbol.name
        return Button {
            draft.symbolName = symbol.name
        } label: {
            Image(systemName: symbol.name)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(isSelected ? draft.color.color.opacity(0.2) : Color.clear, in: Circle())
                .foregroundStyle(isSelected ? draft.color.color : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(symbol.label))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var title: LocalizedStringKey {
        switch mode {
        case .create: "Nuevo proyecto"
        case .edit: "Editar proyecto"
        }
    }

    private func save() {
        do {
            try onSave(draft)
            dismiss()
        } catch let error as ProjectValidationError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = String(localized: "No se pudo guardar. Inténtalo de nuevo.")
        }
    }
}
