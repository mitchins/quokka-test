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

    func testUiTestSandbox_isExplicitlySkippable() throws {
        throw XCTSkip(
            "UI integration test sandbox is intentionally skipped by default. " +
            "Enable on simulator UI runners and replace this body with full card editor flow assertions."
        )
    }

    func testGenericLocatorExamplesAreExplicit() {
        XCTAssertEqual(UITestLocator.label("Save").description, "label(Save)")
        XCTAssertEqual(UITestLocator.placeholder("Card aliases").description, "placeholder(Card aliases)")
    }
}
