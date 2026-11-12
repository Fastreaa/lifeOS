import SwiftUI

/// Tareas de un proyecto, con su progreso.
struct ProjectDetailView: View {
    let project: Project
    let projects: ProjectsViewModel
    let taskList: TaskListViewModel

    @State private var taskForm: TaskFormMode?
    @State private var isEditing = false

    /// La versión más reciente del proyecto (por si se editó desde aquí).
    private var current: Project { projects.project(withID: project.id) ?? project }
    private var pending: [TaskItem] { taskList.pendingTasks(inProject: project.id) }
    private var completed: [TaskItem] { taskList.completedTasks(inProject: project.id) }
    private var progress: ProjectProgress {
        ProjectProgress(projectID: project.id, tasks: taskList.allTasks)
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    ProgressRing(progress: progress.fraction, tint: current.color.color)
                        .frame(width: 40, height: 40)
                    Text(ProjectFormat.summary(progress))
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                .padding(.vertical, 4)
            }

            if pending.isEmpty && completed.isEmpty {
                Section {
                    Text("Este proyecto aún no tiene tareas. Añade la primera con +.")
                        .foregroundStyle(Color.secondary)
                }
            }

            if !pending.isEmpty {
                Section("Pendientes") {
                    ForEach(pending) { task in
                        row(task)
                    }
                }
            }

            if !completed.isEmpty {
                Section("Completadas") {
                    ForEach(completed) { task in
                        row(task)
                    }
                }
            }
        }
        .navigationTitle(current.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    taskForm = .create
                } label: {
                    Label("Nueva tarea", systemImage: "plus")
                }
                .accessibilityIdentifier("project.addTask")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar") {
                    isEditing = true
                }
            }
        }
        .sheet(item: $taskForm) { mode in
            TaskFormView(mode: mode, projects: projects.projects, initialProjectID: project.id) { draft in
                switch mode {
                case .create:
                    try taskList.create(draft)
                case .edit(let task):
                    try taskList.update(task, with: draft)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            ProjectFormView(mode: .edit(current)) { draft in
                try projects.update(current, with: draft)
            }
        }
    }

    private func row(_ task: TaskItem) -> some View {
        TaskRowView(task: task) {
            taskList.toggleCompletion(of: task)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            taskForm = .edit(task)
        }
    }
}
