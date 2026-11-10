import Foundation

extension TaskValidationError {
    /// Mensaje para mostrar al usuario: dice qué hacer, sin culpar.
    var userMessage: String {
        switch self {
        case .emptyTitle:
            String(localized: "Escribe un título para la tarea.")
        case .titleTooLong(let maxLength):
            String(localized: "El título puede tener como máximo \(maxLength) caracteres.")
        case .estimateOutOfRange(let range):
            String(localized: "La duración debe estar entre \(range.lowerBound) y \(range.upperBound) minutos.")
        }
    }
}
