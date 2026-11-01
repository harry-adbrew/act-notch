/// Static description of a plugin. Read before the plugin is ever instantiated
/// (Settings lists every manifest, enabled or not).
public struct PluginManifest: Sendable, Identifiable {
    public let id: String
    public let name: String
    /// SF Symbol shown in the expanded header tabs and in Settings.
    public let symbol: String
    public let summary: String
    public let defaultEnabled: Bool

    public init(id: String, name: String, symbol: String, summary: String, defaultEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.summary = summary
        self.defaultEnabled = defaultEnabled
    }
}
