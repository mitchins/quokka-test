import XCTest

@MainActor
/// A generic wrapped UI element with shared QuokkaTest actions and assertions.
public struct UITestElement {
    public let raw: XCUIElement
    public let identifier: String
    public let timeouts: UITestTimeouts

    /// Creates a wrapped element from any raw `XCUIElement`.
    public init(
        raw: XCUIElement,
        identifier: String,
        timeouts: UITestTimeouts = .init()
    ) {
        self.raw = raw
        self.identifier = identifier
        self.timeouts = timeouts
    }

    /// Asserts that the element exists within the provided timeout.
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

    /// Asserts that the element both exists and is hittable.
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

    /// Waits for the element to become hittable, then taps it.
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
