import XCTest

/// A generic wrapped UI element with shared QuokkaTest actions and assertions.
@MainActor
public struct UITestElement: UITestActionSurface {
    public let raw: XCUIElement
    public let locator: UITestLocatorContext
    public let timeouts: UITestTimeouts
    public let application: XCUIApplication
    public let diagnosticsConfiguration: UITestDiagnosticsConfiguration

    /// Creates a wrapped element from any raw `XCUIElement`.
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

    /// Repeatedly swipes up on this container until `target` exists/hittable.
    @discardableResult
    public func swipeUpUntilExists(
        _ target: UITestActionSurface,
        maxAttempts: Int = 10,
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let waitTimeout = timeout ?? timeouts.normal
        let deadline = Date().addingTimeInterval(waitTimeout)
        var attempts = 0
        let scrollContainer = raw.exists ? raw : application.scrollViews.firstMatch

        if !scrollContainer.exists {
            fail(
                action: "swipeUpUntilExists",
                details: "Expected a scrollable container matching: \(locator.description)",
                timeout: waitTimeout,
                file: file,
                line: line
            )
            return self
        }

        while Date() < deadline && attempts < maxAttempts {
            if target.raw.isHittable {
                return self
            }

            scrollContainer.swipeUp()
            attempts += 1
            UITestWaiter.yield(for: 0.1)
        }

        if target.raw.waitForExistence(timeout: max(0, deadline.timeIntervalSinceNow)) {
            return self
        }

        fail(
            action: "swipeUpUntilExists",
            details: "Expected target to appear after swiping up. Attempts: \(attempts)",
            timeout: waitTimeout,
            file: file,
            line: line
        )

        return self
    }
}
