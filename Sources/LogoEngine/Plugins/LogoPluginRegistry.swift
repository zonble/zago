import Foundation

/// Manages a chain of `LogoParserPlugin` instances for localized and domain-specific token parsing.
public final class LogoPluginRegistry: @unchecked Sendable {
    private var plugins: [any LogoParserPlugin] = []
    private let lock = NSLock()

    public init(plugins: [any LogoParserPlugin] = []) {
        self.plugins = plugins
    }

    /// Registers a plugin into the registry.
    public func register(_ plugin: any LogoParserPlugin) {
        lock.lock()
        defer { lock.unlock() }
        plugins.removeAll { $0.id.lowercased() == plugin.id.lowercased() }
        plugins.append(plugin)
    }

    /// Unregisters a plugin by its ID or alias.
    public func unregister(id: String) {
        lock.lock()
        defer { lock.unlock() }
        let cleanId = id.lowercased()
        plugins.removeAll {
            $0.id.lowercased() == cleanId || $0.aliases.contains { $0.lowercased() == cleanId }
        }
    }

    /// Removes all registered plugins.
    public func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        plugins.removeAll()
    }

    /// Returns all registered plugins.
    public var allPlugins: [any LogoParserPlugin] {
        lock.lock()
        defer { lock.unlock() }
        return plugins
    }

    /// Checks if a plugin with the given ID or alias is registered.
    public func contains(id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let cleanId = id.lowercased()
        return plugins.contains {
            $0.id.lowercased() == cleanId || $0.aliases.contains { $0.lowercased() == cleanId }
        }
    }

    // MARK: - Dispatch Hooks

    public func parsePrimitive(_ token: String) -> LogoPrimitive? {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        for plugin in currentPlugins {
            if let prim = plugin.parsePrimitive(token) {
                return prim
            }
        }
        return nil
    }

    public func parseOperator(_ token: String) -> LogoOperator? {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        for plugin in currentPlugins {
            if let op = plugin.parseOperator(token) {
                return op
            }
        }
        return nil
    }

    public func parseHeading(_ token: String) -> LogoHeading? {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        for plugin in currentPlugins {
            if let heading = plugin.parseHeading(token) {
                return heading
            }
        }
        return nil
    }

    public func parseBoolean(_ token: String) -> Bool? {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        for plugin in currentPlugins {
            if let b = plugin.parseBoolean(token) {
                return b
            }
        }
        return nil
    }

    public func parseExitPosition(_ token: String) -> BoxExitPosition? {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        for plugin in currentPlugins {
            if let pos = plugin.parseExitPosition(token) {
                return pos
            }
        }
        return nil
    }

    public func parseNumberStyle(_ token: String) -> LogoNumberStyle? {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        for plugin in currentPlugins {
            if let style = plugin.parseNumberStyle(token) {
                return style
            }
        }
        return nil
    }

    public func parseListType(_ token: String) -> LogoListType? {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        for plugin in currentPlugins {
            if let type = plugin.parseListType(token) {
                return type
            }
        }
        return nil
    }

    public func parseByteCountStyle(_ token: String) -> LogoByteCountStyle? {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        for plugin in currentPlugins {
            if let style = plugin.parseByteCountStyle(token) {
                return style
            }
        }
        return nil
    }

    public func parsePersonNameStyle(_ token: String) -> LogoPersonNameStyle? {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        for plugin in currentPlugins {
            if let style = plugin.parsePersonNameStyle(token) {
                return style
            }
        }
        return nil
    }

    public func resolveKeyword(_ token: String, domain: LogoKeywordDomain) -> String? {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        for plugin in currentPlugins {
            if let resolved = plugin.resolveKeyword(token, domain: domain) {
                return resolved
            }
        }
        return nil
    }

    public var allKeywordAliases: [String] {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        return currentPlugins.flatMap(\.keywordAliases)
    }
}
