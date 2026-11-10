import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? Color.accentColor : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(task.isCompleted ? "Marcar como pendiente" : "Marcar como completada")

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? Color.secondary : Color.primary)

                if let details {
                    Text(details)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }

            Spacer(minLength: 0)

            if task.priority == .high && !task.isCompleted {
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(Color.orange)
                    .accessibilityLabel("Prioridad alta")
            }
        }
        .padding(.vertical, 2)
    }

    /// Fecha límite y duración, solo si existen.
    private var details: String? {
        var parts: [String] = []
        if let due = task.dueDate {
            parts.append(Self.dueText(for: due))
        }
        if let minutes = task.estimatedMinutes {
            parts.append(
                Duration.seconds(minutes * 60)
                    .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
            )
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// "Hoy, 18:00", "Mañana, 9:00" o la fecha abreviada.
    private static func dueText(for due: Date, calendar: Calendar = .current) -> String {
        let time = due.formatted(date: .omitted, time: .shortened)
        if calendar.isDateInToday(due) {
            return String(localized: "Hoy, \(time)")
        }
        if calendar.isDateInTomorrow(due) {
            return String(localized: "Mañana, \(time)")
        }
        return due.formatted(date: .abbreviated, time: .shortened)
    }
}
