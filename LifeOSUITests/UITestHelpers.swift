import XCTest

extension XCUIApplication {
    /// Desliza hacia arriba hasta que el elemento aparezca.
    ///
    /// Las listas de SwiftUI solo crean las filas visibles: un elemento que está
    /// fuera de pantalla no "existe" para las pruebas hasta que se desplaza
    /// hasta él, igual que haría una persona.
    @MainActor
    func scrollUntilExists(_ element: XCUIElement, maxSwipes: Int = 6) -> Bool {
        if element.waitForExistence(timeout: 2) {
            return true
        }
        for _ in 0..<maxSwipes {
            swipeUp()
            if element.waitForExistence(timeout: 1) {
                return true
            }
        }
        return false
    }
}
