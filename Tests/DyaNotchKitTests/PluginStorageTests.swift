import DyaNotchKit
import Foundation
import Testing

@Suite struct PluginStorageTests {
    struct Item: Codable, Equatable {
        let name: String
        let at: Date
    }

    @Test func roundTripsAndPendingWritesAreVisible() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }

        // ISO-8601 JSON keeps whole seconds, which is all due dates and timer ends need.
        let items = [Item(name: "a", at: Date(timeIntervalSince1970: 1_000_000)), Item(name: "b", at: Date(timeIntervalSince1970: 2_000_000))]
        let storage = PluginStorage(directory: directory, coalesce: 10)
        storage.save(items, to: "items")

        // Not flushed yet, but a read must already see the pending value.
        #expect(storage.load([Item].self, from: "items") == items)

        storage.flush()
        #expect(PluginStorage(directory: directory).load([Item].self, from: "items") == items)
    }

    @Test func unreadableFileIsMovedAsideNotOverwritten() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let original = Data(#"[{"name":"a","legacyField":1}]"#.utf8) // missing "at": an incompatible version
        try original.write(to: directory.appendingPathComponent("items.json"))

        let storage = PluginStorage(directory: directory)
        #expect(storage.load([Item].self, from: "items") == nil)

        // The plugin now starts empty and saves; the old data must survive in the backup.
        storage.save([Item](), to: "items")
        storage.flush()
        let backups = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasPrefix("items.corrupt-") }
        #expect(backups.count == 1)
        let backup = try Data(contentsOf: directory.appendingPathComponent(try #require(backups.first)))
        #expect(backup == original)
    }

    @Test func missingFileLoadsNil() {
        let storage = PluginStorage(directory: URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString)"))
        #expect(storage.load([Item].self, from: "items") == nil)
    }
}
