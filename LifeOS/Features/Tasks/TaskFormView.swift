import SwiftUI

/// Qué está haciendo el formulario: crear una tarea nueva o editar una existente.
enum TaskFormMode: Identifiable {
    case create
    case edit(TaskItem)

    var id: String {
        switch self {
        case .create: "create"
        case .edit(let task): task.id.uuidString
        }
    }
}

struct TaskFormView: View {
    let mode: TaskFormMode
    let projects: [Project]
    let onSave: (TaskDraft) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: TaskDraft
    @State private var errorMessage: String?

    init(
        mode: TaskFormMode,
        projects: [Project] = [],
        initialProjectID: UUID? = nil,
        onSave: @escaping (TaskDraft) throws -> Void
    ) {
        self.mode = mode
        self.projects = projects
        self.onSave = onSave
        switch mode {
        case .create:
            _draft = State(initialValue: TaskDraft(projectID: initialProjectID))
        case .edit(let task):
            _draft = State(initialValue: TaskDraft(task: task))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Título", text: $draft.title)
                        .accessibilityIdentifier("taskForm.title")
                    TextField("Notas", text: $draft.notes, axis: .vertical)
                        .lineLimit(1...4)
                }

                if !projects.isEmpty {
                    Section("Proyecto") {
                        Picker("Proyecto", selection: $draft.projectID) {
                            Text("Sin proyecto").tag(UUID?.none)
                            ForEach(projects) { project in
                                Label {
                                    Text(project.name)
                                } icon: {
                                    Image(systemName: project.symbolName)
                                }
                                .tag(Optional(project.id))
                            }
                        }
                    }
                }

                Section("Prioridad") {
                    Picker("Prioridad", selection: $draft.priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.label).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section {
                    Toggle("Fecha límite", isOn: $draft.hasDueDate.animation())
                    if draft.hasDueDate {
                        DatePicker("Fecha", selection: $draft.dueDate)
                    }

                    Toggle("Duración estimada", isOn: $draft.hasEstimate.animation())
                    if draft.hasEstimate {
                        Stepper(
                            value: $draft.estimatedMinutes,
                            in: TaskItem.estimatedMinutesRange,
                            step: 5
                        ) {
                            Text("\(draft.estimatedMinutes) min")
                        }
                    }
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
                        .accessibilityIdentifier("taskForm.save")
                }
            }
        }
    }

    private var title: LocalizedStringKey {
        switch mode {
        case .create: "Nueva tarea"
        case .edit: "Editar tarea"
        }
    }

    private func save() {
        do {
            try onSave(draft)
            dismiss()
        } catch let error as TaskValidationError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = String(localized: "No se pudo guardar. Inténtalo de nuevo.")
        }
    }
}
