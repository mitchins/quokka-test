import XCTest
import QuokkaTest

private let demoAppBundleIdentifier = "com.mitchins.QuokkaTestDemoApp"

private enum CardEditorLocator: String, UITestIdentifiable {
    case aliases = "cardEditor.aliases"
    case save = "cardEditor.save"
    case savedValue = "cardEditor.savedValue"
    case merchantSearch = "cardEditor.merchantSearch"
}

private enum RootLocator: String, UITestIdentifiable {
    case addCard = "root.addCard"
}

private enum SettingsLocator: String, UITestIdentifiable {
    case debugPOICapture = "settings.debugPOICapture"
    case scroll = "settings.scroll"
}

final class QuokkaTestUsageSandboxUITests: XCTestCase {
    @MainActor
    private func makeApp() -> UITestApp {
        UITestApp(XCUIApplication(bundleIdentifier: demoAppBundleIdentifier))
    }

    @MainActor
    func testUsageSandbox_canEnterAliasAndSave() throws {
        let app = makeApp()
        let config = UITestLaunchConfiguration(
            arguments: ["-AppleLanguages", "(en)"],
            environment: ["UITEST_MODE": "phase-2"]
        )
        let alias = "Keyboard Alias"

        app.launch(using: config)
        app.page(.navigationTitle("Cards")).waitUntilReady()
        app.staticText(UITestLocator.id("cards.pageTitle")).assertExists()
        app.button(RootLocator.addCard)
            .assertEnabled()
            .assertLabelEquals("Add card")

        app.button(RootLocator.addCard)
            .tapWhenReady()
        app.searchField(CardEditorLocator.merchantSearch)
            .assertExists()
            .clearAndEnter("Coles")
        app.field(CardEditorLocator.aliases)
            .clearAndEnter(alias)
        app.button(CardEditorLocator.save)
            .tapWhenReady()
            .assertEnabled()

        app.staticText(CardEditorLocator.savedValue)
            .assertExists()
            .assertLabelContains("Keyboard Alias")
            .assertMatchCount(1)

        let savedAliasLabel = "Saved: \(alias)"
        app.staticText(UITestLocator.label(savedAliasLabel)).assertMatchCount(1)
    }

    @MainActor
    func testUsageSandbox_supportsExplicitFallbackLocators() throws {
        let app = makeApp()
        app.launch()

        app.field(UITestLocator.placeholder("Card aliases"))
            .clearAndEnter("Legacy Alias")
        app.button(UITestLocatorChain(.id("does-not-exist"), .label("Save"), .value("Save")))
            .tapWhenReady()
        app.field(UITestLocatorChain(.id("does-not-exist"), .placeholder("Card aliases")))
            .clearAndEnter("Chain Alias")
        app.button(UITestLocator.label("Save"))
            .tapWhenReady()

        app.staticText(UITestLocator.label("Saved: Chain Alias"))
            .assertExists()

        app.button(UITestLocatorChain(.id("another-missing"), .label("Save"), .value("Save")))
            .tapWhenReady()
    }

    @MainActor
    func testUsageSandbox_supportsCommonSurfacesPageReadinessAndNegativeAssertions() throws {
        let app = makeApp()
        app.launch()
        app.page(.heading("No cards yet")).waitUntilReady()
        app.page(.navigationTitle("Cards"))
            .requiring(.notExists(.id("phase2.negativeTarget")))
            .waitUntilReady()
        app.page(.heading("No cards yet"))
            .requiring(.valueEquals(.id("cardEditor.aliases"), ""))
            .waitUntilReady()

        app.staticText(UITestLocator.id("cards.pageTitle"))
            .assertExists()
        app.page(.navigationTitle("Cards"))
            .waitUntilReady(timeout: app.timeouts.short)
        app.searchField(UITestLocator.id("cardEditor.merchantSearch"))
            .assertExists(timeout: app.timeouts.short)
        app.searchField(UITestLocator.placeholder("Search cards"))
            .assertExists(timeout: app.timeouts.short)
        app.staticText(UITestLocator.id("phase2.negativeTarget"))
            .assertNotExists()

        app.page(.heading("No cards yet"))
            .requiring(.buttonTitle("Save"))
            .waitUntilReady()
    }

    @MainActor
    func testUsageSandbox_scrollHelperCanFindOffscreenElement() throws {
        let app = makeApp()
        app.launch()

        let debugButton = app.button(SettingsLocator.debugPOICapture)
        app.scrollView(SettingsLocator.scroll)
            .swipeUpUntilExists(
                debugButton,
                maxAttempts: 12,
                timeout: app.timeouts.normal
            )

        debugButton.assertExists()
    }

    #if os(macOS)
    @MainActor
    func testUsageSandbox_menuHelpers() throws {
        let app = makeApp()
        app.launch()

        let _ = app.menuItems(in: UITestLocatorChain(.label("File"), .id("File")))
        let fileMenu = app.menu(named: UITestLocatorChain(.label("File"), .id("File")))
        _ = fileMenu.items()

        app.menuItem(UITestLocator.id("quokka-test-missing-menu-item"))
            .assertNotExists()
    }
    #endif
}
