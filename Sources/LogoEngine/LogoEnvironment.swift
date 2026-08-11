import Foundation

/// The persistent variable environment of a LOGO program.
///
/// Values are stored as `LogoValue`, while the string subscript preserves the
/// established source-facing API used by the editor workspace and scripts.
public struct LogoEnvironment: Sequence {
    private var frames: [[String: LogoValue]]

    public init(initialValues: [String: String] = [:]) {
        self.frames = [Dictionary(uniqueKeysWithValues: initialValues.map { key, value in
            (key, LogoValue.parse(value))
        })]
    }

    public subscript(name: String) -> String? {
        get { value(for: name)?.description }
        set {
            setValue(newValue.map(LogoValue.parse), for: name)
        }
    }

    public func value(for name: String) -> LogoValue? {
        for frame in frames.reversed() {
            if let value = frame[name] { return value }
        }
        return nil
    }

    public var keys: [String] { Array(frames.reduce(into: Set<String>()) { $0.formUnion($1.keys) }) }
    public var isEmpty: Bool { frames.allSatisfy(\.isEmpty) }
    public var scopeDepth: Int { frames.count }

    public mutating func pushScope(initialValues: [String: String] = [:]) {
        frames.append(Dictionary(uniqueKeysWithValues: initialValues.map { ($0.key, LogoValue.parse($0.value)) }))
    }

    public mutating func popScope() {
        guard frames.count > 1 else { return }
        frames.removeLast()
    }

    public mutating func declareLocal(_ name: String, initialValue: String = "") {
        frames[frames.count - 1][name] = LogoValue.parse(initialValue)
    }

    public mutating func removeValue(forKey key: String) {
        for index in frames.indices.reversed() where frames[index][key] != nil {
            frames[index].removeValue(forKey: key)
            return
        }
    }

    public mutating func removeAll() {
        frames = [[:]]
    }

    public func makeIterator() -> Dictionary<String, String>.Iterator {
        Dictionary(uniqueKeysWithValues: keys.compactMap { key in value(for: key).map { (key, $0.description) } }).makeIterator()
    }

    private mutating func setValue(_ value: LogoValue?, for name: String) {
        for index in frames.indices.reversed() where frames[index][name] != nil {
            frames[index][name] = value
            return
        }
        frames[frames.count - 1][name] = value
    }
}
