import XCTest

@MainActor
enum UITestAction {
    static func assertExists(
        _ element: XCUIElement,
        identifier: String,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        let waitTimeout = timeout ?? timeouts.normal
        XCTAssertTrue(
            element.waitForExistence(timeout: waitTimeout),
            "Expected element to exist: \(identifier)",
            file: file,
            line: line
        )
    }

    static func assertHittable(
        _ element: XCUIElement,
        identifier: String,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        assertExists(
            element,
            identifier: identifier,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        XCTAssertTrue(
            element.isHittable,
            "Expected element to be hittable: \(identifier)",
            file: file,
            line: line
        )
    }

    static func tapWhenReady(
        _ element: XCUIElement,
        identifier: String,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        assertHittable(
            element,
            identifier: identifier,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        element.tap()
    }
}
