import SwiftUI

struct HabitRowView: View {
    let overview: HabitOverview
    let onToggle: () -> Void
    var calendar: Calendar = .current

    private var habit: Habit { overview.habit }
    private var progress: HabitProgress { overview.progress }
    private var isDone: Bool { progress.isCompletedToday }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: habit.symbolName)
                .font(.title3)
                .foregroundStyle(Color.lifeHabits)
                .frame(width: 40, height: 40)
                .background(Color.lifeHabits.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }

            Spacer(minLength: 0)

            if progress.isScheduledToday {
                Button(action: onToggle) {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isDone ? Color.lifeHabits : Color.secondary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(isDone ? "Desmarcar hoy" : "Marcar como hecho hoy")
                .accessibilityIdentifier("habit.toggle")
            } else {
                Text("Hoy descansa")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    /// Días en que toca y progreso reciente, solo lo que aporte información.
    private var subtitle: String {
        var parts = [scheduleText]
        if progress.currentStreak == 1 {
            parts.append(String(localized: "1 día seguido"))
        } else if progress.currentStreak > 1 {
            parts.append(String(localized: "\(progress.currentStreak) días seguidos"))
        }
        if progress.completedLast7Days > 0 {
            parts.append(String(localized: "\(progress.completedLast7Days) de \(progress.scheduledLast7Days) en 7 días"))
        }
        return parts.joined(separator: " · ")
    }

    private var scheduleText: String {
        if habit.isDaily {
            return String(localized: "Todos los días")
        }
        let ordered = (0..<7)
            .map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }
            .filter { habit.weekdays.contains($0) }
        return ordered.map { calendar.shortWeekdaySymbols[$0 - 1] }.joined(separator: ", ")
    }
}
