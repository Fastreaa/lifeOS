import SwiftUI

/// Estado editable del formulario de proyectos.
struct ProjectDraft: Equatable {
    var name = ""
    var symbolName = "folder"
    var color: ProjectColor = .teal

    init() {}

    init(project: Project) {
        name = project.name
        symbolName = project.symbolName
        color = project.color
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// Iconos para proyectos, con su nombre para VoiceOver.
struct ProjectSymbol: Identifiable {
    let name: String
    let label: LocalizedStringResource
    var id: String { name }

    static let all: [ProjectSymbol] = [
        ProjectSymbol(name: "folder", label: "Carpeta"),
        ProjectSymbol(name: "graduationcap", label: "Universidad"),
        ProjectSymbol(name: "briefcase", label: "Trabajo"),
        ProjectSymbol(name: "house", label: "Casa"),
        ProjectSymbol(name: "book", label: "Estudio"),
        ProjectSymbol(name: "laptopcomputer", label: "Tecnología"),
        ProjectSymbol(name: "heart", label: "Salud"),
        ProjectSymbol(name: "figure.run", label: "Deporte"),
        ProjectSymbol(name: "cart", label: "Compras"),
        ProjectSymbol(name: "paintbrush", label: "Creatividad"),
        ProjectSymbol(name: "hammer", label: "Arreglos"),
        ProjectSymbol(name: "star", label: "Otro"),
    ]
}

extension ProjectColor {
    var color: Color {
        switch self {
        case .teal: .lifeAccent
        case .blue: .lifeTasks
        case .orange: .lifeHabits
        case .purple: .lifeWellness
        case .pink: .pink
        case .green: .green
        case .gray: .gray
        }
    }

    var label: LocalizedStringResource {
        switch self {
        case .teal: "Turquesa"
        case .blue: "Azul"
        case .orange: "Naranja"
        case .purple: "Violeta"
        case .pink: "Rosa"
        case .green: "Verde"
        case .gray: "Gris"
        }
    }
}

extension ProjectValidationError {
    var userMessage: String {
        switch self {
        case .emptyName:
            String(localized: "Escribe un nombre para el proyecto.")
        case .nameTooLong(let maxLength):
            String(localized: "El nombre puede tener como máximo \(maxLength) caracteres.")
        case .missingSymbol:
            String(localized: "Elige un icono.")
        }
    }
}
