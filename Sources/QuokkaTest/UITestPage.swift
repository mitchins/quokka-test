import Foundation
import XCTest

@MainActor
public enum UITestPageAnchor {
    case locator(UITestLocator)
    case locatorChain(UITestLocatorChain)
    case staticText(String)
    case heading(String)
    case navigationTitle(String)
}

@MainActor
public enum UITestPageReadiness {
    case none
    case locator(UITestLocator)
    case locatorChain(UITestLocatorChain)
    case staticText(String)
    case heading(String)
    case navigationTitle(String)
    case buttonTitle(String)
    case notExists(UITestLocator)
    case notExistsChain(UITestLocatorChain)
    case valueEquals(UITestLocator, String)
}

@MainActor
public struct UITestPage {
    private let app: UITestApp
    private let anchor: UITestPageAnchor
    private let readiness: UITestPageReadiness?

    public init(
        app: UITestApp,
        anchor: UITestPageAnchor,
        readiness: UITestPageReadiness? = nil
    ) {
        self.app = app
        self.anchor = anchor
        self.readiness = readiness
    }

    public func requiring(_ readiness: UITestPageReadiness) -> UITestPage {
        UITestPage(app: app, anchor: anchor, readiness: readiness)
    }

    @discardableResult
    public func waitUntilReady(
        requiring readiness: UITestPageReadiness,
        timeout: TimeInterval
    ) -> Self {
        requiring(readiness).waitUntilReady(timeout: timeout)
        return self
    }

    @discardableResult
    public func waitUntilReady(
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let waitTimeout = timeout ?? app.timeouts.normal
        let anchorIdentifier = app.resolvePageIdentifier(for: anchor)
        let readinessIdentifier = readiness.map { app.resolvePageIdentifier(for: $0) }

        let anchorView = app.resolvePageElement(for: anchor)
        if !anchorView.raw.waitForExistence(timeout: waitTimeout) {
            app.failWithDiagnostics(
                action: "page.waitUntilReady",
                details: "Expected anchor to be present: \(anchorIdentifier)",
                locator: anchorIdentifier,
                timeout: waitTimeout,
                file: file,
                line: line
            )
            return self
        }

        guard let readiness else {
            return self
        }

        var isReady = false
        switch readiness {
        case .notExists(let locator):
            let readinessView = app.element(locator, resolution: .crossSurface)
            isReady = UITestWaiter.until(timeout: waitTimeout) {
                !readinessView.raw.exists
            }
        case .notExistsChain(let locatorChain):
            let readinessView = app.element(locatorChain, resolution: .crossSurface)
            isReady = UITestWaiter.until(timeout: waitTimeout) {
                !readinessView.raw.exists
            }
        case let .valueEquals(locator, expected):
            let readinessView = app.element(locator, resolution: .crossSurface)
            var actualValue: String?
            isReady = false

            func normalized(_ value: String?, for placeholder: String?) -> String {
                if let value {
                    if expected.isEmpty && !value.isEmpty && value == placeholder {
                        return ""
                    }
                    return value
                }
                return ""
            }

            isReady = UITestWaiter.until(timeout: waitTimeout) {
                if readinessView.raw.exists {
                    actualValue = readinessView.raw.value as? String
                    let placeholderValue = readinessView.raw.placeholderValue
                    return normalized(actualValue, for: placeholderValue) == expected
                }
                return false
            }
            if !isReady {
                let details = "Expected readiness value to equal \(expected), got \(String(describing: actualValue))"
                app.failWithDiagnostics(
                    action: "page.waitUntilReady",
                    details: "\(details). Readiness: \(readinessIdentifier ?? "none")\nPage anchor: \(anchorIdentifier)",
                    locator: readinessIdentifier ?? anchorIdentifier,
                    timeout: waitTimeout,
                    file: file,
                    line: line
                )
            }
            return self
        default:
            let readinessView = app.resolvePageElement(for: readiness)
            isReady = readinessView.raw.waitForExistence(timeout: waitTimeout)
        }

        if !isReady {
            let details = "Expected readiness condition to be present: \(readinessIdentifier ?? "none")"
            app.failWithDiagnostics(
                action: "page.waitUntilReady",
                details: "\(details)\nPage anchor: \(anchorIdentifier)",
                locator: readinessIdentifier ?? anchorIdentifier,
                timeout: waitTimeout,
                file: file,
                line: line
            )
        }

        return self
    }

    @discardableResult
    public func assertReady(
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        waitUntilReady(timeout: timeout, file: file, line: line)
        return self
    }
}
