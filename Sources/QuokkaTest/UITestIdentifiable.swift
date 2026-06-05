import Foundation

/// A consumer-owned identifier type used to centralize accessibility identifiers.
public protocol UITestIdentifiable {
    var rawValue: String { get }
}

public extension UITestIdentifiable {
    /// The default locator for typed app identifiers.
    var locator: UITestLocator {
        .id(rawValue)
    }
}
