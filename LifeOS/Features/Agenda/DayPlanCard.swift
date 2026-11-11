import SwiftUI

/// Resumen del día: libre, ocupado, descanso, si caben las tareas y conflictos.
struct DayPlanCard: View {
    let plan: DayPlan
    let day: LocalDay
    let showsTasks: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                stat(AgendaFormat.duration(plan.freeMinutes), label: "Libre", color: .lifeAccent)
                stat(AgendaFormat.duration(plan.busyMinutes), label: "Ocupado", color: .lifeTasks)
                stat(AgendaFormat.duration(plan.restMinutes), label: "Descanso", color: .mint)
            }

            if showsTasks {
                PlanFitLabel(plan: plan)
            }

            if !plan.conflicts.isEmpty {
                Label(
                    String(localized: "\(plan.conflictingBlockIDs.count) bloques se solapan. Revisa sus horarios."),
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.subheadline)
                .foregroundStyle(Color.orange)
            }

            Text(windowText)
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        .padding(.vertical, 4)
    }

    private var windowText: String {
        let start = AgendaFormat.time(plan.window.lowerBound, on: day)
        let end = AgendaFormat.time(plan.window.upperBound, on: day)
        return String(localized: "Tiempo libre calculado entre las \(start) y las \(end).")
    }

    private func stat(_ value: String, label: LocalizedStringResource, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}
