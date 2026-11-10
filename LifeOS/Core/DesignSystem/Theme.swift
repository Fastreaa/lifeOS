import SwiftUI
import UIKit

/// Colores de LifeOS. Cada uno tiene versión clara y oscura.
/// Regla: usar estos colores en lugar de valores sueltos en las vistas.
extension Color {
    /// Color principal de la app (botones, selección, pestañas).
    static let lifeAccent = Color.dynamic(light: (0.13, 0.55, 0.53), dark: (0.35, 0.80, 0.76))
    /// Módulo de tareas.
    static let lifeTasks = Color.dynamic(light: (0.20, 0.47, 0.90), dark: (0.42, 0.63, 1.00))
    /// Módulo de hábitos.
    static let lifeHabits = Color.dynamic(light: (0.91, 0.49, 0.16), dark: (1.00, 0.63, 0.32))
    /// Módulo de bienestar.
    static let lifeWellness = Color.dynamic(light: (0.52, 0.38, 0.85), dark: (0.71, 0.60, 1.00))

    /// Color que cambia automáticamente entre modo claro y oscuro.
    static func dynamic(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
        Color(uiColor: UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        })
    }
}
