import Foundation
import XCTest

/// The root QuokkaTest wrapper around `XCUIApplication`.
@MainActor
public struct UITestApp {
    /// Controls whether lookup stays on the requested surface or broadens across common surfaces.
    public enum QueryResolution: Sendable {
        case surface
        case crossSurface
    }

    public let raw: XCUIApplication
    public let timeouts: UITestTimeouts
    public let diagnosticsConfiguration: UITestDiagnosticsConfiguration

    /// Creates a wrapper around an existing application instance.
    public init(
        _ raw: XCUIApplication,
        timeouts: UITestTimeouts = .init(),
        diagnostics: UITestDiagnosticsConfiguration = .init()
    ) {
        self.raw = raw
        self.timeouts = timeouts
        self.diagnosticsConfiguration = diagnostics
    }

    /// Creates a wrapper around a new `XCUIApplication`.
    public init(
        timeouts: UITestTimeouts = .init(),
        diagnostics: UITestDiagnosticsConfiguration = .init()
    ) {
        self.init(XCUIApplication(), timeouts: timeouts, diagnostics: diagnostics)
    }

    @discardableResult
    public func launch() -> Self {
        launch(arguments: [], environment: [:])
    }

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

    @discardableResult
    public func launch(_ options: UITestLaunchOption...) -> Self {
        var arguments: [String] = []
        var environment: [String: String] = [:]

        for option in options {
            switch option {
            case let .argument(argument):
                arguments.append(argument)
            case let .arguments(values):
                arguments.append(contentsOf: values)
            case let .environment(key, value):
                environment[key] = value
            case let .environmentValues(values):
                environment.merge(values) { _, newValue in newValue }
            }
        }

        return launch(arguments: arguments, environment: environment)
    }

    @discardableResult
    public func launch(using config: UITestLaunchConfiguration) -> Self {
        launch(arguments: config.arguments, environment: config.environment)
    }

    public func page(_ anchor: UITestPageAnchor) -> UITestPage {
        UITestPage(app: self, anchor: anchor)
    }

    public func field(_ locator: some UITestLocating) -> UITestField {
        let locatorChain = locator.uiTestLocatorChain
        return UITestField(
            raw: resolveTextField(locatorChain),
            locator: UITestLocatorContext(locatorChain),
            timeouts: timeouts,
            application: raw,
            diagnostics: diagnosticsConfiguration
        )
    }

    public func secureField(_ locator: some UITestLocating) -> UITestField {
        let locatorChain = locator.uiTestLocatorChain
        return UITestField(
            raw: resolveSecureTextField(locatorChain),
            locator: UITestLocatorContext(locatorChain),
            timeouts: timeouts,
            application: raw,
            diagnostics: diagnosticsConfiguration
        )
    }

    public func button(_ locator: some UITestLocating) -> UITestButton {
        let locatorChain = locator.uiTestLocatorChain
        return UITestButton(
            raw: resolveButton(locatorChain),
            locator: UITestLocatorContext(locatorChain),
            timeouts: timeouts,
            application: raw,
            diagnostics: diagnosticsConfiguration
        )
    }

    public func buttons(_ locator: some UITestLocating) -> UITestMatchQuery {
        let locatorChain = locator.uiTestLocatorChain
        return UITestMatchQuery(
            raw: matchQuery(locatorChain, in: raw.buttons, supportsPlaceholder: false),
            locator: UITestLocatorContext(locatorChain),
            surface: "buttons",
            timeouts: timeouts,
            application: raw,
            diagnosticsConfiguration: diagnosticsConfiguration
        )
    }

    public func element(
        _ locator: some UITestLocating,
        resolution: QueryResolution = .surface
    ) -> UITestElement {
        let locatorChain = locator.uiTestLocatorChain
        return UITestElement(
            raw: resolveElement(locatorChain, resolution: resolution),
            locator: UITestLocatorContext(locatorChain),
            timeouts: timeouts,
            application: raw,
            diagnostics: diagnosticsConfiguration
        )
    }

    public func staticText(_ locator: some UITestLocating) -> UITestElement {
        let locatorChain = locator.uiTestLocatorChain
        return UITestElement(
            raw: resolveStaticText(locatorChain),
            locator: UITestLocatorContext(locatorChain),
            timeouts: timeouts,
            application: raw,
            diagnostics: diagnosticsConfiguration
        )
    }

    public func staticTexts(_ locator: some UITestLocating) -> UITestMatchQuery {
        let locatorChain = locator.uiTestLocatorChain
        return UITestMatchQuery(
            raw: matchQuery(locatorChain, in: raw.staticTexts, supportsPlaceholder: false),
            locator: UITestLocatorContext(locatorChain),
            surface: "staticTexts",
            timeouts: timeouts,
            application: raw,
            diagnosticsConfiguration: diagnosticsConfiguration
        )
    }

    /// Navigation-bar lookups are strict to navigation bars only.
    public func navigationBar(_ locator: some UITestLocating) -> UITestElement {
        let locatorChain = locator.uiTestLocatorChain
        return UITestElement(
            raw: resolveNavigationBar(locatorChain),
            locator: UITestLocatorContext(locatorChain),
            timeouts: timeouts,
            application: raw,
            diagnostics: diagnosticsConfiguration
        )
    }

    /// Search fields resolve from `searchFields` first and then `textFields`.
    public func searchField(_ locator: some UITestLocating) -> UITestField {
        let locatorChain = locator.uiTestLocatorChain
        return UITestField(
            raw: resolveSearchField(locatorChain),
            locator: UITestLocatorContext(locatorChain),
            timeouts: timeouts,
            application: raw,
            diagnostics: diagnosticsConfiguration
        )
    }

    public func alert(_ locator: some UITestLocating) -> UITestElement {
        let locatorChain = locator.uiTestLocatorChain
        return UITestElement(
            raw: resolveAlert(locatorChain),
            locator: UITestLocatorContext(locatorChain),
            timeouts: timeouts,
            application: raw,
            diagnostics: diagnosticsConfiguration
        )
    }

    public func toggle(_ locator: some UITestLocating) -> UITestElement {
        let locatorChain = locator.uiTestLocatorChain
        return UITestElement(
            raw: resolveToggle(locatorChain),
            locator: UITestLocatorContext(locatorChain),
            timeouts: timeouts,
            application: raw,
            diagnostics: diagnosticsConfiguration
        )
    }

    public func scrollView(_ locator: some UITestLocating) -> UITestElement {
        let locatorChain = locator.uiTestLocatorChain
        return UITestElement(
            raw: resolveScrollView(locatorChain),
            locator: UITestLocatorContext(locatorChain),
            timeouts: timeouts,
            application: raw,
            diagnostics: diagnosticsConfiguration
        )
    }

    @discardableResult
    public func scrollUntilVisible(
        _ target: any UITestActionSurface,
        in scrollView: UITestElement,
        maxAttempts: Int = 10,
        timeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        scrollView.swipeUpUntilExists(
            target,
            maxAttempts: maxAttempts,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

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

    @discardableResult
    public func attachHierarchy(
        named name: String = "Hierarchy",
        lifetime: XCTAttachment.Lifetime = .keepAlways
    ) -> XCTAttachment {
        let attachment = XCTAttachment(string: raw.debugDescription)
        attachment.name = name
        attachment.lifetime = lifetime
        XCTContext.runActivity(named: "Attach hierarchy: \(name)") { activity in
            activity.add(attachment)
        }
        return attachment
    }

    internal func failWithDiagnostics(
        action: String,
        details: String,
        locator: String = "",
        timeout: TimeInterval,
        file: StaticString,
        line: UInt
    ) {
        UITestFailureReporter.report(
            action: action,
            details: details,
            locator: locator,
            application: raw,
            diagnostics: diagnosticsConfiguration,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    private func matchQuery(
        _ locatorChain: UITestLocatorChain,
        in query: XCUIElementQuery,
        supportsPlaceholder: Bool
    ) -> XCUIElementQuery {
        guard let predicate = locatorPredicates(
            for: locatorChain,
            supportsPlaceholder: supportsPlaceholder
        ) else {
            return query.matching(NSPredicate(value: false))
        }

        return query.matching(predicate)
    }

    #if os(macOS)
    public func menu(_ locator: some UITestLocating) -> UITestElement {
        let locatorChain = locator.uiTestLocatorChain
        return UITestElement(
            raw: resolveMenu(locatorChain),
            locator: UITestLocatorContext(locatorChain),
            timeouts: timeouts,
            application: raw,
            diagnostics: diagnosticsConfiguration
        )
    }

    public func menu(named locator: some UITestLocating) -> UITestMenu {
        UITestMenu(menu: menu(locator), app: self)
    }

    public func menuItem(_ locator: some UITestLocating) -> UITestElement {
        let locatorChain = locator.uiTestLocatorChain
        return UITestElement(
            raw: resolveMenuItem(locatorChain),
            locator: UITestLocatorContext(locatorChain),
            timeouts: timeouts,
            application: raw,
            diagnostics: diagnosticsConfiguration
        )
    }

    public func menuItems(in locator: some UITestLocating) -> [String] {
        let container = resolveMenu(locator.uiTestLocatorChain)
        return menuItemLabels(in: container)
    }

    @discardableResult
    public func assertMenuItemsContains(
        in locator: some UITestLocating,
        all expected: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let items = menuItems(in: locator)
        let missing = expected.filter { !items.contains($0) }

        if !missing.isEmpty {
            failWithDiagnostics(
                action: "assertMenuItemsContains",
                details: "Missing menu items: \(missing.joined(separator: ", "))",
                locator: locator.uiTestLocatorChain.description,
                timeout: timeouts.short,
                file: file,
                line: line
            )
        }

        return self
    }

    @discardableResult
    public func assertMenuItemsEqual(
        in locator: some UITestLocating,
        _ expected: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let actual = menuItems(in: locator)
        if actual != expected {
            failWithDiagnostics(
                action: "assertMenuItemsEqual",
                details: "Expected menu labels to equal \(expected), got \(actual)",
                locator: locator.uiTestLocatorChain.description,
                timeout: timeouts.short,
                file: file,
                line: line
            )
        }
        return self
    }
    #endif

    internal func resolvePageElement(for anchor: UITestPageAnchor) -> UITestElement {
        switch anchor {
        case let .locator(locator):
            return element(locator, resolution: .crossSurface)
        case let .locatorChain(locatorChain):
            return element(locatorChain, resolution: .crossSurface)
        case let .staticText(value):
            return staticText(UITestLocator.label(value))
        case let .heading(value):
            return staticText(UITestLocator.label(value))
        case let .navigationTitle(value):
            return UITestElement(
                raw: resolvePageNavigationTitle(value),
                locator: UITestLocatorContext(description: "page anchor navigation title: \(value)"),
                timeouts: timeouts,
                application: raw,
                diagnostics: diagnosticsConfiguration
            )
        }
    }

    internal func resolvePageIdentifier(for anchor: UITestPageAnchor) -> String {
        switch anchor {
        case let .locator(locator):
            return "page anchor locator: \(locator)"
        case let .locatorChain(locatorChain):
            return "page anchor chain: \(locatorChain)"
        case let .staticText(value):
            return "page anchor staticText: \(value)"
        case let .heading(value):
            return "page anchor heading: \(value)"
        case let .navigationTitle(value):
            return "page anchor navigation title: \(value)"
        }
    }

    internal func resolvePageIdentifier(for readiness: UITestPageReadiness) -> String {
        switch readiness {
        case .none:
            return "none"
        case let .locator(locator):
            return "page readiness locator: \(locator)"
        case let .locatorChain(locatorChain):
            return "page readiness chain: \(locatorChain)"
        case let .staticText(value):
            return "page readiness staticText: \(value)"
        case let .heading(value):
            return "page readiness heading: \(value)"
        case let .navigationTitle(value):
            return "page readiness navigation title: \(value)"
        case let .buttonTitle(value):
            return "page readiness button title: \(value)"
        case let .notExists(locator):
            return "page readiness not exists: \(locator)"
        case let .notExistsChain(locatorChain):
            return "page readiness chain not exists: \(locatorChain)"
        case let .valueEquals(locator, expected):
            return "page readiness value equals: \(locator) == \(expected)"
        }
    }

    internal func resolvePageElement(for readiness: UITestPageReadiness) -> UITestElement {
        switch readiness {
        case .none:
            return UITestElement(
                raw: missingElement(in: raw.otherElements),
                locator: UITestLocatorContext(description: "none"),
                timeouts: timeouts,
                application: raw,
                diagnostics: diagnosticsConfiguration
            )
        case let .locator(locator):
            return element(locator, resolution: .crossSurface)
        case let .locatorChain(locatorChain):
            return element(locatorChain, resolution: .crossSurface)
        case let .staticText(value):
            return staticText(UITestLocator.label(value))
        case let .heading(value):
            return staticText(UITestLocator.label(value))
        case let .navigationTitle(value):
            return UITestElement(
                raw: resolvePageNavigationTitle(value),
                locator: UITestLocatorContext(description: "page readiness navigation title: \(value)"),
                timeouts: timeouts,
                application: raw,
                diagnostics: diagnosticsConfiguration
            )
        case let .buttonTitle(value):
            return UITestElement(
                raw: resolve(UITestLocator.label(value), in: raw.buttons, supportsPlaceholder: false),
                locator: UITestLocatorContext(description: "button title: \(value)"),
                timeouts: timeouts,
                application: raw,
                diagnostics: diagnosticsConfiguration
            )
        case let .notExists(locator):
            return element(locator, resolution: .crossSurface)
        case let .notExistsChain(locatorChain):
            return element(locatorChain, resolution: .crossSurface)
        case let .valueEquals(locator, _):
            return element(locator, resolution: .crossSurface)
        }
    }

    private func resolvePageNavigationTitle(_ value: String) -> XCUIElement {
        let navigationBarMatch = resolveExact(
            .label(value),
            in: raw.navigationBars,
            supportsPlaceholder: false
        )
        if navigationBarMatch.exists {
            return navigationBarMatch
        }
        return resolveExact(
            .label(value),
            in: raw.staticTexts,
            supportsPlaceholder: false
        )
    }

    private func resolveTextField(_ locatorChain: UITestLocatorChain) -> XCUIElement {
        resolve(locatorChain, in: raw.textFields, supportsPlaceholder: true)
    }

    private func resolveSecureTextField(_ locatorChain: UITestLocatorChain) -> XCUIElement {
        resolve(locatorChain, in: raw.secureTextFields, supportsPlaceholder: true)
    }

    private func resolveButton(_ locatorChain: UITestLocatorChain) -> XCUIElement {
        resolve(locatorChain, in: raw.buttons, supportsPlaceholder: false)
    }

    private func resolveElement(
        _ locatorChain: UITestLocatorChain,
        resolution: QueryResolution
    ) -> XCUIElement {
        switch resolution {
        case .surface:
            return resolve(locatorChain, in: raw.otherElements, supportsPlaceholder: false)
        case .crossSurface:
            return resolveElementAcrossTypes(locatorChain)
        }
    }

    private func resolveElementAcrossTypes(_ locatorChain: UITestLocatorChain) -> XCUIElement {
        resolve(locatorChain, in: raw.descendants(matching: .any), supportsPlaceholder: true)
    }

    private func resolveStaticText(_ locatorChain: UITestLocatorChain) -> XCUIElement {
        resolve(locatorChain, in: raw.staticTexts, supportsPlaceholder: false)
    }

    private func resolveNavigationBar(_ locatorChain: UITestLocatorChain) -> XCUIElement {
        resolve(locatorChain, in: raw.navigationBars, supportsPlaceholder: false)
    }

    private func resolveSearchField(_ locatorChain: UITestLocatorChain) -> XCUIElement {
        guard let locatorPredicate = locatorPredicates(
            for: locatorChain,
            supportsPlaceholder: true
        ) else {
            return missingElement(in: raw.searchFields)
        }

        let searchFieldMatch = raw.searchFields.matching(locatorPredicate).firstMatch
        if searchFieldMatch.exists {
            return searchFieldMatch
        }

        return raw.textFields.matching(locatorPredicate).firstMatch
    }

    private func resolveAlert(_ locatorChain: UITestLocatorChain) -> XCUIElement {
        resolve(locatorChain, in: raw.alerts, supportsPlaceholder: false)
    }

    private func resolveToggle(_ locatorChain: UITestLocatorChain) -> XCUIElement {
        resolve(locatorChain, in: raw.switches, supportsPlaceholder: false)
    }

    private func resolveScrollView(_ locatorChain: UITestLocatorChain) -> XCUIElement {
        resolve(locatorChain, in: raw.scrollViews, supportsPlaceholder: false)
    }

    private func resolve(
        _ locatorChain: UITestLocatorChain,
        in query: XCUIElementQuery,
        supportsPlaceholder: Bool
    ) -> XCUIElement {
        precondition(!locatorChain.locators.isEmpty, "Locator chain cannot be empty.")
        guard let locatorPredicate = locatorPredicates(
            for: locatorChain,
            supportsPlaceholder: supportsPlaceholder
        ) else {
            return missingElement(in: query)
        }
        return query.matching(locatorPredicate).firstMatch
    }

    private func resolve(
        _ locator: UITestLocator,
        in query: XCUIElementQuery,
        supportsPlaceholder: Bool
    ) -> XCUIElement {
        resolveExact(locator, in: query, supportsPlaceholder: supportsPlaceholder)
    }

    private func resolveExact(
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
                return missingElement(in: query)
            }
            return query.matching(NSPredicate(format: "placeholderValue == %@", value)).firstMatch
        }
    }

    private func locatorPredicates(
        for locatorChain: UITestLocatorChain,
        supportsPlaceholder: Bool
    ) -> NSPredicate? {
        let predicates = locatorChain.locators.compactMap {
            locatorPredicate(for: $0, supportsPlaceholder: supportsPlaceholder)
        }

        guard !predicates.isEmpty else {
            return nil
        }

        guard predicates.count > 1 else {
            return predicates[0]
        }

        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }

    private func locatorPredicate(
        for locator: UITestLocator,
        supportsPlaceholder: Bool
    ) -> NSPredicate? {
        switch locator {
        case let .id(value):
            return NSPredicate(format: "identifier == %@", value)
        case let .label(value):
            return NSPredicate(format: "label == %@", value)
        case let .value(value):
            return NSPredicate(format: "value == %@", value)
        case let .placeholder(value):
            guard supportsPlaceholder else {
                return nil
            }
            return NSPredicate(format: "placeholderValue == %@", value)
        }
    }

    private func missingElement(in query: XCUIElementQuery) -> XCUIElement {
        // A deterministic, never-present element used for fallback paths where no
        // locator can be represented as a query predicate.
        query.matching(NSPredicate(value: false)).firstMatch
    }

    internal func menuItemLabels(in container: XCUIElement) -> [String] {
        container.children(matching: .menuItem).allElementsBoundByIndex.compactMap { element in
            let label = element.label
            return label.isEmpty ? nil : label
        }
    }

    #if os(macOS)
    private func resolveMenu(_ locatorChain: UITestLocatorChain) -> XCUIElement {
        resolve(locatorChain, in: raw.menuBars.menuBarItems, supportsPlaceholder: false)
    }

    private func resolveMenuItem(_ locatorChain: UITestLocatorChain) -> XCUIElement {
        resolve(locatorChain, in: raw.menuItems, supportsPlaceholder: false)
    }
    #endif
}
