import XCTest

@MainActor
/// The root QuokkaTest wrapper around `XCUIApplication`.
public struct UITestApp {
    public let raw: XCUIApplication
    public let timeouts: UITestTimeouts

    /// Creates a wrapper around an existing application instance.
    public init(
        _ raw: XCUIApplication,
        timeouts: UITestTimeouts = .init()
    ) {
        self.raw = raw
        self.timeouts = timeouts
    }

    /// Creates a wrapper around a new `XCUIApplication`.
    public init(
        timeouts: UITestTimeouts = .init()
    ) {
        self.init(XCUIApplication(), timeouts: timeouts)
    }

    /// Launches the host app with merged arguments and environment values.
    @discardableResult
    public func launch(
        arguments: [String] = [],
        environment: [String: String] = [:]
    ) -> Self {
        raw.launchArguments += arguments
        raw.launchEnvironment.merge(environment) { _, new in new }
        raw.launch()
        return self
    }

    /// Wraps a text field resolved from a typed identifier.
    public func field(_ id: any UITestIdentifiable) -> UITestField {
        field(id.locator)
    }

    /// Wraps a text field resolved from a generic locator.
    public func field(_ locator: UITestLocator) -> UITestField {
        UITestField(
            raw: resolveTextField(locator),
            identifier: locator.description,
            timeouts: timeouts,
            application: raw
        )
    }

    /// Wraps a secure text field resolved from a typed identifier.
    public func secureField(_ id: any UITestIdentifiable) -> UITestField {
        secureField(id.locator)
    }

    /// Wraps a secure text field resolved from a generic locator.
    public func secureField(_ locator: UITestLocator) -> UITestField {
        UITestField(
            raw: resolveSecureTextField(locator),
            identifier: locator.description,
            timeouts: timeouts,
            application: raw
        )
    }

    /// Wraps a button resolved from a typed identifier.
    public func button(_ id: any UITestIdentifiable) -> UITestButton {
        button(id.locator)
    }

    /// Wraps a button resolved from a generic locator.
    public func button(_ locator: UITestLocator) -> UITestButton {
        UITestButton(
            raw: resolveButton(locator),
            identifier: locator.description,
            timeouts: timeouts
        )
    }

    /// Wraps a generic element resolved from a typed identifier.
    public func element(_ id: any UITestIdentifiable) -> UITestElement {
        element(id.locator)
    }

    /// Wraps a generic element resolved from a generic locator.
    public func element(_ locator: UITestLocator) -> UITestElement {
        UITestElement(
            raw: resolveElement(locator),
            identifier: locator.description,
            timeouts: timeouts
        )
    }

    /// Captures and attaches a screenshot to the current XCTest activity.
    @discardableResult
    public func attachScreenshot(
        named name: String = "Screenshot",
        lifetime: XCTAttachment.Lifetime = .keepAlways
    ) -> XCTAttachment {
        let attachment = XCTAttachment(screenshot: raw.screenshot())
        attachment.name = name
        attachment.lifetime = lifetime
        XCTContext.runActivity(named: "Attach screenshot: \(name)") { activity in
            activity.add(attachment)
        }
        return attachment
    }

    private func resolveTextField(_ locator: UITestLocator) -> XCUIElement {
        resolve(locator, in: raw.textFields, supportsPlaceholder: true)
    }

    private func resolveSecureTextField(_ locator: UITestLocator) -> XCUIElement {
        resolve(locator, in: raw.secureTextFields, supportsPlaceholder: true)
    }

    private func resolveButton(_ locator: UITestLocator) -> XCUIElement {
        resolve(locator, in: raw.buttons, supportsPlaceholder: false)
    }

    private func resolveElement(_ locator: UITestLocator) -> XCUIElement {
        resolve(locator, in: raw.otherElements, supportsPlaceholder: false)
    }

    private func resolve(
        _ locator: UITestLocator,
        in query: XCUIElementQuery,
        supportsPlaceholder: Bool
    ) -> XCUIElement {
        switch locator {
        case let .id(value):
            return query[value]
        case let .label(value):
            return query.matching(NSPredicate(format: "label == %@", value)).firstMatch
        case let .value(value):
            return query.matching(NSPredicate(format: "value == %@", value)).firstMatch
        case let .placeholder(value):
            guard supportsPlaceholder else {
                return query.matching(NSPredicate(value: false)).firstMatch
            }
            return query.matching(NSPredicate(format: "placeholderValue == %@", value)).firstMatch
        }
    }
}
