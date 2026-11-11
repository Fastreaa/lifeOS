import Foundation

/// ¿Caben las tareas estimadas en el tiempo libre?
nonisolated enum PlanFit: Equatable, Sendable {
    /// No hay tareas con duración estimada para hoy.
    case nothingPending
    case fits
    /// Cabe, pero con menos del 20 % de margen.
    case tight
    case overloaded(excessMinutes: Int)
}

/// Dos bloques que se solapan.
nonisolated struct BlockConflict: Equatable, Sendable {
    let first: UUID
    let second: UUID
}

/// Análisis de un día: tiempo ocupado, descanso, tiempo libre y conflictos.
/// Lógica pura: no depende de la interfaz ni de la base de datos.
nonisolated struct DayPlan: Equatable, Sendable {
    /// Ventana del día en la que se calcula el tiempo libre: de 7:00 a 23:00.
    static let defaultWindow = (7 * 60)...(23 * 60)

    let window: ClosedRange<Int>
    /// Minutos dentro de la ventana ocupados por bloques que no son descanso.
    let busyMinutes: Int
    /// Minutos de descanso planificado que no coinciden con bloques ocupados.
    let restMinutes: Int
    /// Minutos de la ventana sin ningún bloque.
    let freeMinutes: Int
    let taskMinutes: Int
    let conflicts: [BlockConflict]
    let fit: PlanFit

    var conflictingBlockIDs: Set<UUID> {
        Set(conflicts.flatMap { [$0.first, $0.second] })
    }

    init(blocks: [TimeBlock], taskMinutes: Int, window: ClosedRange<Int> = DayPlan.defaultWindow) {
        let active = blocks.filter { !$0.isDeleted }.sorted { $0.startMinute < $1.startMinute }
        self.window = window
        self.taskMinutes = max(taskMinutes, 0)

        let all = active.map { Self.clip($0, to: window) }
        let busy = active.filter { $0.kind != .rest }.map { Self.clip($0, to: window) }
        let plannedMinutes = Self.unionLength(all)
        let busyTotal = Self.unionLength(busy)

        busyMinutes = busyTotal
        restMinutes = plannedMinutes - busyTotal
        freeMinutes = (window.upperBound - window.lowerBound) - plannedMinutes

        var found: [BlockConflict] = []
        for (index, block) in active.enumerated() {
            for other in active[(index + 1)...] where block.overlaps(other) {
                found.append(BlockConflict(first: block.id, second: other.id))
            }
        }
        conflicts = found

        let pending = max(taskMinutes, 0)
        if pending == 0 {
            fit = .nothingPending
        } else if pending > freeMinutes {
            fit = .overloaded(excessMinutes: pending - freeMinutes)
        } else if Double(pending) > Double(freeMinutes) * 0.8 {
            fit = .tight
        } else {
            fit = .fits
        }
    }

    private static func clip(_ block: TimeBlock, to window: ClosedRange<Int>) -> (start: Int, end: Int) {
        (max(block.startMinute, window.lowerBound), min(block.endMinute, window.upperBound))
    }

    /// Duración total de la unión de intervalos (sin contar dos veces lo que se solapa).
    static func unionLength(_ intervals: [(start: Int, end: Int)]) -> Int {
        let sorted = intervals.filter { $0.end > $0.start }.sorted { $0.start < $1.start }
        var total = 0
        var current: (start: Int, end: Int)?
        for interval in sorted {
            if let open = current, interval.start <= open.end {
                current = (open.start, max(open.end, interval.end))
            } else {
                if let open = current {
                    total += open.end - open.start
                }
                current = interval
            }
        }
        if let open = current {
            total += open.end - open.start
        }
        return total
    }
}

/// El bloque en curso o, si no hay, el siguiente del día.
nonisolated struct UpcomingBlock: Equatable, Sendable {
    let block: TimeBlock
    let isCurrent: Bool

    static func find(in blocks: [TimeBlock], atMinute minute: Int) -> UpcomingBlock? {
        let sorted = blocks.filter { !$0.isDeleted }.sorted { $0.startMinute < $1.startMinute }
        if let current = sorted.first(where: { $0.startMinute <= minute && minute < $0.endMinute }) {
            return UpcomingBlock(block: current, isCurrent: true)
        }
        if let next = sorted.first(where: { $0.startMinute > minute }) {
            return UpcomingBlock(block: next, isCurrent: false)
        }
        return nil
    }
}
