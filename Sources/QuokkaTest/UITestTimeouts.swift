import Foundation

/// Shared timeout policy for QuokkaTest actions and assertions.
public struct UITestTimeouts: Sendable {
    public static let defaultTiny: TimeInterval = 1
    public static let defaultShort: TimeInterval = 3
    public static let defaultNormal: TimeInterval = 10
    public static let defaultLong: TimeInterval = 20

    public let tiny: TimeInterval
    public let short: TimeInterval
    public let normal: TimeInterval
    public let long: TimeInterval

    public init(
        tiny: TimeInterval = Self.defaultTiny,
        short: TimeInterval = Self.defaultShort,
        normal: TimeInterval = Self.defaultNormal,
        long: TimeInterval = Self.defaultLong
    ) {
        self.tiny = tiny
        self.short = short
        self.normal = normal
        self.long = long
    }
}
