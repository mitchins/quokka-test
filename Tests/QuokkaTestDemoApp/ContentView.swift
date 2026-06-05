import SwiftUI

struct ContentView: View {
    @State private var aliases = ""
    @State private var searchCards = ""
    @State private var savedAliases = ""
    @State private var showAlert = false
    @State private var showNegativeTarget = false

    var body: some View {
        Group {
            if #available(iOS 16.0, macOS 13.0, *) {
                NavigationStack {
                    content
                }
            } else {
                NavigationView {
                    content
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Cards")
                    .font(.title2)
                    .bold()
                    .accessibilityIdentifier("cards.pageTitle")

                Text("No cards yet")
                    .font(.headline)
                    .accessibilityIdentifier("cards.emptyStateTitle")

                Button("Add card") {
                    aliases = ""
                    searchCards = ""
                    savedAliases = ""
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("root.addCard")

                VStack(spacing: 12) {
                    TextField("Search cards", text: $searchCards)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("cardEditor.merchantSearch")

                    TextField("Card aliases", text: $aliases)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("cardEditor.aliases")

                    Button("Save") {
                        savedAliases = aliases
                    }
                    .accessibilityIdentifier("cardEditor.save")

                    Text("Saved: \(savedAliases)")
                        .accessibilityIdentifier("cardEditor.savedValue")
                }
                .padding(.horizontal)
                .accessibilityIdentifier("cardEditor.detailPanel")

                if showNegativeTarget {
                    Text("Fallback negative marker")
                        .accessibilityIdentifier("phase2.negativeTarget")
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(0..<60, id: \.self) { index in
                        Text("Card item #\(index)")
                            .padding(.horizontal)
                    }
                }

                Button("Debug POI Capture") {
                    showAlert = true
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("settings.debugPOICapture")
                .padding(.top, 8)
            }
            .padding()
        }
        .accessibilityIdentifier("settings.scroll")
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                showAlert = false
            }
        }
        .onAppear(perform: resetStateForUITests)
    }

    private func resetStateForUITests() {
        aliases = ""
        searchCards = ""
        savedAliases = ""
        showAlert = false
        showNegativeTarget = false
    }
}
