import XCTest

@MainActor
/// A wrapped text field with shared QuokkaTest actions plus text-entry helpers.
public struct UITestField: _UITestActionSurface {
    public let raw: XCUIElement
    public let identifier: String
    public let timeouts: UITestTimeouts
    public let application: XCUIApplication

    /// Creates a wrapped field from any raw `XCUIElement`.
    public init(
        raw: XCUIElement,
        identifier: String,
        timeouts: UITestTimeouts = .init(),
        application: XCUIApplication = XCUIApplication()
    ) {
        self.raw = raw
        self.identifier = identifier
        self.timeouts = timeouts
        self.application = application
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
        raw.clearText(in: application, timeouts: timeouts)
        raw.typeText(text)
        return self
    }
}
