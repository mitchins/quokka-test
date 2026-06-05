import Foundation

/// Failure diagnostics options for assertion and action failures.
public struct UITestDiagnosticsConfiguration: Sendable {
    public var attachScreenshotOnFailure: Bool
    public var attachHierarchyOnFailure: Bool

    public init(
        attachScreenshotOnFailure: Bool = false,
        attachHierarchyOnFailure: Bool = false
    ) {
        self.attachScreenshotOnFailure = attachScreenshotOnFailure
        self.attachHierarchyOnFailure = attachHierarchyOnFailure
    }
}
