import XCTest

@MainActor
/// A wrapped button with shared QuokkaTest actions and assertions.
public struct UITestButton {
    public let raw: XCUIElement
    public let identifier: String
    public let timeouts: UITestTimeouts

    /// Creates a wrapped button from any raw `XCUIElement`.
    public init(
        raw: XCUIElement,
        identifier: String,
        timeouts: UITestTimeouts = .init()
    ) {
        self.raw = raw
        self.identifier = identifier
        self.timeouts = timeouts
    }

    /// Asserts that the button exists within the provided timeout.
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

    /// Asserts that the button both exists and is hittable.
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

    /// Waits for the button to become hittable, then taps it.
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
}
