# QuokkaTest

Small shared XCUITest core for reusable mechanics across iOS UI test suites.

## Phase 1 scope

- Typed identifiers (`UITestIdentifiable`)
- Generic locators for legacy fallback (`UITestLocator`)
- Shared launch + timeout policy (`UITestApp`, `UITestTimeouts`)
- Element mechanics helpers (`UITestElement`, `UITestField`, `UITestButton`)
- Field/text entry ergonomics (`tapWhenReady`, `clearAndEnter`)
- Screenshot attachments (`UITestApp.attachScreenshot(named:)`)

## Example

```swift
import QuokkaTest
import XCTest

enum CardEditorLocator: String, UITestIdentifiable {
    case aliases = "cardEditor.aliases"
}

func testCanEnterAlias() {
    let app = UITestApp()
    app.launch()
    app.field(CardEditorLocator.aliases)
        .clearAndEnter("Keyboard Alias")
}
```

For legacy screens that still rely on labels or placeholders:

```swift
app.field(.placeholder("Card aliases"))
    .clearAndEnter("Keyboard Alias")

app.button(.label("Save"))
    .tapWhenReady()
```

Readiness semantics are intentionally uniform across wrappers:

- `assertExists(...)` waits for existence.
- `assertHittable(...)` waits for existence, then asserts hittability.
- `tapWhenReady(...)` waits for existence, asserts hittability, then taps.

## Robot example

Keep Robots in the app test target, not in QuokkaTest itself:

```swift
import QuokkaTest

enum CardEditorLocator: String, UITestIdentifiable {
    case aliases = "cardEditor.aliases"
    case save = "cardEditor.save"
}

struct CardEditorRobot {
    let app: UITestApp

    @discardableResult
    func enterAlias(_ value: String) -> Self {
        app.field(CardEditorLocator.aliases)
            .clearAndEnter(value)
        return self
    }

    @discardableResult
    func save() -> Self {
        app.button(CardEditorLocator.save)
            .tapWhenReady()
        return self
    }
}
```

## Proof sandbox + CI paths

### 1) Library/API coverage (SwiftPM smoke checks)
Use this for package build + unit checks:

```bash
swift test -Xswiftc -warnings-as-errors
```

This validates package compilation and the shared-code examples.

### 2) XCUITest coverage path (XcodeGen + Xcode)

SwiftPM test runners are not a reliable path for end-to-end `XCUITest`.
Use XcodeGen + Xcode for the true UI coverage signal.

Generate the Xcode project:

```bash
xcodegen generate
```

Run tests with strict compiler policy (`-warnings-as-errors`) and coverage:

```bash
xcodebuild \
  -project QuokkaTest.xcodeproj \
  -scheme QuokkaDemoTest \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -derivedDataPath ./.build/xcodebuild \
  -resultBundlePath ./.build/QuokkaTest.xcresult \
  test \
  -enableCodeCoverage YES \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
  OTHER_SWIFT_FLAGS='-warnings-as-errors'
```

`SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` is the strict Swift equivalent to `-Werror` in this workflow.

For local Xcode runs, choose the `QuokkaDemoTest` scheme and run `Product > Test` or `⌘U`.

CI coverage artifacts to pass to Sonar:

```bash
xcrun xccov view --report --json ./.build/QuokkaTest.xcresult > ./.build/coverage.json
```

If `xccov` fails to emit coverage in your environment, use this fallback:

```bash
xcrun xcresulttool get --legacy object --path ./.build/QuokkaTest.xcresult --format json > ./.build/coverage.json
```

The repository keeps:

- [project.yml](project.yml)
- [Tests/QuokkaTestDemoApp](Tests/QuokkaTestDemoApp)
- [Tests/QuokkaTestUITests/QuokkaTestUsageSandboxUITests.swift](Tests/QuokkaTestUITests/QuokkaTestUsageSandboxUITests.swift)

CI should consume coverage artifacts from Xcode test output (`.xcresult`) and convert to Sonar-compatible format in your Sonar pipeline.
