import Foundation

/// Resumen del día calculado a partir de las tareas pendientes.
/// Lógica pura: recibe la hora y el calendario para poder probarla.
nonisolated struct DaySummary: Equatable, Sendable {
    let pendingCount: Int
    let dueTodayCount: Int
    /// Tareas cuya fecha límite fue antes de hoy. Se muestran en tono neutro.
    let pastDueCount: Int
    /// Suma de duraciones estimadas de las tareas que vencen hoy.
    let estimatedMinutesDueToday: Int

    init(pending: [TaskItem], now: Date, calendar: Calendar) {
        let startOfToday = calendar.startOfDay(for: now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)
            ?? startOfToday.addingTimeInterval(86_400)

        let dueToday = pending.filter { task in
            guard let due = task.dueDate else { return false }
            return due >= startOfToday && due < startOfTomorrow
        }
        let pastDue = pending.filter { task in
            guard let due = task.dueDate else { return false }
            return due < startOfToday
        }

        pendingCount = pending.count
        dueTodayCount = dueToday.count
        pastDueCount = pastDue.count
        estimatedMinutesDueToday = dueToday.compactMap(\.estimatedMinutes).reduce(0, +)
    }
}
