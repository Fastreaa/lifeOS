import Foundation

/// Progreso de un hábito, calculado a partir de los días cumplidos.
///
/// Reglas pensadas para no castigar:
/// - Los días que no toca el hábito no cortan la racha.
/// - Hoy, si aún no está hecho, tampoco la corta: el día no ha terminado.
/// - Además de la racha se muestra "X de Y en los últimos 7 días", que no se
///   reinicia a cero por un solo día.
nonisolated struct HabitProgress: Equatable, Sendable {
    /// Días hacia atrás que se revisan para calcular la racha.
    static let streakLookbackDays = 366

    let isScheduledToday: Bool
    let isCompletedToday: Bool
    let currentStreak: Int
    let completedLast7Days: Int
    let scheduledLast7Days: Int

    init(habit: Habit, completedDays: Set<LocalDay>, today: LocalDay, calendar: Calendar) {
        isScheduledToday = habit.isScheduled(on: today, calendar: calendar)
        isCompletedToday = completedDays.contains(today)

        var scheduled = 0
        var completed = 0
        for offset in 0..<7 {
            guard let day = today.adding(days: -offset, calendar: calendar),
                  habit.isScheduled(on: day, calendar: calendar) else { continue }
            scheduled += 1
            if completedDays.contains(day) {
                completed += 1
            }
        }
        scheduledLast7Days = scheduled
        completedLast7Days = completed

        var streak = 0
        for offset in 0..<Self.streakLookbackDays {
            guard let day = today.adding(days: -offset, calendar: calendar) else { break }
            guard habit.isScheduled(on: day, calendar: calendar) else { continue }
            if completedDays.contains(day) {
                streak += 1
            } else if offset == 0 {
                continue
            } else {
                break
            }
        }
        currentStreak = streak
    }
}
