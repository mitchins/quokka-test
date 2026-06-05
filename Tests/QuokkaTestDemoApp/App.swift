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
                Button("Print") {}
            }
        }
        #endif
    }
}
