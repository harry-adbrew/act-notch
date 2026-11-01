import DyaNotchKit
import SwiftUI

/// Rounded album artwork with a music-note placeholder while it loads.
struct ArtworkView: View {
    let image: NSImage?
    let size: CGFloat
    let radius: CGFloat

    var body: some View {
        ZStack {
            shape.fill(DN.Palette.surfaceRaised)
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundStyle(DN.Palette.textTertiary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(shape)
        .animation(.easeOut(duration: 0.25), value: image)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}
