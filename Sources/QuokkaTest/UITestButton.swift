import XCTest

/// A wrapped button with shared QuokkaTest actions and assertions.
@MainActor
public struct UITestButton: UITestActionSurface {
    public let raw: XCUIElement
    public let locator: UITestLocatorContext
    public let timeouts: UITestTimeouts
    public let application: XCUIApplication
    public let diagnosticsConfiguration: UITestDiagnosticsConfiguration

    /// Creates a wrapped button from any raw `XCUIElement`.
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
}
