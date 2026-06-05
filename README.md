# QuokkaTest

Small shared XCUITest mechanics for reusable suites across iOS and macOS UI tests.

## Goals

QuokkaTest stays app-agnostic and thin:

- typed locator enums in app code
- reusable wrappers in the framework
- minimal helpers for repeated mechanics, not app behavior

## Scope

- Typed identifiers (`UITestIdentifiable`)
- Generic/legacy locators (`UITestLocator`)
- App launch helpers (`UITestApp`, `UITestLaunchConfiguration`, `UITestLaunchOption`)
- Element mechanics (`UITestElement`, `UITestField`, `UITestButton`)
- Common assertions (`assertExists`, `assertHittable`, `assertNotExists`)
- Query surfaces for common surfaces (field, button, static text, search field, alert, navigation bar, switch/toggle, scroll view, menu APIs where supported)
- fallback locator chains
- page/readiness checks
- minimal scrolling and menu helper coverage
- basic diagnostics on failures
- extended assertion set (`assertEnabled`, `assertDisabled`, `assertValueEquals`,
  `assertLabelEquals`, `assertLabelContains`, `assertMatchCount(_)`, selected/checked state)

## Usage

### Typed locators

```swift
enum CardEditorLocator: String, UITestIdentifiable {
    case aliases = "cardEditor.aliases"
    case save = "cardEditor.save"
    case savedValue = "cardEditor.savedValue"
    case merchantSearch = "cardEditor.merchantSearch"
    case addCard = "root.addCard"
}

func testCanEnterAlias() {
    let app = UITestApp()
    app.launch()

    app.page(.navigationTitle("Cards")).waitUntilReady()

    app.button(CardEditorLocator.addCard)
        .tapWhenReady()
    app.searchField(CardEditorLocator.merchantSearch)
        .clearAndEnter("Coles")
    app.field(CardEditorLocator.aliases)
        .clearAndEnter("Keyboard Alias")
    app.button(CardEditorLocator.save)
        .tapWhenReady()
    app.staticText(CardEditorLocator.savedValue)
        .assertExists()
}
```

### Explicit fallbacks

Use fallbacks only when a surface is genuinely unstable across UI implementations or accessibility wiring.

```swift
app.button(UITestLocatorChain(.id("missing.id"), .label("Save"), .value("Save")))
    .tapWhenReady()
```

### Launch preset

```swift
let launch = UITestLaunchConfiguration(
    arguments: ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"],
    environment: ["JUSTCARDS_STORE_MODE": "ui-test"]
)
let app = UITestApp()
app.launch(using: launch)
```

or inline:

```swift
let app = UITestApp().launch(
    .argument("-AppleLanguages"),
    .argument("(en)"),
    .environment("JUSTCARDS_STORE_MODE", "ui-test")
)
```

### Page readiness

`searchField(...)` is intentionally compatible with SwiftUI/XCUI differences: it queries `searchFields` first and falls back to `textFields` when needed.

`navigationBar(...)` is strict to navigation bars only. For fuzzy screen-title or heading checks, use page anchors instead.

```swift
app.page(.navigationTitle("Accounts")).waitUntilReady()
app.page(.heading("Settings"))
    .requiring(.buttonTitle("Sign out"))
    .waitUntilReady()
app.page(.locator(.id("cards.root")))
    .requiring(.staticText("No cards yet"))
    .assertReady()
```

### Robot pattern

```swift
enum CardEditorLocator: String, UITestIdentifiable {
    case aliases = "cardEditor.aliases"
    case save = "cardEditor.save"
}

struct CardEditorRobot {
    let app: UITestApp

    @discardableResult
    func enterAlias(_ value: String) -> Self {
        app.field(CardEditorLocator.aliases).clearAndEnter(value)
        return self
    }

    @discardableResult
    func save() -> Self {
        app.button(CardEditorLocator.save).tapWhenReady()
        return self
    }
}
```

### Negative assertions

```swift
app.alert(UITestLocator.label("Error")).assertNotExists()
app.staticText(UITestLocator.label("Based on nearby match")).assertNotExists(timeout: app.timeouts.short)
```

### Synchronization helpers

```swift
app.element(.id("loading-spinner"))
    .waitUntilExists(timeout: 5)

app.button(.id("saved-connection-connect"))
    .waitUntilNotExists(timeout: 2)

XCTAssertTrue(
    UITestSync.untilAllNotExist(
        [
            app.button(.id("saved-connection-connect")),
            app.button(.id("saved-connection-update")),
        ],
        timeout: 2
    )
)
```

### Surface-scoped counts

```swift
app.buttons(
    UITestLocatorChain(
        .id("shell-sidebar-toggle"),
        .label("Sidebar")
    )
).assertCount(1)
```

### Container-relative visibility

```swift
app.element(.id("saved-connection-inline-error"))
    .assertVisible(in: app.element(.id("saved-connection-detail-panel")))
```

### Scroll helper

```swift
let debugButton = app.button(UITestLocator.id("settings.debugPOICapture"))
app.scrollView(UITestLocator.id("settings.scroll"))
    .swipeUpUntilExists(debugButton, maxAttempts: 12)
```

### Menu helpers (macOS)

```swift
#if os(macOS)
app.menuItem(UITestLocatorChain(.id("invoiceEditor.exportPDF"), .label("Export PDF"))).tapWhenReady()
app.assertMenuItemsContains(in: UITestLocator.label("File"), all: ["Export PDF", "Print"])
app.assertMenuItemsEqual(in: UITestLocator.label("File"), ["About", "Print", "Quit"])
#endif
```

`menu` and `menuItem` APIs are available only on macOS where XCUITest menu traversal is supported.

### Diagnostics

```swift
let app = UITestApp(diagnostics: .init(
    attachScreenshotOnFailure: true,
    attachHierarchyOnFailure: true
))
```

On failure, diagnostics can attach the action, locator, timeout, screenshot, and hierarchy.

### Default assertion set

- `assertExists()` for required UI surfaces.
- `assertNotExists()` for optional/dismissed UI paths.
- `assertHittable()` (or `tapWhenReady()`) for interactive actions.
- `assertEnabled()` / `assertDisabled()` for control state.
- `assertValueEquals(_:)` for text fields.
- `assertLabelEquals(_:)` or `assertLabelContains(_:)` for semantic labels.
- `assertMatchCount(_:)` for collection-like checks.
- `assertChecked()` / `assertUnchecked()` for selectable or toggle-like controls.

## Validation

### 1) Package smoke checks

```bash
swift test -Xswiftc -warnings-as-errors
```

### 2) XcodeGen + Xcode validation

```bash
xcodegen generate
rm -rf ./.build/QuokkaTest.xcresult

xcodebuild \
  -project QuokkaTest.xcodeproj \
  -scheme QuokkaDemoTest \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  -derivedDataPath ./.build/xcodebuild \
  -resultBundlePath ./.build/QuokkaTest.xcresult \
  test \
  -enableCodeCoverage YES \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
  OTHER_SWIFT_FLAGS='-warnings-as-errors'
```

Coverage conversion:

```bash
xcrun xccov view --report --json ./.build/QuokkaTest.xcresult > ./.build/coverage.json
```
