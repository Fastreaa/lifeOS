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

extension XCUIElement {
    /// Toca un campo de texto y escribe en él cuando de verdad tiene el foco.
    ///
    /// Si el campo está en una hoja que aún se está animando, el primer toque
    /// puede no darle el foco y `typeText` falla con "Neither element nor any
    /// descendant has keyboard focus". Aquí se espera a que se pueda tocar y se
    /// reintenta el toque hasta que el campo tenga el foco.
    @MainActor
    func tapAndType(_ text: String, attempts: Int = 3) {
        waitUntilHittable()
        for _ in 0..<attempts {
            tap()
            if hasKeyboardFocus {
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        typeText(text)
    }

    @MainActor
    private func waitUntilHittable(timeout: TimeInterval = 5) {
        let deadline = Date().addingTimeInterval(timeout)
        while !isHittable && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.2)
        }
    }

    @MainActor
    private var hasKeyboardFocus: Bool {
        (value(forKey: "hasKeyboardFocus") as? Bool) ?? false
    }
}
