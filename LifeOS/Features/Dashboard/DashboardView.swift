import SwiftUI

struct DashboardView: View {
    @Bindable var viewModel: TaskListViewModel
    let habits: HabitsViewModel
    let wellness: WellnessViewModel
    let agenda: AgendaViewModel
    let profile: ProfileViewModel
    let reminders: RemindersViewModel
    let projects: ProjectsViewModel
    let onSelectTab: (AppTab) -> Void

    @State private var formMode: TaskFormMode?
    @State private var checkInSheet: CheckInSheet?
    @State private var isShowingSettings = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            TimelineView(.everyMinute) { context in
                content(at: context.date)
                    .navigationTitle(title(at: context.date))
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Label("Ajustes", systemImage: "gearshape")
                    }
                    .accessibilityIdentifier("dashboard.settings")
                }
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
                TaskFormView(mode: mode, projects: projects.projects) { draft in
                    try save(draft, mode: mode)
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(viewModel: profile, reminders: reminders)
            }
            .sheet(item: $checkInSheet) { sheet in
                CheckInFormView(sheet: sheet) { draft in
                    try wellness.save(draft, for: sheet.day)
                }
            }
            .alert("Algo salió mal", isPresented: $viewModel.isShowingError) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                loadAll()
            }
            .task(id: viewModel.recentlyDeleted?.id) {
                await autoDismissUndo()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    loadAll()
                }
            }
        }
    }

    /// "Buenas tardes" o "Buenas tardes, Ana" si el usuario dio su nombre.
    private func title(at date: Date) -> Text {
        let greeting = DayPeriod(date: date).greeting
        if let name = profile.displayName {
            return Text("\(Text(greeting)), \(name)")
        }
        return Text(greeting)
    }

    private func loadAll() {
        viewModel.load()
        habits.load()
        wellness.load()
        agenda.load()
        projects.load()
    }

    // MARK: - Contenido

    @ViewBuilder
    private func content(at date: Date) -> some View {
        if viewModel.hasNoSearchResults {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            List {
                if !viewModel.isSearching {
                    Section {
                        TodayTasksCard(summary: viewModel.summary(at: date))
                    } header: {
                        Text(date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    }
                    Section {
                        TodayAgendaCard(
                            viewModel: agenda,
                            taskMinutes: viewModel.summary(at: date).estimatedMinutesDueToday,
                            now: date
                        ) {
                            onSelectTab(.agenda)
                        }
                    }
                    Section {
                        TodayHabitsCard(viewModel: habits) {
                            onSelectTab(.habits)
                        }
                    }
                    Section {
                        TodayWellnessCard(viewModel: wellness) {
                            checkInSheet = CheckInSheet(
                                day: wellness.today,
                                existing: wellness.todayCheckIn,
                                isToday: true
                            )
                        }
                    }
                }

                if viewModel.isEmpty {
                    Section("Tareas") {
                        emptyTasksRow
                    }
                } else {
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
            }
            .accessibilityIdentifier("dashboard.taskList")
        }
    }

    private var emptyTasksRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "sun.max")
                .font(.title2)
                .foregroundStyle(Color.lifeTasks)
            VStack(alignment: .leading, spacing: 2) {
                Text("Tu día está despejado")
                    .font(.headline)
                Text("Cuando quieras, añade una tarea con el botón +.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("dashboard.emptyState")
    }

    private func row(for task: TaskItem) -> some View {
        TaskRowView(task: task, project: projects.project(withID: task.projectID)) {
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
#Preview("Con datos") {
    DashboardView(
        viewModel: TaskListViewModel(repository: PreviewTaskRepository.sample),
        habits: HabitsViewModel(repository: PreviewHabitRepository.sample),
        wellness: WellnessViewModel(repository: PreviewWellnessRepository.sample),
        agenda: AgendaViewModel(repository: PreviewTimeBlockRepository.sample),
        profile: ProfileViewModel(repository: PreviewProfileRepository(), suppressesOnboarding: true),
        reminders: RemindersViewModel(
            store: InMemoryReminderSettingsStore(),
            scheduler: DisabledNotificationScheduler(),
            blockRepository: PreviewTimeBlockRepository()
        ),
        projects: ProjectsViewModel(repository: PreviewProjectRepository(), taskRepository: PreviewTaskRepository()),
        onSelectTab: { _ in }
    )
}

#Preview("Vacío") {
    DashboardView(
        viewModel: TaskListViewModel(repository: PreviewTaskRepository()),
        habits: HabitsViewModel(repository: PreviewHabitRepository()),
        wellness: WellnessViewModel(repository: PreviewWellnessRepository()),
        agenda: AgendaViewModel(repository: PreviewTimeBlockRepository()),
        profile: ProfileViewModel(repository: PreviewProfileRepository(), suppressesOnboarding: true),
        reminders: RemindersViewModel(
            store: InMemoryReminderSettingsStore(),
            scheduler: DisabledNotificationScheduler(),
            blockRepository: PreviewTimeBlockRepository()
        ),
        projects: ProjectsViewModel(repository: PreviewProjectRepository(), taskRepository: PreviewTaskRepository()),
        onSelectTab: { _ in }
    )
}
#endif
