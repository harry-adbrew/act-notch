import SwiftUI

/// Thin horizontal progress bar. `fraction` is clamped to 0...1.
public struct NotchProgressBar: View {
    private let fraction: Double
    private let tint: Color

    public init(fraction: Double, tint: Color) {
        self.fraction = fraction
        self.tint = tint
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.14))
                Capsule().fill(tint).frame(width: clamped * geo.size.width)
            }
        }
        .frame(height: 4)
    }

    private var clamped: Double { min(1, max(0, fraction)) }
}
