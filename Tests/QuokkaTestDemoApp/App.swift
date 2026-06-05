import SwiftUI

@main
struct QuokkaTestDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .commands {
            CommandMenu("QuokkaTest") {
                Button("Export PDF") {}
                    .accessibilityIdentifier("quokka-test-export-pdf")
                Button("Print") {}
                    .accessibilityIdentifier("quokka-test-print")
            }
        }
        #endif
    }
}
