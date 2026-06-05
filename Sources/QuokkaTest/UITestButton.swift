import XCTest

@MainActor
/// A wrapped button with shared QuokkaTest actions and assertions.
public struct UITestButton: _UITestActionSurface {
    public let raw: XCUIElement
    public let identifier: String
    public let timeouts: UITestTimeouts

    /// Creates a wrapped button from any raw `XCUIElement`.
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
