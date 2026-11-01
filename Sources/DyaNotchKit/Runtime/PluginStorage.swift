import Foundation
import os

/// Namespaced JSON persistence for one plugin: `<root>/<plugin-id>/<name>.json`.
///
/// Reads are synchronous (files are tiny). Writes are encoded on the caller's thread, then
/// coalesced for 300 ms and written atomically on a background queue. Call `flush()` before quitting.
///
/// A file that exists but cannot be decoded (corrupt, or written by an incompatible version) is moved
/// aside to `<name>.corrupt-<timestamp>.json` instead of being silently overwritten by the next save.
public final class PluginStorage: @unchecked Sendable {
    public let directory: URL
    private let log = Logger(subsystem: "io.dyanotch.app", category: "storage")
    private let queue: DispatchQueue
    private var pending: [String: Data] = [:] // guarded by `queue`
    private var scheduled = false              // guarded by `queue`
    private let coalesce: TimeInterval

    public init(directory: URL, coalesce: TimeInterval = 0.3) {
        self.directory = directory
        self.coalesce = coalesce
        self.queue = DispatchQueue(label: "dyanotch.storage.\(directory.lastPathComponent)", qos: .utility)
    }

    public func load<T: Decodable>(_ type: T.Type, from name: String) -> T? {
        // A write that is still pending wins over the file on disk.
        if let pendingData = queue.sync(execute: { pending[name] }) {
            return try? Self.decoder.decode(T.self, from: pendingData)
        }
        guard let data = try? Data(contentsOf: url(name)) else { return nil }
        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            quarantine(name, because: error)
            return nil
        }
    }

    public func save<T: Encodable>(_ value: T, to name: String) {
        let data: Data
        do {
            data = try Self.encoder.encode(value)
        } catch {
            log.error("encode \(name, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            return
        }
        queue.async {
            self.pending[name] = data
            guard !self.scheduled else { return }
            self.scheduled = true
            self.queue.asyncAfter(deadline: .now() + self.coalesce) { self.writePending() }
        }
    }

    /// Writes everything pending, synchronously.
    public func flush() {
        queue.sync { writePending() }
    }

    private func writePending() {
        scheduled = false
        guard !pending.isEmpty else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            for (name, data) in pending {
                try data.write(to: url(name), options: .atomic)
            }
        } catch {
            log.error("write to \(self.directory.path, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
        }
        pending.removeAll()
    }

    /// Moves an undecodable file out of the way so the next save cannot destroy it.
    private func quarantine(_ name: String, because error: Error) {
        let stamp = Int(Date().timeIntervalSince1970)
        let backup = directory.appendingPathComponent("\(name).corrupt-\(stamp).json")
        try? FileManager.default.moveItem(at: url(name), to: backup)
        log.error("\(name, privacy: .public).json unreadable, moved to \(backup.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
    }

    private func url(_ name: String) -> URL { directory.appendingPathComponent("\(name).json") }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
