import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            TimelineView(.everyMinute) { context in
                ContentUnavailableView {
                    Label("Tu día está despejado", systemImage: "sun.max")
                } description: {
                    Text("Aquí verás tus tareas y bloques de tiempo de hoy.")
                }
                .accessibilityIdentifier("dashboard.emptyState")
                .navigationTitle(Text(DayPeriod(date: context.date).greeting))
            }
        }
    }
}

#Preview {
    DashboardView()
}
