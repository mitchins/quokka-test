import XCTest
@testable import QuokkaTest

private enum CardEditorLocator: String, UITestIdentifiable {
    case aliases = "cardEditor.aliases"
    case save = "cardEditor.save"
}

private enum InvoiceLocator: String, UITestIdentifiable {
    case customerName = "invoice.customerName"
}

final class QuokkaTestUsageSandboxTests: XCTestCase {
    func testTimeoutPolicyDefaults() {
        let defaults = UITestTimeouts()
        XCTAssertEqual(defaults.tiny, 1)
        XCTAssertEqual(defaults.short, 3)
        XCTAssertEqual(defaults.normal, 10)
        XCTAssertEqual(defaults.long, 20)
    }

    func testTimeoutPolicyCanBeOverridden() {
        let custom = UITestTimeouts(normal: 5)
        XCTAssertEqual(custom.normal, 5)
    }

    func testTypedLocatorUsageIsCentralized() throws {
        XCTAssertEqual(CardEditorLocator.aliases.rawValue, "cardEditor.aliases")
        XCTAssertEqual(CardEditorLocator.save.rawValue, "cardEditor.save")
        XCTAssertEqual(InvoiceLocator.customerName.rawValue, "invoice.customerName")
        XCTAssertEqual(CardEditorLocator.aliases.locator, .id("cardEditor.aliases"))
    }

    func testUsageExampleForFirstImplementationTarget() throws {
        let locator: CardEditorLocator = .aliases
        let expectedUsage = "app.field(CardEditorLocator.aliases).clearAndEnter(\"Keyboard Alias\")"
        XCTAssertEqual(locator.rawValue, "cardEditor.aliases")
        XCTAssertFalse(expectedUsage.isEmpty)
    }

    func testGenericLocatorExamplesAreExplicit() {
        XCTAssertEqual(UITestLocator.label("Save").description, "label(Save)")
        XCTAssertEqual(UITestLocator.placeholder("Card aliases").description, "placeholder(Card aliases)")
    }

    func testLaunchConfigurationHasExpectedShape() {
        let config = UITestLaunchConfiguration(
            arguments: ["-AppleLanguages", "(en)"],
            environment: ["UITEST_MODE": "unit"]
        )
        XCTAssertEqual(config.arguments, ["-AppleLanguages", "(en)"])
        XCTAssertEqual(config.environment["UITEST_MODE"], "unit")
    }

    func testLaunchOptionSetSupportsChainingInputs() {
        let options: [UITestLaunchOption] = [
            .argument("-AppleLanguages"),
            .argument("(en)"),
            .environment("UITEST_MODE", "unit")
        ]
        XCTAssertEqual(options.count, 3)
    }

    func testLocatorChainCapturesOrderedFallbackSequence() {
        let chain = UITestLocatorChain(
            .id("cardEditor.save"),
            .label("Save"),
            .value("Save")
        )

        XCTAssertEqual(
            chain.description,
            "first match: id(cardEditor.save) -> label(Save) -> value(Save)"
        )
    }

    func testPageReadinessIdentifiersAreDescribed() {
        let anchorDescription = UITestPageAnchor.navigationTitle("Cards")
        if case let .navigationTitle(value) = anchorDescription {
            XCTAssertEqual(value, "Cards")
        } else {
            XCTFail("Anchor should preserve navigation title")
        }

        let readinessDescription = UITestPageReadiness.buttonTitle("Save")
        if case let .buttonTitle(value) = readinessDescription {
            XCTAssertEqual(value, "Save")
        } else {
            XCTFail("Readiness should preserve button title")
        }

        let notExists = UITestPageReadiness.notExists(.id("missing"))
        if case let .notExists(missingLocator) = notExists {
            XCTAssertEqual(missingLocator, .id("missing"))
        } else {
            XCTFail("Readiness should support .notExists")
        }

        let valueEquals = UITestPageReadiness.valueEquals(.id("value-field"), "value")
        if case let .valueEquals(locator, expected) = valueEquals {
            XCTAssertEqual(locator, .id("value-field"))
            XCTAssertEqual(expected, "value")
        } else {
            XCTFail("Readiness should support .valueEquals(locator, value)")
        }
    }

    func testElementResolutionOptionsExist() {
        XCTAssertEqual(UITestApp.QueryResolution.surface, .surface)
        XCTAssertEqual(UITestApp.QueryResolution.crossSurface, .crossSurface)
    }

    func testDiagnosticsConfigurationDefaultsOffByDefault() {
        let config = UITestDiagnosticsConfiguration()
        XCTAssertFalse(config.attachScreenshotOnFailure)
        XCTAssertFalse(config.attachHierarchyOnFailure)
    }

    @MainActor
    func testSyncUtilitySupportsBasicWaitingContracts() {
        XCTAssertTrue(UITestSync.until(timeout: 0) { true })
        XCTAssertTrue(UITestSync.untilAllExist([], timeout: 0))
        XCTAssertTrue(UITestSync.untilAllNotExist([], timeout: 0))
    }

    @MainActor
    func testSurfaceScopedMatchQuerySupportsCountAssertions() {
        XCTAssertEqual(String(describing: UITestMatchQuery.self), "UITestMatchQuery")

        let fluentCountAssertion:
            (UITestMatchQuery) -> (Int, TimeInterval?, StaticString, UInt) -> UITestMatchQuery =
                UITestMatchQuery.assertCount(_:timeout:file:line:)

        _ = fluentCountAssertion
    }

}
