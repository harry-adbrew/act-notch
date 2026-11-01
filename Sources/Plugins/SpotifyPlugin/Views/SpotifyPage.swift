import DyaNotchKit
import SwiftUI

/// Expanded player: artwork with a tinted glow, title/artist, scrubber, transport controls.
struct SpotifyPage: View {
    let plugin: SpotifyPlugin
    let namespace: Namespace.ID

    var body: some View {
        if let track = plugin.track {
            player(track)
        } else {
            placeholder
        }
    }

    private func player(_ track: SpotifyTrack) -> some View {
        HStack(spacing: DN.Space.l) {
            ArtworkView(image: plugin.artwork, size: 80, radius: DN.Radius.art)
                .matchedGeometryEffect(id: SpotifyPlugin.artworkID, in: namespace)
                .shadow(color: plugin.tint.opacity(0.45), radius: 18)

            VStack(alignment: .leading, spacing: DN.Space.s) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(DN.Typography.titleLarge)
                        .foregroundStyle(DN.Palette.textPrimary)
                    Text(track.artist)
                        .font(DN.Typography.bodyLarge)
                        .foregroundStyle(DN.Palette.textSecondary)
                }
                .lineLimit(1)

                ScrubBar(track: track, tint: plugin.tint, onSeek: plugin.seek(to:))

                transport(isPlaying: track.isPlaying)
            }
        }
    }

    private func transport(isPlaying: Bool) -> some View {
        HStack(spacing: DN.Space.l) {
            Spacer()
            NotchIconButton("backward.fill", size: 30) { plugin.previous() }
            NotchIconButton(isPlaying ? "pause.fill" : "play.fill", size: 38, prominent: true) { plugin.playPause() }
            NotchIconButton("forward.fill", size: 30) { plugin.next() }
            Spacer()
        }
    }

    private var placeholder: some View {
        VStack(spacing: DN.Space.s) {
            Image(systemName: "music.note")
                .font(.system(size: 22))
                .foregroundStyle(DN.Palette.textTertiary)
            Text(plugin.isRunning ? "Nothing playing in Spotify" : "Open Spotify to see what's playing")
                .font(DN.Typography.body)
                .foregroundStyle(DN.Palette.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
    }
}

/// Draggable progress bar with elapsed / remaining times. Seeks on release.
/// Progress is extrapolated from the last notification; refreshes once a second while visible.
private struct ScrubBar: View {
    let track: SpotifyTrack
    let tint: Color
    let onSeek: (TimeInterval) -> Void
    @State private var dragPosition: TimeInterval?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let elapsed = dragPosition ?? track.elapsed(at: context.date)
            VStack(spacing: 4) {
                bar(elapsed: elapsed)
                times(elapsed: elapsed)
            }
        }
    }

    private func bar(elapsed: TimeInterval) -> some View {
        GeometryReader { geo in
            NotchProgressBar(fraction: track.duration > 0 ? elapsed / track.duration : 0, tint: tint)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let fraction = min(1, max(0, drag.location.x / geo.size.width))
                            dragPosition = fraction * track.duration
                        }
                        .onEnded { _ in
                            if let dragPosition { onSeek(dragPosition) }
                            dragPosition = nil
                        }
                )
        }
        .frame(height: 10)
    }

    private func times(elapsed: TimeInterval) -> some View {
        HStack {
            Text(DurationParser.clock(elapsed))
            Spacer()
            Text("-" + DurationParser.clock(track.duration - elapsed))
        }
        .font(DN.Typography.caption)
        .monospacedDigit()
        .foregroundStyle(DN.Palette.textTertiary)
    }
}
