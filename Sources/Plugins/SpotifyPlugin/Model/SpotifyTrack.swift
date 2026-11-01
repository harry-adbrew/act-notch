import Foundation

/// Snapshot of Spotify's state. Elapsed time is extrapolated from `position` and `positionAt`,
/// so nothing has to tick while a song plays.
public struct SpotifyTrack: Equatable, Sendable {
    /// "spotify:track:…"
    public var id: String
    public var title: String
    public var artist: String
    public var duration: TimeInterval
    public var isPlaying: Bool
    public var position: TimeInterval
    public var positionAt: Date

    public func elapsed(at now: Date) -> TimeInterval {
        guard isPlaying else { return position }
        return min(duration, position + now.timeIntervalSince(positionAt))
    }

    /// Freezes the extrapolated position as the new base (used for optimistic play/pause and seek).
    mutating func rebase(position newPosition: TimeInterval? = nil, at now: Date = .now) {
        position = newPosition ?? elapsed(at: now)
        positionAt = now
    }
}

extension SpotifyTrack {
    /// Parses the `com.spotify.client.PlaybackStateChanged` userInfo. Tolerates missing keys.
    /// Returns nil when playback stopped.
    ///
    /// Units differ: `Duration` is in milliseconds, `Playback Position` in seconds.
    init?(notification info: [AnyHashable: Any], now: Date) {
        let state = info["Player State"] as? String ?? "Stopped"
        guard state != "Stopped", let id = info["Track ID"] as? String else { return nil }
        self.init(
            id: id,
            title: info["Name"] as? String ?? "",
            artist: info["Artist"] as? String ?? "",
            duration: ((info["Duration"] as? NSNumber)?.doubleValue ?? 0) / 1000,
            isPlaying: state == "Playing",
            position: (info["Playback Position"] as? NSNumber)?.doubleValue ?? 0,
            positionAt: now
        )
    }
}
