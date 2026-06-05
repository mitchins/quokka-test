import XCTest
import QuokkaTestMac

private let demoMacAppBundleIdentifier = "com.mitchins.QuokkaTestDemoMacApp"

private enum MacCardEditorLocator: String, UITestIdentifiable {
    case aliases = "cardEditor.aliases"
    case save = "cardEditor.save"
}

private enum MacRootLocator: String, UITestIdentifiable {
    case addCard = "root.addCard"
}

final class QuokkaTestMacUsageSandboxUITests: XCTestCase {
    @MainActor
    private func makeApp() -> UITestApp {
        UITestApp(XCUIApplication(bundleIdentifier: demoMacAppBundleIdentifier))
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
        app.staticText(UITestLocator.id("cardEditor.savedValue"))
            .assertExists(timeout: app.timeouts.long)
            .assertValueEquals("Saved: Mac Alias")
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
