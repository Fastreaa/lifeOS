import SwiftUI

struct DashboardView: View {
    @Bindable var viewModel: TaskListViewModel
    @State private var formMode: TaskFormMode?

    var body: some View {
        NavigationStack {
            TimelineView(.everyMinute) { context in
                content(at: context.date)
                    .navigationTitle(Text(DayPeriod(date: context.date).greeting))
            }
            .searchable(text: $viewModel.searchText, prompt: Text("Buscar tareas"))
            .safeAreaInset(edge: .bottom) {
                undoBanner
            }
            .animation(.default, value: viewModel.recentlyDeleted?.id)
            .sensoryFeedback(.success, trigger: viewModel.completedTasks.count) { old, new in
                new > old
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        formMode = .create
                    } label: {
                        Label("Nueva tarea", systemImage: "plus")
                    }
                    .accessibilityIdentifier("dashboard.addTask")
                }
            }
            .sheet(item: $formMode) { mode in
                TaskFormView(mode: mode) { draft in
                    try save(draft, mode: mode)
                }
            }
            .alert("Algo salió mal", isPresented: $viewModel.isShowingError) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                viewModel.load()
            }
            .task(id: viewModel.recentlyDeleted?.id) {
                await autoDismissUndo()
            }
        }
    }

    // MARK: - Contenido

    @ViewBuilder
    private func content(at date: Date) -> some View {
        if viewModel.isEmpty {
            ContentUnavailableView {
                Label("Tu día está despejado", systemImage: "sun.max")
            } description: {
                Text("Cuando quieras, añade una tarea con el botón +.")
            }
            .accessibilityIdentifier("dashboard.emptyState")
        } else if viewModel.hasNoSearchResults {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            List {
                if !viewModel.isSearching {
                    Section {
                        DaySummaryView(summary: viewModel.summary(at: date))
                    }
                }
                if !viewModel.visiblePendingTasks.isEmpty {
                    Section("Pendientes") {
                        ForEach(viewModel.visiblePendingTasks) { task in
                            row(for: task)
                        }
                    }
                }
                if !viewModel.visibleCompletedTasks.isEmpty {
                    Section("Completadas") {
                        ForEach(viewModel.visibleCompletedTasks) { task in
                            row(for: task)
                        }
                    }
                }
            }
            .accessibilityIdentifier("dashboard.taskList")
        }
    }

    private func row(for task: TaskItem) -> some View {
        TaskRowView(task: task) {
            viewModel.toggleCompletion(of: task)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            formMode = .edit(task)
        }
        .swipeActions(edge: .leading) {
            Button {
                viewModel.toggleCompletion(of: task)
            } label: {
                if task.isCompleted {
                    Label("Reabrir", systemImage: "arrow.uturn.backward")
                } else {
                    Label("Completar", systemImage: "checkmark")
                }
            }
            .tint(Color.green)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.delete(task)
            } label: {
                Label("Borrar", systemImage: "trash")
            }
        }
    }

    // MARK: - Deshacer

    @ViewBuilder
    private var undoBanner: some View {
        if let deleted = viewModel.recentlyDeleted {
            UndoBanner(taskTitle: deleted.title) {
                viewModel.undoDelete()
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    /// Oculta el aviso tras 5 segundos. Si antes se pulsa Deshacer o se borra
    /// otra tarea, SwiftUI cancela esta espera y no se oculta nada por error.
    private func autoDismissUndo() async {
        guard viewModel.recentlyDeleted != nil else { return }
        do {
            try await Task.sleep(for: .seconds(5))
            viewModel.dismissUndo()
        } catch {
            // Espera cancelada: no hay nada que hacer.
        }
    }

    // MARK: - Guardar

    private func save(_ draft: TaskDraft, mode: TaskFormMode) throws {
        switch mode {
        case .create:
            try viewModel.create(draft)
        case .edit(let task):
            try viewModel.update(task, with: draft)
        }
    }
}

#if DEBUG
#Preview("Con tareas") {
    DashboardView(viewModel: TaskListViewModel(repository: PreviewTaskRepository.sample))
}

#Preview("Vacío") {
    DashboardView(viewModel: TaskListViewModel(repository: PreviewTaskRepository()))
}
#endif
