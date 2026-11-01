import Foundation

/// Talks to Spotify with raw Apple Events, using the codes from Spotify's scripting dictionary
/// (`Spotify.app/Contents/Resources/Spotify.sdef`). Unlike `NSAppleScript`, this never loads the
/// AppleScript runtime (~60 MB resident).
///
/// Events go out on a private serial queue so a slow Spotify never blocks the UI. Callers only use
/// this while Spotify is running, so it can never launch Spotify.
enum SpotifyAppleEvents {
    enum Command {
        case playPause, next, previous
        case seek(TimeInterval)
    }

    private static let queue = DispatchQueue(label: "dyanotch.spotify.appleevents", qos: .userInitiated)
    private static let timeout: TimeInterval = 2

    static func send(_ command: Command) {
        queue.async {
            _ = try? event(for: command).sendEvent(options: [.noReply], timeout: timeout)
        }
    }

    /// One-time read of the current track, used when Spotify is already playing at activation
    /// (Spotify only posts notifications on changes).
    static func currentTrack() async -> SpotifyTrack? {
        await withCheckedContinuation { continuation in
            queue.async { continuation.resume(returning: readCurrentTrack()) }
        }
    }

    // MARK: - Events

    private static func event(for command: Command) -> NSAppleEventDescriptor {
        switch command {
        case .playPause: return spotifyCommand("PlPs")
        case .next: return spotifyCommand("Next")
        case .previous: return spotifyCommand("Prev")
        case .seek(let seconds):
            // `set player position to <seconds>` = core/setd on property pPos.
            let event = appleEvent(class: "core", id: "setd")
            event.setParam(property("pPos"), forKeyword: code("----"))
            event.setParam(NSAppleEventDescriptor(double: seconds), forKeyword: code("data"))
            return event
        }
    }

    private static func readCurrentTrack() -> SpotifyTrack? {
        // Compare raw enum codes. Do NOT use AppleScript's `player state as string`: Spotify's codes differ
        // only by case (playing kPSP, paused kPSp) and AppleScript reports a paused player as "playing".
        guard let state = get(property("pPlS"))?.enumCodeValue, state != code("kPSS") else { return nil } // stopped
        let track = property("pTrk")
        guard let id = get(property("ID  ", of: track))?.stringValue else { return nil }
        return SpotifyTrack(
            id: id,
            title: get(property("pnam", of: track))?.stringValue ?? "",
            artist: get(property("pArt", of: track))?.stringValue ?? "",
            duration: (get(property("pDur", of: track))?.doubleValue ?? 0) / 1000, // milliseconds
            isPlaying: state == code("kPSP"),
            position: get(property("pPos"))?.doubleValue ?? 0,
            positionAt: .now
        )
    }

    /// `get <property>`: core/getd, waiting for the reply.
    private static func get(_ specifier: NSAppleEventDescriptor) -> NSAppleEventDescriptor? {
        let event = appleEvent(class: "core", id: "getd")
        event.setParam(specifier, forKeyword: code("----"))
        let reply = try? event.sendEvent(options: [.waitForReply], timeout: timeout)
        return reply?.paramDescriptor(forKeyword: code("----"))
    }

    // MARK: - Descriptor building

    private static func spotifyCommand(_ id: String) -> NSAppleEventDescriptor {
        appleEvent(class: "spfy", id: id)
    }

    private static func appleEvent(class eventClass: String, id: String) -> NSAppleEventDescriptor {
        NSAppleEventDescriptor(
            eventClass: code(eventClass),
            eventID: code(id),
            targetDescriptor: NSAppleEventDescriptor(bundleIdentifier: SpotifyMonitor.bundleID),
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )
    }

    /// Object specifier for `<property> of <container>` (container nil = the application).
    private static func property(_ name: String, of container: NSAppleEventDescriptor? = nil) -> NSAppleEventDescriptor {
        let record = NSAppleEventDescriptor.record()
        record.setDescriptor(NSAppleEventDescriptor(typeCode: code("prop")), forKeyword: code("want"))
        record.setDescriptor(container ?? NSAppleEventDescriptor.null(), forKeyword: code("from"))
        record.setDescriptor(NSAppleEventDescriptor(enumCode: code("prop")), forKeyword: code("form"))
        record.setDescriptor(NSAppleEventDescriptor(typeCode: code(name)), forKeyword: code("seld"))
        return record.coerce(toDescriptorType: code("obj ")) ?? record
    }

    /// Four-character code, e.g. "core" → 0x636F7265.
    private static func code(_ text: String) -> FourCharCode {
        text.utf8.reduce(0) { $0 << 8 | FourCharCode($1) }
    }
}
