import Foundation

public protocol UITestLocating {
    var uiTestLocatorChain: UITestLocatorChain { get }
}

/// Ordered locator chain used for explicit fallback lookup.
public struct UITestLocatorChain: Sendable, Equatable, UITestLocating {
    public let locators: [UITestLocator]

    public init(_ locators: [UITestLocator]) {
        self.locators = locators
    }

    public init(_ locators: UITestLocator...) {
        self.locators = locators
    }

    public var uiTestLocatorChain: UITestLocatorChain {
        self
    }
}

extension UITestLocatorChain: CustomStringConvertible {
    public var description: String {
        guard !locators.isEmpty else {
            return "first match: <empty locator chain>"
        }
        let detail = locators
            .map(\.description)
            .joined(separator: " -> ")
        return "first match: \(detail)"
    }
}

public struct UITestLocatorContext: Sendable, CustomStringConvertible {
    public let description: String
    public let chain: UITestLocatorChain?

    public init(_ locatorChain: UITestLocatorChain) {
        self.description = locatorChain.description
        self.chain = locatorChain
    }

    public init(description: String) {
        self.description = description
        self.chain = nil
    }
}
