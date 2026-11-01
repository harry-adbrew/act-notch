import DyaNotchKit
import SwiftUI

/// The island surfaces for Spotify: artwork | equalizer in compact, title · artist in peek,
/// the full player in expanded.
extension SpotifyPlugin {
    public func compactLeading(_ ctx: NotchViewContext) -> AnyView? {
        guard track != nil else { return nil }
        return AnyView(
            ArtworkView(image: artwork, size: 20, radius: DN.Radius.compactArt)
                .matchedGeometryEffect(id: Self.artworkID, in: ctx.namespace)
        )
    }

    public func compactTrailing(_ ctx: NotchViewContext) -> AnyView? {
        guard let track else { return nil }
        return AnyView(
            EqualizerBars(isPlaying: track.isPlaying, tint: tint)
                .frame(width: 18, height: 14)
        )
    }

    public func peekView(_ ctx: NotchViewContext) -> AnyView? {
        guard let track else { return nil }
        return AnyView(
            HStack(spacing: DN.Space.s) {
                Text(track.title)
                    .font(DN.Typography.title)
                    .foregroundStyle(DN.Palette.textPrimary)
                Text(track.artist)
                    .font(DN.Typography.body)
                    .foregroundStyle(DN.Palette.textSecondary)
                Spacer(minLength: 0)
            }
            .lineLimit(1)
        )
    }

    public func expandedView(_ ctx: NotchViewContext) -> AnyView? {
        AnyView(SpotifyPage(plugin: self, namespace: ctx.namespace))
    }
}
