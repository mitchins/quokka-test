import Foundation
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
        let waitTimeout = timeout ?? timeouts.normal
        let deadline = Date().addingTimeInterval(waitTimeout)

        while Date() < deadline {
            if element.isHittable {
                return
            }
            Thread.sleep(forTimeInterval: 0.05)
        }

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

@MainActor
public protocol UITestActionSurface {
    var raw: XCUIElement { get }
    var identifier: String { get }
    var timeouts: UITestTimeouts { get }
}

@MainActor
extension UITestActionSurface {
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
