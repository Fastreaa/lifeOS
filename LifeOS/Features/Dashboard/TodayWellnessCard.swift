import SwiftUI

/// Tarjeta del dashboard con el check-in de hoy o la invitación a hacerlo.
struct TodayWellnessCard: View {
    let viewModel: WellnessViewModel
    let onCheckIn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CardHeader(title: "Cómo estás", systemImage: "heart.text.square", tint: .lifeWellness)
                Spacer()
                if viewModel.todayCheckIn != nil {
                    Button("Editar", action: onCheckIn)
                        .buttonStyle(.borderless)
                }
            }

            if let checkIn = viewModel.todayCheckIn {
                CheckInSummaryView(checkIn: checkIn)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("dashboard.wellnessSummary")
            } else {
                Text("¿Cómo te sientes hoy? Registrarlo toma unos segundos.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                Button(action: onCheckIn) {
                    Label("Registrar", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.lifeWellness)
                .accessibilityIdentifier("dashboard.checkIn")
            }
        }
        .padding(.vertical, 4)
    }
}
