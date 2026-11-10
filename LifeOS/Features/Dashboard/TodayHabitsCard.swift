import SwiftUI

/// Tarjeta del dashboard con los hábitos que tocan hoy, marcables desde aquí.
struct TodayHabitsCard: View {
    let viewModel: HabitsViewModel
    let onOpenHabits: () -> Void

    private let maxVisible = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CardHeader(title: "Hábitos de hoy", systemImage: "repeat", tint: .lifeHabits)
                Spacer()
                if viewModel.scheduledTodayCount > 0 {
                    Text("\(viewModel.completedTodayCount)/\(viewModel.scheduledTodayCount)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                    ProgressRing(progress: progress, tint: .lifeHabits)
                        .frame(width: 28, height: 28)
                }
            }

            if viewModel.isEmpty {
                Text("Crea un hábito pequeño y márcalo aquí cada día.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                Button("Ir a Hábitos", action: onOpenHabits)
                    .buttonStyle(.borderless)
                    .accessibilityIdentifier("dashboard.openHabits")
            } else if viewModel.todayItems.isEmpty {
                Text("Hoy es día de descanso para tus hábitos.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            } else {
                ForEach(Array(viewModel.todayItems.prefix(maxVisible))) { item in
                    habitRow(item)
                }
                if viewModel.todayItems.count > maxVisible {
                    Button("Ver todos", action: onOpenHabits)
                        .buttonStyle(.borderless)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var progress: Double {
        guard viewModel.scheduledTodayCount > 0 else { return 0 }
        return Double(viewModel.completedTodayCount) / Double(viewModel.scheduledTodayCount)
    }

    private func habitRow(_ item: HabitOverview) -> some View {
        let isDone = item.progress.isCompletedToday
        return HStack(spacing: 12) {
            Image(systemName: item.habit.symbolName)
                .foregroundStyle(Color.lifeHabits)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(item.habit.name)
                .foregroundStyle(isDone ? Color.secondary : Color.primary)
            Spacer(minLength: 0)
            Button {
                viewModel.toggleToday(item.habit)
            } label: {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isDone ? Color.lifeHabits : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            // Sin esto, tocar cualquier parte de la fila activaría todos los botones.
            .buttonStyle(.borderless)
            .accessibilityLabel(isDone ? "Desmarcar \(item.habit.name)" : "Marcar \(item.habit.name) como hecho")
        }
    }
}
