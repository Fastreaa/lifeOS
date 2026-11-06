import Foundation

/// Motivos por los que una tarea no cumple las reglas del dominio.
nonisolated enum TaskValidationError: Error, Equatable, Sendable {
    case emptyTitle
    case titleTooLong(maxLength: Int)
    case estimateOutOfRange(ClosedRange<Int>)
}
