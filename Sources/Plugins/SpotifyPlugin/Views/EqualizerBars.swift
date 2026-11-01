import SwiftUI

/// Fake visualizer: a few sine-driven bars, with no audio capture.
/// Animates at ≤ 12 fps and only while playing *and* on screen; when paused it is a static frame.
struct EqualizerBars: View {
    let isPlaying: Bool
    let tint: Color

    private let speeds: [Double] = [4.1, 5.3, 3.4, 4.7]
    private let gap: CGFloat = 2

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12, paused: !isPlaying)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            Canvas { graphics, size in
                for rect in barRects(in: size, time: time) {
                    graphics.fill(Path(roundedRect: rect, cornerRadius: rect.width / 2), with: .color(tint))
                }
            }
        }
    }

    /// Bar heights oscillate between 30% and 100%; paused bars rest at 25%.
    private func barRects(in size: CGSize, time: TimeInterval) -> [CGRect] {
        let count = CGFloat(speeds.count)
        let width = (size.width - gap * (count - 1)) / count
        return speeds.enumerated().map { index, speed in
            let level = isPlaying ? 0.3 + 0.7 * abs(sin(time * speed + Double(index) * 1.3)) : 0.25
            let height = max(width, size.height * level)
            return CGRect(x: CGFloat(index) * (width + gap), y: (size.height - height) / 2, width: width, height: height)
        }
    }
}
