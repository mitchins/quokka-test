import XCTest

/// A wrapped text field with shared QuokkaTest actions plus text-entry helpers.
@MainActor
public struct UITestField: UITestActionSurface {
    public let raw: XCUIElement
    public let locator: UITestLocatorContext
    public let timeouts: UITestTimeouts
    public let application: XCUIApplication
    public let diagnosticsConfiguration: UITestDiagnosticsConfiguration

    /// Creates a wrapped field from any raw `XCUIElement`.
    public init(
        raw: XCUIElement,
        locator: UITestLocatorContext,
        timeouts: UITestTimeouts = .init(),
        application: XCUIApplication,
        diagnostics: UITestDiagnosticsConfiguration = .init()
    ) {
        self.raw = raw
        self.locator = locator
        self.timeouts = timeouts
        self.application = application
        self.diagnosticsConfiguration = diagnostics
    }

    /// Types additional text into the current field contents.
    @discardableResult
    public func enterText(
        _ text: String,
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        tapWhenReady(timeout: timeout, file: file, line: line)
        raw.typeText(text)
        return self
    }

    /// Replaces any existing text in the field before typing the new value.
    @discardableResult
    public func clearAndEnter(
        _ text: String,
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        tapWhenReady(timeout: timeout, file: file, line: line)
        raw.clearText()
        raw.typeText(text)
        return self
    }
}
