import SwiftUI

/// Frase sobre si las tareas de hoy caben en el tiempo libre.
/// Tono tranquilo: informa y sugiere, nunca alarma ni culpa.
struct PlanFitLabel: View {
    let plan: DayPlan

    var body: some View {
        Label {
            Text(message)
        } icon: {
            Image(systemName: symbolName)
                .foregroundStyle(color)
        }
        .font(.subheadline)
    }

    private var tasks: String { AgendaFormat.duration(plan.taskMinutes) }
    private var free: String { AgendaFormat.duration(plan.freeMinutes) }

    private var message: String {
        switch plan.fit {
        case .nothingPending:
            String(localized: "No hay tareas con duración estimada para hoy.")
        case .fits:
            String(localized: "Tus tareas de hoy (≈ \(tasks)) caben en tu tiempo libre (\(free)).")
        case .tight:
            String(localized: "Cabe, pero justo: ≈ \(tasks) de tareas para \(free) libres. Deja algo de margen.")
        case .overloaded(let excess):
            String(localized: "Tienes \(free) libres y ≈ \(tasks) de tareas: quizá conviene mover unas \(AgendaFormat.duration(excess)) a otro día.")
        }
    }

    private var symbolName: String {
        switch plan.fit {
        case .nothingPending: "checklist"
        case .fits: "checkmark.circle.fill"
        case .tight: "hourglass"
        case .overloaded: "arrow.right.circle.fill"
        }
    }

    private var color: Color {
        switch plan.fit {
        case .nothingPending: .secondary
        case .fits: .green
        case .tight, .overloaded: .orange
        }
    }
}
