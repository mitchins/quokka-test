import XCTest
import QuokkaTest

private enum CardEditorLocator: String, UITestIdentifiable {
    case aliases = "cardEditor.aliases"
    case save = "cardEditor.save"
    case savedValue = "cardEditor.savedValue"
}

final class QuokkaTestUsageSandboxUITests: XCTestCase {
    @MainActor
    func testUsageSandbox_canEnterAliasAndSave() throws {
        let app = UITestApp()
        app.launch()

        app.field(CardEditorLocator.aliases)
            .clearAndEnter("Keyboard Alias")
        app.button(CardEditorLocator.save)
            .tapWhenReady()

        let savedLabel = app.raw.staticTexts[CardEditorLocator.savedValue.rawValue]
        XCTAssertTrue(savedLabel.waitForExistence(timeout: app.timeouts.normal))
        XCTAssertEqual(savedLabel.label, "Saved: Keyboard Alias")
    }

    @MainActor
    func testUsageSandbox_supportsLegacyFallbackLocators() throws {
        let app = UITestApp()
        app.launch()

        app.field(.placeholder("Card aliases"))
            .clearAndEnter("Legacy Alias")
        app.button(.label("Save"))
            .tapWhenReady()
        app.attachScreenshot(named: "legacy-locator-flow")

        let savedLabel = app.raw.staticTexts[CardEditorLocator.savedValue.rawValue]
        XCTAssertTrue(savedLabel.waitForExistence(timeout: app.timeouts.normal))
        XCTAssertEqual(savedLabel.label, "Saved: Legacy Alias")
    }
}
