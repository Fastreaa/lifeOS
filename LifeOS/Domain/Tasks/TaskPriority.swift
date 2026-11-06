import Foundation

/// Importancia relativa de una tarea.
/// El valor entero se usa para ordenar y para persistir.
nonisolated enum TaskPriority: Int, CaseIterable, Comparable, Sendable {
    case low = 0
    case medium = 1
    case high = 2

    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
