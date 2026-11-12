import SwiftUI

struct ProjectsView: View {
    @Bindable var viewModel: ProjectsViewModel
    let taskList: TaskListViewModel

    @State private var formMode: ProjectFormMode?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Proyectos")
                .navigationDestination(for: UUID.self) { id in
                    if let project = viewModel.project(withID: id) {
                        ProjectDetailView(project: project, projects: viewModel, taskList: taskList)
                    } else {
                        ContentUnavailableView("Proyecto no encontrado", systemImage: "folder")
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            formMode = .create
                        } label: {
                            Label("Nuevo proyecto", systemImage: "plus")
                        }
                        .accessibilityIdentifier("projects.addProject")
                    }
                }
                .sheet(item: $formMode) { mode in
                    ProjectFormView(mode: mode) { draft in
                        switch mode {
                        case .create:
                            try viewModel.create(draft)
                        case .edit(let project):
                            try viewModel.update(project, with: draft)
                        }
                    }
                }
                .alert("Algo salió mal", isPresented: $viewModel.isShowingError) {
                    Button("Aceptar", role: .cancel) {}
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
                .task {
                    viewModel.load()
                    taskList.load()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isEmpty {
            ContentUnavailableView {
                Label("Agrupa tus tareas", systemImage: "folder")
            } description: {
                Text("Crea proyectos o áreas como «Universidad», «Trabajo» o «Casa».")
            } actions: {
                Button("Crear un proyecto") {
                    formMode = .create
                }
                .buttonStyle(.borderedProminent)
            }
            .accessibilityIdentifier("projects.emptyState")
        } else {
            List {
                ForEach(viewModel.projects) { project in
                    NavigationLink(value: project.id) {
                        ProjectRowView(
                            project: project,
                            progress: ProjectProgress(projectID: project.id, tasks: taskList.allTasks)
                        )
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.delete(project)
                            taskList.load()
                        } label: {
                            Label("Borrar", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    ProjectsView(
        viewModel: ProjectsViewModel(repository: PreviewProjectRepository(), taskRepository: PreviewTaskRepository()),
        taskList: TaskListViewModel(repository: PreviewTaskRepository())
    )
}
#endif
