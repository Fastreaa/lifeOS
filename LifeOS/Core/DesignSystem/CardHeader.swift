import SwiftUI

/// Encabezado común de las tarjetas: icono del módulo con su color y título.
struct CardHeader: View {
    let title: LocalizedStringResource
    let systemImage: String
    let tint: Color

    var body: some View {
        Label {
            Text(title)
                .font(.headline)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
    }
}
