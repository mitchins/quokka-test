import XCTest
import QuokkaTestMac

private enum MacCardEditorLocator: String, UITestIdentifiable {
    case aliases = "cardEditor.aliases"
    case save = "cardEditor.save"
    case savedValue = "cardEditor.savedValue"
    case detailPanel = "cardEditor.detailPanel"
}

private enum MacRootLocator: String, UITestIdentifiable {
    case addCard = "root.addCard"
}

final class QuokkaTestMacUsageSandboxUITests: XCTestCase {
    @MainActor
    private func makeApp() -> UITestApp {
        UITestApp(XCUIApplication())
    }

    @MainActor
    func testMacUsageSandbox_canEnterAliasAndSave() throws {
        let app = makeApp()
        let config = UITestLaunchConfiguration(
            arguments: ["-AppleLanguages", "(en)"],
            environment: ["UITEST_MODE": "phase-2"]
        )

        app.launch(using: config)
        app.searchField(UITestLocator.id("cardEditor.merchantSearch"))
            .clearAndEnter("Mac Search")
        app.button(MacRootLocator.addCard).tapWhenReady()
        app.field(MacCardEditorLocator.aliases).clearAndEnter("Mac Alias")
        app.button(MacCardEditorLocator.save).tapWhenReady()
        app.staticText(MacCardEditorLocator.savedValue)
            .assertExists(timeout: app.timeouts.long)
            .assertValueEquals("Saved: Mac Alias")
            .assertVisible(in: app.element(MacCardEditorLocator.detailPanel))
    }

    @MainActor
    func testMacUsageSandbox_supportsMenusAndReadiness() throws {
        let app = makeApp()
        let config = UITestLaunchConfiguration(
            arguments: ["-AppleLanguages", "(en)"],
            environment: ["UITEST_MODE": "phase-2"]
        )

        app.launch(using: config)
        app.searchField(UITestLocator.id("cardEditor.merchantSearch"))
            .assertExists(timeout: app.timeouts.long)
        app.staticText(UITestLocator.id("cards.emptyStateTitle"))
            .assertExists(timeout: app.timeouts.long)
        app.menuItem(UITestLocator.id("quokka-test-missing-menu-item")).assertNotExists()
    }
}
