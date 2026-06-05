import XCTest

@MainActor
/// A generic wrapped UI element with shared QuokkaTest actions and assertions.
public struct UITestElement: _UITestActionSurface {
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

}
