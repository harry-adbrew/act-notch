import AppKit

/// Watches Spotify without polling:
/// - `NSWorkspace` launch/terminate notifications tell us when Spotify starts or quits;
/// - Spotify's distributed notification is subscribed to **only while Spotify runs**.
@MainActor
final class SpotifyMonitor {
    enum Event {
        case launched
        case quit
        /// nil = playback stopped.
        case playback(SpotifyTrack?)
    }

    nonisolated static let bundleID = "com.spotify.client"
    private static let playbackNotification = Notification.Name("com.spotify.client.PlaybackStateChanged")

    var onEvent: (Event) -> Void = { _ in }

    private var workspaceObservers: [NSObjectProtocol] = []
    private var playbackObserver: NSObjectProtocol?

    static var isSpotifyRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }

    func start() {
        let center = NSWorkspace.shared.notificationCenter
        workspaceObservers = [
            center.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main) { [weak self] note in
                guard Self.isSpotify(note) else { return }
                MainActor.assumeIsolated { self?.spotifyLaunched() }
            },
            center.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) { [weak self] note in
                guard Self.isSpotify(note) else { return }
                MainActor.assumeIsolated { self?.spotifyQuit() }
            },
        ]
        if Self.isSpotifyRunning { spotifyLaunched() }
    }

    func stop() {
        workspaceObservers.forEach(NSWorkspace.shared.notificationCenter.removeObserver)
        workspaceObservers = []
        unsubscribePlayback()
    }

    // MARK: - Private

    private func spotifyLaunched() {
        subscribePlayback()
        onEvent(.launched)
    }

    private func spotifyQuit() {
        unsubscribePlayback()
        onEvent(.quit)
    }

    private func subscribePlayback() {
        guard playbackObserver == nil else { return }
        playbackObserver = DistributedNotificationCenter.default().addObserver(
            forName: Self.playbackNotification, object: nil, queue: .main
        ) { [weak self] note in
            // Parse before hopping: the track is Sendable, the userInfo dictionary is not.
            let track = SpotifyTrack(notification: note.userInfo ?? [:], now: .now)
            MainActor.assumeIsolated { self?.onEvent(.playback(track)) }
        }
    }

    private func unsubscribePlayback() {
        if let playbackObserver { DistributedNotificationCenter.default().removeObserver(playbackObserver) }
        playbackObserver = nil
    }

    private nonisolated static func isSpotify(_ note: Notification) -> Bool {
        (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.bundleIdentifier == bundleID
    }
}
