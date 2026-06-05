/// App launch options and launch environment preconfiguration.
public struct UITestLaunchConfiguration {
    public var arguments: [String]
    public var environment: [String: String]

    public init(
        arguments: [String] = [],
        environment: [String: String] = [:]
    ) {
        self.arguments = arguments
        self.environment = environment
    }
}

/// Ergonomic launch options for common UI test app bootstrapping.
public enum UITestLaunchOption: Sendable {
    case argument(String)
    case arguments([String])
    case environment(String, String)
    case environmentValues([String: String])
}
