import SwiftUI

struct AgendaView: View {
    @Bindable var viewModel: AgendaViewModel
    let taskList: TaskListViewModel

    @State private var formMode: BlockFormMode?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            List {
                Section {
                    dayPicker
                }

                Section("Plan del día") {
                    DayPlanCard(plan: plan, day: viewModel.selectedDay, showsTasks: viewModel.isShowingToday)
                }

                Section("Bloques") {
                    if viewModel.blocks.isEmpty {
                        emptyRow
                    } else {
                        ForEach(viewModel.blocks) { block in
                            TimeBlockRowView(
                                block: block,
                                hasConflict: plan.conflictingBlockIDs.contains(block.id)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                formMode = .edit(block)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.delete(block)
                                } label: {
                                    Label("Borrar", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Agenda")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        formMode = .create
                    } label: {
                        Label("Nuevo bloque", systemImage: "plus")
                    }
                    .accessibilityIdentifier("agenda.addBlock")
                }
            }
            .sheet(item: $formMode) { mode in
                BlockFormView(mode: mode) { draft in
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
                taskList.load()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    viewModel.load()
                }
            }
        }
    }

    private var plan: DayPlan {
        viewModel.plan(taskMinutes: taskList.summary(at: .now).estimatedMinutesDueToday)
    }

    private var dayPicker: some View {
        HStack {
            Button {
                viewModel.showDay(offset: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Día anterior")

            Spacer()

            VStack(spacing: 2) {
                Text(AgendaFormat.dayTitle(viewModel.selectedDay, today: viewModel.today))
                    .font(.headline)
                if !viewModel.isShowingToday {
                    Button("Volver a hoy") {
                        viewModel.showToday()
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                }
            }

            Spacer()

            Button {
                viewModel.showDay(offset: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Día siguiente")
        }
        .padding(.vertical, 2)
    }

    private var emptyRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sin bloques para este día")
                .font(.headline)
            Text("Organiza el día en bloques: clases, trabajo, estudio y también descanso.")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
            Button {
                formMode = .create
            } label: {
                Label("Añadir bloque", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("agenda.emptyState")
    }

    private func save(_ draft: BlockDraft, mode: BlockFormMode) throws {
        switch mode {
        case .create:
            try viewModel.create(draft)
        case .edit(let block):
            try viewModel.update(block, with: draft)
        }
    }
}

#if DEBUG
#Preview("Con bloques") {
    AgendaView(
        viewModel: AgendaViewModel(repository: PreviewTimeBlockRepository.sample),
        taskList: TaskListViewModel(repository: PreviewTaskRepository.sample)
    )
}

#Preview("Vacío") {
    AgendaView(
        viewModel: AgendaViewModel(repository: PreviewTimeBlockRepository()),
        taskList: TaskListViewModel(repository: PreviewTaskRepository())
    )
}
#endif
