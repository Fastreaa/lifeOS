import Foundation

extension TaskPriority {
    var label: LocalizedStringResource {
        switch self {
        case .low: "Baja"
        case .medium: "Media"
        case .high: "Alta"
        }
    }
}
