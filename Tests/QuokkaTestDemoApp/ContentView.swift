import SwiftUI

struct ContentView: View {
    @State private var aliases = ""
    @State private var savedAliases = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("QuokkaTest demo host")
                .font(.title3)
                .bold()

            Text("This app exists so XCUITest targets in this repo can run in CI.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()

            TextField("Card aliases", text: $aliases)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("cardEditor.aliases")
                .padding(.horizontal)

            Button("Save") {
                savedAliases = aliases
            }
            .accessibilityIdentifier("cardEditor.save")

            Text("Saved: \(savedAliases)")
                .accessibilityIdentifier("cardEditor.savedValue")
        }
        .padding()
    }
}
