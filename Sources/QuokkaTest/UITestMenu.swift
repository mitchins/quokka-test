import Foundation
import XCTest

/// macOS menu-scoped helpers built on top of `UITestElement`.
@MainActor
public struct UITestMenu {
    public let menu: UITestElement
    public let app: UITestApp

    /// Returns labels for direct menu item descendants.
    public func items() -> [String] {
        app.menuItemLabels(in: menu.raw)
    }

    /// Asserts that a menu item exists by locator.
    @discardableResult
    public func assertMenuItemExists(
        _ locator: UITestLocator,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let item = menuItem(locator)
        if !item.raw.waitForExistence(timeout: app.timeouts.short) {
            app.failWithDiagnostics(
                action: "UITestMenu.assertMenuItemExists",
                details: "Expected menu item to exist: \(locator)",
                locator: "\(menu.locator.description) > \(locator)",
                timeout: app.timeouts.short,
                file: file,
                line: line
            )
        }
        return self
    }

    /// Asserts that a menu item exists by label.
    @discardableResult
    public func assertMenuItemExists(
        label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        assertMenuItemExists(.label(label), file: file, line: line)
        return self
    }

    /// Asserts that a menu item is enabled.
    @discardableResult
    public func assertMenuItemEnabled(
        label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let item = menuItem(.label(label))
        if !item.raw.waitForExistence(timeout: app.timeouts.short) {
            app.failWithDiagnostics(
                action: "UITestMenu.assertMenuItemEnabled",
                details: "Expected menu item '\(label)' to exist",
                locator: "\(menu.locator.description) > label(\(label))",
                timeout: app.timeouts.short,
                file: file,
                line: line
            )
            return self
        }
        if !item.raw.isEnabled {
            app.failWithDiagnostics(
                action: "UITestMenu.assertMenuItemEnabled",
                details: "Expected menu item '\(label)' to be enabled",
                locator: "\(menu.locator.description) > label(\(label))",
                timeout: app.timeouts.short,
                file: file,
                line: line
            )
        }
        return self
    }

    /// Asserts that a menu item is disabled.
    @discardableResult
    public func assertMenuItemDisabled(
        label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let item = menuItem(.label(label))
        if !item.raw.waitForExistence(timeout: app.timeouts.short) {
            app.failWithDiagnostics(
                action: "UITestMenu.assertMenuItemDisabled",
                details: "Expected menu item '\(label)' to exist",
                locator: "\(menu.locator.description) > label(\(label))",
                timeout: app.timeouts.short,
                file: file,
                line: line
            )
            return self
        }
        if item.raw.isEnabled {
            app.failWithDiagnostics(
                action: "UITestMenu.assertMenuItemDisabled",
                details: "Expected menu item '\(label)' to be disabled",
                locator: "\(menu.locator.description) > label(\(label))",
                timeout: app.timeouts.short,
                file: file,
                line: line
            )
        }
        return self
    }

    /// Taps a menu item by locator.
    @discardableResult
    public func tapMenuItem(
        _ locator: UITestLocator,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let item = menuItem(locator)
        if !item.raw.waitForExistence(timeout: app.timeouts.short) {
            app.failWithDiagnostics(
                action: "UITestMenu.tapMenuItem",
                details: "Unable to tap menu item; missing: \(locator)",
                locator: "\(menu.locator.description) > \(locator)",
                timeout: app.timeouts.short,
                file: file,
                line: line
            )
            return self
        }

        item.raw.tap()
        return self
    }

    /// Taps a menu item by label.
    @discardableResult
    public func tapMenuItem(label: String) -> Self {
        tapMenuItem(.label(label))
        return self
    }

    /// Resolves menu item from locator for assertion and tap operations.
    private func menuItem(_ locator: UITestLocator) -> UITestElement {
        let query = menu.raw.children(matching: .menuItem)
        let resolved: XCUIElement

        switch locator {
        case let .id(value):
            resolved = query.matching(NSPredicate(format: "identifier == %@", value)).firstMatch
        case let .label(value):
            resolved = query.matching(NSPredicate(format: "label == %@", value)).firstMatch
        case let .value(value):
            resolved = query.matching(NSPredicate(format: "value == %@", value)).firstMatch
        case let .placeholder(value):
            resolved = query.matching(NSPredicate(format: "placeholderValue == %@", value)).firstMatch
        }

        return UITestElement(
            raw: resolved,
            locator: UITestLocatorContext(description: "menu(\(menu.locator.description)).item(\(locator))"),
            timeouts: app.timeouts,
            application: app.raw,
            diagnostics: app.diagnosticsConfiguration
        )
    }
}
