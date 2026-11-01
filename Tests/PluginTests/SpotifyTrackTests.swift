import Foundation
import Testing
@testable import SpotifyPlugin

@Suite struct SpotifyTrackTests {
    let now = Date(timeIntervalSince1970: 1_000_000)

    @Test func parsesNotificationWithMixedUnits() throws {
        let info: [AnyHashable: Any] = [
            "Track ID": "spotify:track:abc",
            "Name": "Song",
            "Artist": "Artist",
            "Album": "Album",
            "Player State": "Playing",
            "Duration": NSNumber(value: 200_000), // milliseconds
            "Playback Position": NSNumber(value: 42.5), // seconds
        ]
        let track = try #require(SpotifyTrack(notification: info, now: now))
        #expect(track.duration == 200)
        #expect(track.position == 42.5)
        #expect(track.isPlaying)
    }

    @Test func stoppedMeansNoTrack() {
        #expect(SpotifyTrack(notification: ["Player State": "Stopped", "Track ID": "x"], now: now) == nil)
    }

    @Test func elapsedExtrapolatesOnlyWhilePlaying() throws {
        var track = try #require(SpotifyTrack(
            notification: ["Track ID": "x", "Player State": "Playing", "Duration": NSNumber(value: 100_000),
                           "Playback Position": NSNumber(value: 10)],
            now: now
        ))
        #expect(track.elapsed(at: now + 5) == 15)
        #expect(track.elapsed(at: now + 500) == 100) // clamped to duration

        track.isPlaying = false
        #expect(track.elapsed(at: now + 5) == 10)
    }
}
