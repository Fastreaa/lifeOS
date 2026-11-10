import SwiftUI

/// Tarjeta del dashboard con el resumen de tareas del día.
struct TodayTasksCard: View {
    let summary: DaySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader(title: "Tareas", systemImage: "checklist", tint: .lifeTasks)
            DaySummaryView(summary: summary)
        }
        .padding(.vertical, 4)
    }
}
