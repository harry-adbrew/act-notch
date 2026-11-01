import SwiftUI

/// Circular progress ring starting at 12 o'clock. `fraction` is the remaining part (1 = full).
public struct NotchRing: View {
    private let fraction: Double
    private let tint: Color
    private let lineWidth: CGFloat

    public init(fraction: Double, tint: Color, lineWidth: CGFloat = 2.5) {
        self.fraction = fraction
        self.tint = tint
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.22), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1, max(0, fraction)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
