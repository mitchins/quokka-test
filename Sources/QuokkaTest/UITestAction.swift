import Foundation
import XCTest

@MainActor
enum UITestFailureReporter {
    static func report(
        action: String,
        details: String,
        locator: String,
        application: XCUIApplication,
        diagnostics: UITestDiagnosticsConfiguration,
        timeout: TimeInterval,
        file: StaticString,
        line: UInt
    ) {
        if diagnostics.attachScreenshotOnFailure {
            let screenshot = XCTAttachment(screenshot: application.screenshot())
            screenshot.name = "Failure screenshot: \(action)"
            screenshot.lifetime = .keepAlways
            XCTContext.runActivity(named: "Attach screenshot: \(action)") { activity in
                activity.add(screenshot)
            }
        }

        if diagnostics.attachHierarchyOnFailure {
            let hierarchy = XCTAttachment(string: application.debugDescription)
            hierarchy.name = "Failure hierarchy: \(action)"
            hierarchy.lifetime = .keepAlways
            XCTContext.runActivity(named: "Attach hierarchy: \(action)") { activity in
                activity.add(hierarchy)
            }
        }

        let locatorPrefix = locator.isEmpty ? "" : " Locator: \(locator)."
        XCTFail(
            "Action '\(action)' failed.\(locatorPrefix) \(details). Timeout: \(String(format: "%.2f", timeout))s",
            file: file,
            line: line
        )
    }
}

@MainActor
enum UITestWaiter {
    static func until(
        timeout: TimeInterval,
        pollInterval: TimeInterval = 0.05,
        condition: () -> Bool
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if condition() {
                return true
            }

            let remaining = deadline.timeIntervalSinceNow
            if remaining <= 0 {
                break
            }

            yield(for: min(pollInterval, remaining))
        } while Date() < deadline

        return condition()
    }

    static func yield(for interval: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(interval))
    }
}

@MainActor
public enum UITestSync {
    public static func until(
        timeout: TimeInterval,
        pollInterval: TimeInterval = 0.05,
        condition: @escaping () -> Bool
    ) -> Bool {
        UITestWaiter.until(
            timeout: timeout,
            pollInterval: pollInterval,
            condition: condition
        )
    }

    public static func untilAllExist(
        _ elements: [any UITestActionSurface],
        timeout: TimeInterval,
        pollInterval: TimeInterval = 0.05
    ) -> Bool {
        until(timeout: timeout, pollInterval: pollInterval) {
            elements.allSatisfy(\.raw.exists)
        }
    }

    public static func untilAllNotExist(
        _ elements: [any UITestActionSurface],
        timeout: TimeInterval,
        pollInterval: TimeInterval = 0.05
    ) -> Bool {
        until(timeout: timeout, pollInterval: pollInterval) {
            elements.allSatisfy { !$0.raw.exists }
        }
    }
}

@MainActor
public struct UITestMatchQuery {
    public let raw: XCUIElementQuery
    public let locator: UITestLocatorContext
    public let surface: String
    public let timeouts: UITestTimeouts
    public let application: XCUIApplication
    public let diagnosticsConfiguration: UITestDiagnosticsConfiguration

    public var count: Int {
        raw.count
    }

    @discardableResult
    public func assertCount(
        _ expectedCount: Int,
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.assertCount(
            self,
            expectedCount,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    func fail(
        action: String,
        details: String,
        timeout: TimeInterval,
        file: StaticString,
        line: UInt
    ) {
        UITestFailureReporter.report(
            action: action,
            details: details,
            locator: "\(surface): \(locator.description)",
            application: application,
            diagnostics: diagnosticsConfiguration,
            timeout: timeout,
            file: file,
            line: line
        )
    }
}

@MainActor
enum UITestAction {
    static func assertExists(
        _ element: UITestActionSurface,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        let waitTimeout = timeout ?? timeouts.normal
        if !element.raw.waitForExistence(timeout: waitTimeout) {
            element.fail(
                action: "assertExists",
                details: failureDetails(
                    "Expected element to exist",
                    locator: element.locator
                ),
                timeout: waitTimeout,
                file: file,
                line: line
            )
        }
    }

    static func assertHittable(
        _ element: UITestActionSurface,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        assertExists(
            element,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )

        let waitTimeout = timeout ?? timeouts.normal
        if UITestWaiter.until(timeout: waitTimeout, condition: {
            element.raw.isHittable
        }) {
            return
        }

        element.fail(
            action: "assertHittable",
            details: "Expected element to be hittable",
            timeout: waitTimeout,
            file: file,
            line: line
        )
    }

    static func tapWhenReady(
        _ element: UITestActionSurface,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        assertHittable(
            element,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        element.raw.tap()
    }

    static func assertNotExists(
        _ element: UITestActionSurface,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        let waitTimeout = timeout ?? timeouts.short
        if !element.raw.exists {
            return
        }

        if UITestWaiter.until(timeout: waitTimeout, condition: {
            !element.raw.exists
        }) {
            return
        }

        element.fail(
            action: "assertNotExists",
            details: "Expected element to not exist",
            timeout: waitTimeout,
            file: file,
            line: line
        )
    }

    static func waitUntilExists(
        _ element: UITestActionSurface,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        let waitTimeout = timeout ?? timeouts.normal
        if element.raw.waitForExistence(timeout: waitTimeout) {
            return
        }

        element.fail(
            action: "waitUntilExists",
            details: failureDetails(
                "Expected element to exist before timeout expired",
                locator: element.locator
            ),
            timeout: waitTimeout,
            file: file,
            line: line
        )
    }

    static func waitUntilNotExists(
        _ element: UITestActionSurface,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        let waitTimeout = timeout ?? timeouts.short
        if !element.raw.exists {
            return
        }

        if UITestWaiter.until(timeout: waitTimeout, condition: {
            !element.raw.exists
        }) {
            return
        }

        element.fail(
            action: "waitUntilNotExists",
            details: failureDetails(
                "Expected element to stop existing before timeout expired",
                locator: element.locator
            ),
            timeout: waitTimeout,
            file: file,
            line: line
        )
    }

    static func assertEnabled(
        _ element: UITestActionSurface,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        let waitTimeout = timeout ?? timeouts.normal
        if UITestWaiter.until(timeout: waitTimeout, condition: {
            element.raw.isEnabled
        }) {
            return
        }

        element.fail(
            action: "assertEnabled",
            details: "Expected element to be enabled",
            timeout: waitTimeout,
            file: file,
            line: line
        )
    }

    static func assertDisabled(
        _ element: UITestActionSurface,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        let waitTimeout = timeout ?? timeouts.normal
        if UITestWaiter.until(timeout: waitTimeout, condition: {
            !element.raw.isEnabled
        }) {
            return
        }

        element.fail(
            action: "assertDisabled",
            details: "Expected element to be disabled",
            timeout: waitTimeout,
            file: file,
            line: line
        )
    }

    static func assertValueEquals(
        _ element: UITestActionSurface,
        _ expected: String,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        let waitTimeout = timeout ?? timeouts.normal
        var last = element.raw.value as? String

        if UITestWaiter.until(timeout: waitTimeout, condition: {
            last = element.raw.value as? String
            return last == expected
        }) {
            return
        }

        element.fail(
            action: "assertValueEquals",
            details: "Expected value to equal \(expected), got \(String(describing: last))",
            timeout: waitTimeout,
            file: file,
            line: line
        )
    }

    static func assertLabelEquals(
        _ element: UITestActionSurface,
        _ expected: String,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        let waitTimeout = timeout ?? timeouts.normal
        var last = element.raw.label

        if UITestWaiter.until(timeout: waitTimeout, condition: {
            last = element.raw.label
            return last == expected
        }) {
            return
        }

        element.fail(
            action: "assertLabelEquals",
            details: "Expected label to equal \(expected), got \(last)",
            timeout: waitTimeout,
            file: file,
            line: line
        )
    }

    static func assertLabelContains(
        _ element: UITestActionSurface,
        _ expectedSubstring: String,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        let waitTimeout = timeout ?? timeouts.normal
        var last = element.raw.label

        if UITestWaiter.until(timeout: waitTimeout, condition: {
            last = element.raw.label
            return last.contains(expectedSubstring)
        }) {
            return
        }

        element.fail(
            action: "assertLabelContains",
            details: "Expected label to contain \(expectedSubstring), got \(last)",
            timeout: waitTimeout,
            file: file,
            line: line
        )
    }

    static func assertMatchCount(
        _ element: UITestActionSurface,
        _ expectedCount: Int,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        guard let predicate = countPredicate(for: element.raw, locator: element.locator) else {
            element.fail(
                action: "assertMatchCount",
                details: "Cannot determine a stable match predicate for count assertions",
                timeout: timeout ?? timeouts.short,
                file: file,
                line: line
            )
            return
        }

        let waitTimeout = timeout ?? timeouts.short
        var matchCount = element.application.descendants(matching: .any).matching(predicate).count

        if UITestWaiter.until(timeout: waitTimeout, condition: {
            matchCount = element.application.descendants(matching: .any).matching(predicate).count
            return matchCount == expectedCount
        }) {
            return
        }

        element.fail(
            action: "assertMatchCount",
            details: "Expected \(expectedCount) matching elements, got \(matchCount)",
            timeout: waitTimeout,
            file: file,
            line: line
        )
    }

    static func assertCount(
        _ query: UITestMatchQuery,
        _ expectedCount: Int,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        let waitTimeout = timeout ?? query.timeouts.short
        var matchCount = query.raw.count

        if UITestWaiter.until(timeout: waitTimeout, condition: {
            matchCount = query.raw.count
            return matchCount == expectedCount
        }) {
            return
        }

        query.fail(
            action: "assertCount",
            details: "Expected \(expectedCount) matches, got \(matchCount)",
            timeout: waitTimeout,
            file: file,
            line: line
        )
    }

    private static func countPredicate(
        for element: XCUIElement,
        locator: UITestLocatorContext
    ) -> NSPredicate? {
        let identityLocator = preferredCountLocator(for: element, locator: locator)
        guard let identityLocator else {
            return nil
        }

        let typePredicate = NSPredicate(
            format: "elementType == %@",
            element.elementType.rawValue as NSNumber
        )
        let identityPredicate = predicate(for: identityLocator)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [typePredicate, identityPredicate])
    }

    private static func preferredCountLocator(
        for element: XCUIElement,
        locator: UITestLocatorContext
    ) -> UITestLocator? {
        if !element.identifier.isEmpty {
            return .id(element.identifier)
        }
        if !element.label.isEmpty {
            return .label(element.label)
        }
        if let value = element.value as? String, !value.isEmpty {
            return .value(value)
        }
        if let placeholder = element.placeholderValue, !placeholder.isEmpty {
            return .placeholder(placeholder)
        }
        return locator.chain?.locators.first
    }

    private static func predicate(for locator: UITestLocator) -> NSPredicate {
        switch locator {
        case let .id(value):
            return NSPredicate(format: "identifier == %@", value)
        case let .label(value):
            return NSPredicate(format: "label == %@", value)
        case let .value(value):
            return NSPredicate(format: "value == %@", value)
        case let .placeholder(value):
            return NSPredicate(format: "placeholderValue == %@", value)
        }
    }

    static func assertSelected(
        _ element: UITestActionSurface,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        let waitTimeout = timeout ?? timeouts.normal
        if UITestWaiter.until(timeout: waitTimeout, condition: {
            element.raw.isSelected
        }) {
            return
        }

        element.fail(
            action: "assertSelected",
            details: "Expected element to be selected",
            timeout: waitTimeout,
            file: file,
            line: line
        )
    }

    static func assertNotSelected(
        _ element: UITestActionSurface,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        let waitTimeout = timeout ?? timeouts.normal
        if UITestWaiter.until(timeout: waitTimeout, condition: {
            !element.raw.isSelected
        }) {
            return
        }

        element.fail(
            action: "assertNotSelected",
            details: "Expected element to not be selected",
            timeout: waitTimeout,
            file: file,
            line: line
        )
    }

    static func assertChecked(
        _ element: UITestActionSurface,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        let waitTimeout = timeout ?? timeouts.normal
        var lastValue = describeCheckedState(element.raw)

        if UITestWaiter.until(timeout: waitTimeout, condition: {
            lastValue = describeCheckedState(element.raw)
            return checkedState(of: element.raw) == true
        }) {
            return
        }

        element.fail(
            action: "assertChecked",
            details: "Expected element to be checked, got \(lastValue)",
            timeout: waitTimeout,
            file: file,
            line: line
        )
    }

    static func assertVisible<Container: UITestActionSurface>(
        _ element: UITestActionSurface,
        in container: Container,
        timeouts: UITestTimeouts,
        file: StaticString,
        line: UInt
    ) {
        let waitTimeout = timeouts.normal

        guard element.raw.waitForExistence(timeout: waitTimeout) else {
            element.fail(
                action: "assertVisible(in:)",
                details: visibilityFailureDetails(
                    "Expected element to exist before checking container-relative visibility",
                    element: element,
                    container: container,
                    elementFrame: element.raw.frame,
                    containerFrame: container.raw.frame
                ),
                timeout: waitTimeout,
                file: file,
                line: line
            )
            return
        }

        guard container.raw.waitForExistence(timeout: waitTimeout) else {
            element.fail(
                action: "assertVisible(in:)",
                details: visibilityFailureDetails(
                    "Expected container to exist before checking container-relative visibility",
                    element: element,
                    container: container,
                    elementFrame: element.raw.frame,
                    containerFrame: container.raw.frame
                ),
                timeout: waitTimeout,
                file: file,
                line: line
            )
            return
        }

        let elementFrame = element.raw.frame
        let containerFrame = container.raw.frame

        guard !elementFrame.isEmpty else {
            element.fail(
                action: "assertVisible(in:)",
                details: visibilityFailureDetails(
                    "Expected element frame to be non-empty",
                    element: element,
                    container: container,
                    elementFrame: elementFrame,
                    containerFrame: containerFrame
                ),
                timeout: waitTimeout,
                file: file,
                line: line
            )
            return
        }

        guard !containerFrame.isEmpty else {
            element.fail(
                action: "assertVisible(in:)",
                details: visibilityFailureDetails(
                    "Expected container frame to be non-empty",
                    element: element,
                    container: container,
                    elementFrame: elementFrame,
                    containerFrame: containerFrame
                ),
                timeout: waitTimeout,
                file: file,
                line: line
            )
            return
        }

        guard containerFrame.intersects(elementFrame) else {
            element.fail(
                action: "assertVisible(in:)",
                details: visibilityFailureDetails(
                    "Expected element frame to intersect container frame",
                    element: element,
                    container: container,
                    elementFrame: elementFrame,
                    containerFrame: containerFrame
                ),
                timeout: waitTimeout,
                file: file,
                line: line
            )
            return
        }
    }

    static func assertUnchecked(
        _ element: UITestActionSurface,
        timeouts: UITestTimeouts,
        timeout: TimeInterval?,
        file: StaticString,
        line: UInt
    ) {
        let waitTimeout = timeout ?? timeouts.normal
        var lastValue = describeCheckedState(element.raw)

        if UITestWaiter.until(timeout: waitTimeout, condition: {
            lastValue = describeCheckedState(element.raw)
            return checkedState(of: element.raw) == false
        }) {
            return
        }

        element.fail(
            action: "assertUnchecked",
            details: "Expected element to be unchecked, got \(lastValue)",
            timeout: waitTimeout,
            file: file,
            line: line
        )
    }

    private static func checkedState(of element: XCUIElement) -> Bool? {
        switch element.value {
        case let value as Bool:
            return value
        case let value as NSNumber:
            return value.intValue != 0
        case let value as String:
            switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "1", "true", "on", "checked", "selected":
                return true
            case "0", "false", "off", "unchecked", "unselected":
                return false
            default:
                return nil
            }
        default:
            return element.rawValueBackedSelectionState
        }
    }

    private static func describeCheckedState(_ element: XCUIElement) -> String {
        if let checked = checkedState(of: element) {
            return checked ? "checked" : "unchecked"
        }
        if let value = element.value {
            return String(describing: value)
        }
        return "unknown"
    }

    private static func failureDetails(
        _ base: String,
        locator: UITestLocatorContext
    ) -> String {
        guard let chain = locator.chain, chain.locators.count > 1 else {
            return base
        }
        return "\(base). Attempted locator chain: \(chain.description)"
    }

    private static func visibilityFailureDetails(
        _ base: String,
        element: UITestActionSurface,
        container: some UITestActionSurface,
        elementFrame: CGRect,
        containerFrame: CGRect
    ) -> String {
        "\(base). Element locator: \(element.locator.description). " +
        "Container locator: \(container.locator.description). " +
        "elementFrame=\(frameDescription(elementFrame)). " +
        "containerFrame=\(frameDescription(containerFrame))"
    }

    private static func frameDescription(_ frame: CGRect) -> String {
        "{x: \(String(format: "%.2f", frame.origin.x)), " +
        "y: \(String(format: "%.2f", frame.origin.y)), " +
        "width: \(String(format: "%.2f", frame.size.width)), " +
        "height: \(String(format: "%.2f", frame.size.height))}"
    }
}

private extension XCUIElement {
    var rawValueBackedSelectionState: Bool? {
        isSelected
    }
}

@MainActor
public protocol UITestActionSurface {
    var raw: XCUIElement { get }
    var locator: UITestLocatorContext { get }
    var timeouts: UITestTimeouts { get }
    var application: XCUIApplication { get }
    var diagnosticsConfiguration: UITestDiagnosticsConfiguration { get }
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
            self,
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
            self,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func assertNotExists(
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.assertNotExists(
            self,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func waitUntilExists(
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.waitUntilExists(
            self,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func waitUntilNotExists(
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.waitUntilNotExists(
            self,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func assertEnabled(
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.assertEnabled(
            self,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func assertDisabled(
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.assertDisabled(
            self,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func assertValueEquals(
        _ expected: String,
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.assertValueEquals(
            self,
            expected,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func assertLabelEquals(
        _ expected: String,
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.assertLabelEquals(
            self,
            expected,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func assertLabelContains(
        _ expectedSubstring: String,
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.assertLabelContains(
            self,
            expectedSubstring,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func assertMatchCount(
        _ expectedCount: Int,
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.assertMatchCount(
            self,
            expectedCount,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func assertSelected(
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.assertSelected(
            self,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func assertNotSelected(
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.assertNotSelected(
            self,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func assertChecked(
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.assertChecked(
            self,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func assertUnchecked(
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.assertUnchecked(
            self,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    public func assertVisible(
        in container: some UITestActionSurface,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAction.assertVisible(
            self,
            in: container,
            timeouts: timeouts,
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
            self,
            timeouts: timeouts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    func fail(
        action: String,
        details: String,
        timeout: TimeInterval,
        file: StaticString,
        line: UInt
    ) {
        UITestFailureReporter.report(
            action: action,
            details: details,
            locator: locator.description,
            application: application,
            diagnostics: diagnosticsConfiguration,
            timeout: timeout,
            file: file,
            line: line
        )
    }
}
