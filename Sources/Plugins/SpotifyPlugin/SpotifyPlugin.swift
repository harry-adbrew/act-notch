import AppKit
import DyaNotchKit
import Observation
import SwiftUI

/// Now playing from Spotify, detected automatically. Fully event-driven (see `SpotifyMonitor`).
///
/// - Activity: `.ambient`, and only while a track is playing.
/// - A new track fetches artwork and peeks the notch for 2.5 s. Play/pause changes never peek.
@MainActor
@Observable
public final class SpotifyPlugin: NotchPlugin {
    public static let manifest = PluginManifest(
        id: "spotify",
        name: "Spotify",
        symbol: "music.note",
        summary: "Now playing, artwork and controls. Detected automatically."
    )

    static let trackChangePeek: TimeInterval = 2.5

    public private(set) var track: SpotifyTrack?
    private(set) var artwork: NSImage?
    private(set) var tint: Color = DN.Palette.spotify
    private(set) var isRunning = false

    @ObservationIgnored private var context: PluginContext?
    @ObservationIgnored private let monitor = SpotifyMonitor()
    @ObservationIgnored private let artworkLoader = ArtworkLoader()

    public init() {}

    // MARK: - Lifecycle

    public func activate(_ context: PluginContext) async throws {
        self.context = context
        monitor.onEvent = { [weak self] event in self?.handle(event) }
        monitor.start()
        // Spotify only posts on changes, so read the current state once if it is already running.
        if SpotifyMonitor.isSpotifyRunning, let current = await SpotifyAppleEvents.currentTrack() {
            apply(current, allowPeek: false)
        }
    }

    public func deactivate() {
        monitor.stop()
        context = nil
    }

    private func handle(_ event: SpotifyMonitor.Event) {
        switch event {
        case .launched:
            isRunning = true
            context?.log.info("Spotify detected")
        case .quit:
            isRunning = false
            track = nil
            artwork = nil
        case .playback(let new):
            if let new { apply(new, allowPeek: true) } else { track = nil }
        }
    }

    private func apply(_ new: SpotifyTrack, allowPeek: Bool) {
        let isNewTrack = new.id != track?.id
        track = new
        guard isNewTrack else { return }

        artwork = nil
        loadArtwork(for: new.id)
        if allowPeek && new.isPlaying { context?.requestPeek(seconds: Self.trackChangePeek) }
    }

    private func loadArtwork(for trackID: String) {
        Task { [weak self] in
            guard let artwork = await self?.artworkLoader.artwork(for: trackID),
                  self?.track?.id == trackID else { return } // the track changed meanwhile
            self?.artwork = artwork.image
            self?.tint = Color(nsColor: artwork.tint)
        }
    }

    // MARK: - Commands

    func playPause() {
        SpotifyAppleEvents.send(.playPause)
        // Optimistic: flip now; the next notification confirms.
        track?.rebase()
        track?.isPlaying.toggle()
    }

    func next() { SpotifyAppleEvents.send(.next) }

    func previous() { SpotifyAppleEvents.send(.previous) }

    func seek(to seconds: TimeInterval) {
        SpotifyAppleEvents.send(.seek(seconds))
        track?.rebase(position: seconds)
    }

    // MARK: - Activity

    public var activity: LiveActivity? {
        guard isRunning, let track, track.isPlaying else { return nil }
        return LiveActivity(id: "spotify", priority: .ambient, since: track.positionAt, tint: tint)
    }

    /// Shared `matchedGeometryEffect` id for the artwork (compact ⇄ expanded).
    static let artworkID = "spotify-art"
}
