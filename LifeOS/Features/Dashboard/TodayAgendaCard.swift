import SwiftUI

/// Tarjeta del dashboard: qué bloque toca ahora o después, y si caben las tareas.
struct TodayAgendaCard: View {
    let viewModel: AgendaViewModel
    let taskMinutes: Int
    let now: Date
    let onOpenAgenda: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CardHeader(title: "Agenda", systemImage: "calendar", tint: .lifeAccent)
                Spacer()
                Button("Ver", action: onOpenAgenda)
                    .buttonStyle(.borderless)
                    .accessibilityIdentifier("dashboard.openAgenda")
            }

            if viewModel.todayBlocks.isEmpty {
                Text("Organiza tu día en bloques: clases, trabajo, estudio y descanso.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            } else {
                if let upcoming = viewModel.upcomingToday(at: now) {
                    upcomingRow(upcoming)
                } else {
                    Text("No quedan bloques por hoy.")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                PlanFitLabel(plan: viewModel.todayPlan(taskMinutes: taskMinutes))
            }
        }
        .padding(.vertical, 4)
    }

    private func upcomingRow(_ upcoming: UpcomingBlock) -> some View {
        let block = upcoming.block
        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(block.kind.color)
                .frame(width: 4, height: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(upcoming.isCurrent ? "Ahora" : "Siguiente")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(block.kind.color)
                Text(block.title)
                    .font(.body)
            }
            Spacer(minLength: 0)
            Text(timeText(upcoming))
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private func timeText(_ upcoming: UpcomingBlock) -> String {
        let block = upcoming.block
        if upcoming.isCurrent {
            let end = AgendaFormat.time(block.endMinute, on: block.day)
            return String(localized: "hasta las \(end)")
        }
        return AgendaFormat.time(block.startMinute, on: block.day)
    }
}
