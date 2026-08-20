import Drawing
import Foundation

/// Central registry managing active `LogoParserPlugin` instances.
public final class LogoPluginRegistry: @unchecked Sendable {
    private var plugins: [any LogoParserPlugin] = []
    private let lock = NSLock()

    public init(plugins: [any LogoParserPlugin] = []) {
        self.plugins = plugins
    }

    public func contains(id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return plugins.contains { $0.id == id || $0.aliases.contains(id) }
    }

    public func register(_ plugin: any LogoParserPlugin) {
        lock.lock()
        defer { lock.unlock() }
        plugins.removeAll { $0.id == plugin.id }
        plugins.append(plugin)
    }

    public func unregister(id: String) {
        lock.lock()
        defer { lock.unlock() }
        plugins.removeAll { $0.id == id }
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        plugins.removeAll()
    }

    public var registeredPlugins: [any LogoParserPlugin] {
        lock.lock()
        defer { lock.unlock() }
        return plugins
    }

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
            if let val = plugin.parseBoolean(token) {
                return val
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

    public func parseBorderStyle(_ token: String) -> BorderStyle? {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        for plugin in currentPlugins {
            if let style = plugin.parseBorderStyle(token) {
                return style
            }
        }
        return nil
    }

    public func parseCalendarIdentifier(_ token: String) -> Calendar.Identifier? {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        for plugin in currentPlugins {
            if let cal = plugin.parseCalendarIdentifier(token) {
                return cal
            }
        }
        return nil
    }

    public func parseDateTimeStylePreset(_ token: String) -> LogoDateTimeStylePreset? {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        for plugin in currentPlugins {
            if let preset = plugin.parseDateTimeStylePreset(token) {
                return preset
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

    public func isFillerToken(_ token: String) -> Bool {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        for plugin in currentPlugins {
            if plugin.isFillerToken(token) {
                return true
            }
        }
        return false
    }

    public var allFillerTokens: Set<String> {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        return currentPlugins.reduce(into: Set<String>()) { $0.formUnion($1.fillerTokens) }
    }

    public var allKeywordAliases: [String] {
        lock.lock()
        let currentPlugins = plugins
        lock.unlock()
        return currentPlugins.flatMap(\.keywordAliases)
    }
}
