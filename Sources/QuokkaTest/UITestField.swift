import XCTest

@MainActor
/// A wrapped text field with shared QuokkaTest actions plus text-entry helpers.
public struct UITestField {
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

    /// Asserts that the field exists within the provided timeout.
    @discardableResult
    public func assertExists(
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.assertExists(
            raw,
            identifier: identifier,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    /// Asserts that the field both exists and is hittable.
    @discardableResult
    public func assertHittable(
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.assertHittable(
            raw,
            identifier: identifier,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    /// Waits for the field to become hittable, then taps it.
    @discardableResult
    public func tapWhenReady(
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.tapWhenReady(
            raw,
            identifier: identifier,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
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
