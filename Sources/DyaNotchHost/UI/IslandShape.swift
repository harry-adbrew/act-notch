import SwiftUI

/// The island silhouette: concave top flares that melt into the menu bar, rounded bottom corners.
/// Both radii are animatable, so one shape morphs through every state.
struct NotchShape: Shape {
    var topFlare: CGFloat
    var bottomRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topFlare, bottomRadius) }
        set { topFlare = newValue.first; bottomRadius = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        let t = min(topFlare, rect.width / 4)
        let b = min(bottomRadius, (rect.width - 2 * t) / 2, rect.height / 2)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        // Left flare: from the screen edge curving down into the body.
        p.addQuadCurve(to: CGPoint(x: rect.minX + t, y: rect.minY + t), control: CGPoint(x: rect.minX + t, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + t, y: rect.maxY - b))
        p.addQuadCurve(to: CGPoint(x: rect.minX + t + b, y: rect.maxY), control: CGPoint(x: rect.minX + t, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - t - b, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - t, y: rect.maxY - b), control: CGPoint(x: rect.maxX - t, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - t, y: rect.minY + t))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.maxX - t, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

/// Rounded rect for screens without a notch (floating pill under the menu bar).
struct PillShape: Shape {
    var radius: CGFloat
    var animatableData: CGFloat {
        get { radius }
        set { radius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: min(radius, rect.height / 2), style: .continuous)
    }
}

/// The island outline for a screen: notch silhouette on notched screens, rounded pill elsewhere.
enum IslandShape {
    static func make(hasNotch: Bool, radii: NotchLayout.Radii) -> AnyShape {
        hasNotch
            ? AnyShape(NotchShape(topFlare: radii.top, bottomRadius: radii.bottom))
            : AnyShape(PillShape(radius: radii.bottom))
    }
}
