import Foundation

/// A generic locator that supports identifier-first lookup with legacy fallback strategies.
public enum UITestLocator: Sendable, Equatable {
    case id(String)
    case label(String)
    case value(String)
    case placeholder(String)
}

extension UITestLocator: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .id(value):
            return "id(\(value))"
        case let .label(value):
            return "label(\(value))"
        case let .value(value):
            return "value(\(value))"
        case let .placeholder(value):
            return "placeholder(\(value))"
        }
    }
}
