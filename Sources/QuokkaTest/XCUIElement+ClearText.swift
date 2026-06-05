import XCTest

@MainActor
extension XCUIElement {
    func clearText() {
        guard let currentValue = value as? String else {
            return
        }

        if currentValue.isEmpty || currentValue == placeholderValue {
            return
        }

        tap()
        let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        typeText(deletes)
    }
}
