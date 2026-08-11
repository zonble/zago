import Foundation

/// The persistent variable environment of a LOGO program.
///
/// Values are stored as `LogoValue`, while the string subscript preserves the
/// established source-facing API used by the editor workspace and scripts.
public struct LogoEnvironment: Sequence {
    private var storage: [String: LogoValue]

    public init(initialValues: [String: String] = [:]) {
        self.storage = Dictionary(uniqueKeysWithValues: initialValues.map { key, value in
            (key, LogoValue.parse(value))
        })
    }

    public subscript(name: String) -> String? {
        get { storage[name]?.description }
        set {
            storage[name] = newValue.map(LogoValue.parse)
        }
    }

    public func value(for name: String) -> LogoValue? {
        storage[name]
    }

    public var keys: [String] { Array(storage.keys) }
    public var isEmpty: Bool { storage.isEmpty }

    public mutating func removeValue(forKey key: String) {
        storage.removeValue(forKey: key)
    }

    public mutating func removeAll() {
        storage.removeAll()
    }

    public func makeIterator() -> Dictionary<String, String>.Iterator {
        Dictionary(uniqueKeysWithValues: storage.map { key, value in (key, value.description) }).makeIterator()
    }
}
