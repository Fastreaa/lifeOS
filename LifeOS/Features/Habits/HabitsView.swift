import SwiftUI

struct HabitsView: View {
    @Bindable var viewModel: HabitsViewModel
    @State private var formMode: HabitFormMode?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Hábitos")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            formMode = .create
                        } label: {
                            Label("Nuevo hábito", systemImage: "plus")
                        }
                        .accessibilityIdentifier("habits.addHabit")
                    }
                }
                .sheet(item: $formMode) { mode in
                    HabitFormView(mode: mode) { draft in
                        try save(draft, mode: mode)
                    }
                }
                .alert("Algo salió mal", isPresented: $viewModel.isShowingError) {
                    Button("Aceptar", role: .cancel) {}
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
                .sensoryFeedback(.success, trigger: viewModel.completedTodayCount) { old, new in
                    new > old
                }
                .task {
                    viewModel.load()
                }
                .onChange(of: scenePhase) { _, phase in
                    // Al volver a la app (quizá al día siguiente), recalcular "hoy".
                    if phase == .active {
                        viewModel.load()
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isEmpty {
            ContentUnavailableView {
                Label("Aún no tienes hábitos", systemImage: "repeat")
            } description: {
                Text("Empieza con uno pequeño: beber agua, leer 10 minutos o caminar.")
            } actions: {
                Button("Crear un hábito") {
                    formMode = .create
                }
                .buttonStyle(.borderedProminent)
            }
            .accessibilityIdentifier("habits.emptyState")
        } else {
            List {
                Section {
                    todaySummary
                } footer: {
                    Text("Los días de descanso no cortan tu racha.")
                }
                Section {
                    ForEach(viewModel.items) { item in
                        HabitRowView(overview: item) {
                            viewModel.toggleToday(item.habit)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            formMode = .edit(item.habit)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.delete(item.habit)
                            } label: {
                                Label("Borrar", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    private var todaySummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            if viewModel.scheduledTodayCount == 0 {
                Text("Hoy es día de descanso")
                    .font(.headline)
            } else {
                Text("Hoy: \(viewModel.completedTodayCount) de \(viewModel.scheduledTodayCount)")
                    .font(.headline)
                ProgressView(
                    value: Double(viewModel.completedTodayCount),
                    total: Double(viewModel.scheduledTodayCount)
                )
                .tint(Color.lifeHabits)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func save(_ draft: HabitDraft, mode: HabitFormMode) throws {
        switch mode {
        case .create:
            try viewModel.create(draft)
        case .edit(let habit):
            try viewModel.update(habit, with: draft)
        }
    }
}

#if DEBUG
#Preview("Con hábitos") {
    HabitsView(viewModel: HabitsViewModel(repository: PreviewHabitRepository.sample))
}

#Preview("Vacío") {
    HabitsView(viewModel: HabitsViewModel(repository: PreviewHabitRepository()))
}
#endif
