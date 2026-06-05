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

## Phase 2 usage patterns

### 1) Happy path typed locator usage

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

### 2) Explicit fallback locator usage

Fallback should be explicit and used as a compatibility bridge only.

```swift
app.button(UITestLocatorChain(.id("missing.id"), .label("Save"), .value("Save")))
    .tapWhenReady()
```

### 3) App-owned launch preset

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

### 4) Page readiness

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

### 5) Robot pattern in app tests (not inside QuokkaTest)

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

### 6) Negative assertions

```swift
app.alert(UITestLocator.label("Error")).assertNotExists()
app.staticText(UITestLocator.label("Based on nearby match")).assertNotExists(timeout: app.timeouts.short)
```

### 7) Scroll helper

```swift
let debugButton = app.button(UITestLocator.id("settings.debugPOICapture"))
app.scrollView(UITestLocator.id("settings.scroll"))
    .swipeUpUntilExists(debugButton, maxAttempts: 12)
```

### 8) Menu helpers (macOS)

```swift
#if os(macOS)
app.menuItem(UITestLocatorChain(.id("invoiceEditor.exportPDF"), .label("Export PDF"))).tapWhenReady()
app.assertMenuItemsContains(in: UITestLocator.label("File"), all: ["Export PDF", "Print"])
app.assertMenuItemsEqual(in: UITestLocator.label("File"), ["About", "Print", "Quit"])
#endif
```

`menu` and `menuItem` APIs are available only on macOS where XCUITest menu traversal is supported.

### 9) Diagnostics on failures

```swift
let app = UITestApp(diagnostics: .init(
    attachScreenshotOnFailure: true,
    attachHierarchyOnFailure: true
))
```

Diagnostics are attached automatically when wrapped assertions/actions fail and include:

- action attempted
- identifier/locator used
- timeout used
- optional screenshot + hierarchy attachment

### 10) Minimum assertion set (recommended baseline)

For stable tests across suites, prefer this compact set as your default checks:

- `assertExists()` for required UI surfaces.
- `assertNotExists()` for optional/dismissed UI paths.
- `assertHittable()` (or `tapWhenReady()`) for interactive actions.
- `assertEnabled()` / `assertDisabled()` for control state.
- `assertValueEquals(_:)` for text fields.
- `assertLabelEquals(_:)` or `assertLabelContains(_:)` for semantic labels.
- `assertMatchCount(_:)` for collection-like checks.
- `assertChecked()` / `assertUnchecked()` for selectable or toggle-like controls.

## Proof sandbox + CI paths

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
