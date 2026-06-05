import SwiftUI
#if os(iOS)
import UIKit
#endif

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
                    #if os(iOS)
                    IdentifiedSearchField(
                        placeholder: "Search cards",
                        text: $searchCards,
                        identifier: "cardEditor.merchantSearch"
                    )

                    IdentifiedTextField(
                        placeholder: "Card aliases",
                        text: $aliases,
                        identifier: "cardEditor.aliases"
                    )
                    #else
                    TextField("Search cards", text: $searchCards)
                        .accessibilityIdentifier("cardEditor.merchantSearch")

                    TextField("Card aliases", text: $aliases)
                        .accessibilityIdentifier("cardEditor.aliases")
                    #endif

                    Button("Save") {
                        savedAliases = aliases
                    }
                    .accessibilityIdentifier("cardEditor.save")

                    Text("Saved: \(savedAliases)")
                        .accessibilityIdentifier("cardEditor.savedValue")
                }
                .padding(.horizontal)
                .background {
                    Color.black
                        .opacity(0.001)
                        .accessibilityElement(children: .ignore)
                        .accessibilityIdentifier("cardEditor.detailPanel")
                }

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

#if os(iOS)
private struct IdentifiedSearchField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    let identifier: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UISearchTextField {
        let textField = UISearchTextField(frame: .zero)
        textField.placeholder = placeholder
        textField.accessibilityIdentifier = identifier
        textField.accessibilityLabel = placeholder
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingChanged(_:)),
            for: .editingChanged
        )
        return textField
    }

    func updateUIView(_ uiView: UISearchTextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.placeholder = placeholder
        uiView.accessibilityIdentifier = identifier
        uiView.accessibilityLabel = placeholder
    }

    @MainActor
    final class Coordinator: NSObject {
        private var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        @objc
        func editingChanged(_ sender: UISearchTextField) {
            text.wrappedValue = sender.text ?? ""
        }
    }
}

private struct IdentifiedTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    let identifier: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.borderStyle = .roundedRect
        textField.placeholder = placeholder
        textField.accessibilityIdentifier = identifier
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingChanged(_:)),
            for: .editingChanged
        )
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.placeholder = placeholder
        uiView.accessibilityIdentifier = identifier
    }

    @MainActor
    final class Coordinator: NSObject {
        private var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        @objc
        func editingChanged(_ sender: UITextField) {
            text.wrappedValue = sender.text ?? ""
        }
    }
}
#endif
