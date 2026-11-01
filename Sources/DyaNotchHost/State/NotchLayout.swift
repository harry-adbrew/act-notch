import CoreGraphics

/// Sizes and radii for each presentation on one screen. Pure values; see docs/LLD.md §3.5.
///
/// "Body" is the island without its top flares; "shape" includes them; "canvas" is the window,
/// which adds room for spring overshoot and the secondary badge.
struct NotchLayout {
    struct Radii: Equatable {
        /// Concave flare where the island meets the menu bar (0 on pill screens).
        let top: CGFloat
        let bottom: CGFloat
    }

    static let expandedContentHeight: CGFloat = 156
    static let expandedMinWidth: CGFloat = 560
    static let peekContentHeight: CGFloat = 40
    static let peekMinWidth: CGFloat = 380
    static let secondaryDiameter: CGFloat = 28
    static let secondaryGap: CGFloat = 6
    static let overshootMargin = CGSize(width: 24, height: 12)

    let geometry: NotchGeometry

    /// Height of the band level with the camera.
    var bandHeight: CGFloat { geometry.notchSize.height }
    /// Wings are about as wide as they are tall, per Apple's compact guidance.
    var wing: CGFloat { bandHeight + 4 }

    func body(_ p: Presentation) -> CGSize {
        let notch = geometry.notchSize
        let compactWidth = notch.width + 2 * wing
        switch p {
        case .hidden: return CGSize(width: notch.width, height: geometry.hasNotch ? notch.height : 0)
        case .closed: return notch
        case .compact: return CGSize(width: compactWidth, height: notch.height)
        case .peek: return CGSize(width: max(compactWidth, Self.peekMinWidth), height: notch.height + Self.peekContentHeight)
        case .expanded: return CGSize(width: max(Self.expandedMinWidth, notch.width + 300), height: notch.height + Self.expandedContentHeight)
        }
    }

    func radii(_ p: Presentation) -> Radii {
        if geometry.hasNotch {
            switch p {
            case .hidden, .closed: return Radii(top: 6, bottom: 10)
            case .compact: return Radii(top: 6, bottom: 14)
            case .peek: return Radii(top: 10, bottom: 18)
            case .expanded: return Radii(top: 19, bottom: 24)
            }
        }
        switch p {
        case .hidden, .closed, .compact: return Radii(top: 0, bottom: bandHeight / 2)
        case .peek: return Radii(top: 0, bottom: 18)
        case .expanded: return Radii(top: 0, bottom: 24)
        }
    }

    /// Full island size including the flares.
    func shape(_ p: Presentation) -> CGSize {
        let body = body(p)
        return CGSize(width: body.width + 2 * radii(p).top, height: body.height)
    }

    /// Window size for a presentation.
    func canvas(_ p: Presentation, hasSecondary: Bool) -> CGSize {
        var size = shape(p)
        switch p {
        case .expanded, .peek:
            size.width += Self.overshootMargin.width
            size.height += Self.overshootMargin.height
        case .compact where hasSecondary:
            size.width += 2 * (Self.secondaryDiameter + Self.secondaryGap)
        default:
            break
        }
        return size
    }
}
