import SwiftUI

/// Single source of truth for the design system. docs/DESIGN.md §4 mirrors this file; change both together.
public enum DN {
    public enum Palette {
        /// The notch fill. Pure black so it merges with the hardware notch.
        public static let notch = Color.black
        public static let surface = Color(hex: 0x1C1C1E)
        public static let surfaceRaised = Color(hex: 0x2C2C2E)

        public static let textPrimary = Color.white
        public static let textSecondary = Color.white.opacity(0.62)
        public static let textTertiary = Color.white.opacity(0.38)

        public static let spotify = Color(hex: 0x1DB954)
        public static let timer = Color(hex: 0xFF9F0A)
        public static let todo = Color(hex: 0x0A84FF)
        public static let danger = Color(hex: 0xFF453A)
        public static let success = Color(hex: 0x30D158)

        /// Fill behind interactive elements, by state.
        public static let controlFill = Color.white.opacity(0.08)
        public static let controlFillHover = Color.white.opacity(0.16)
        public static let controlFillSelected = Color.white.opacity(0.14)
    }

    /// Inner radii follow the concentric rule: outer bottom radius minus the content margin.
    public enum Radius {
        public static let compactArt: CGFloat = 5
        public static let tab: CGFloat = 7
        public static let row: CGFloat = 8
        public static let button: CGFloat = 10
        public static let card: CGFloat = 12
        public static let art: CGFloat = 12
    }

    public enum Space {
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 12
        public static let l: CGFloat = 16
        /// Content margin inside the expanded island.
        public static let margin: CGFloat = 14
    }

    public enum Typography {
        public static let title = Font.system(size: 13, weight: .semibold)
        public static let titleLarge = Font.system(size: 15, weight: .semibold)
        public static let body = Font.system(size: 12, weight: .regular)
        public static let bodyLarge = Font.system(size: 13, weight: .regular)
        public static let caption = Font.system(size: 11, weight: .medium)
        public static let compactValue = Font.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit()
        public static let digits = Font.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit()
        public static let digitsLarge = Font.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit()
    }

    public enum Icon {
        public static let compact: CGFloat = 14
        public static let tab: CGFloat = 13
        public static let expanded: CGFloat = 17
    }

    /// Response/damping match the tested values used by shipped notch apps (docs/DESIGN.md §Motion).
    public enum Motion {
        public static let open = Animation.spring(response: 0.42, dampingFraction: 0.80)
        public static let close = Animation.spring(response: 0.45, dampingFraction: 1.0)
        public static let swap = Animation.spring(response: 0.34, dampingFraction: 0.88)
        public static let press = Animation.spring(response: 0.2, dampingFraction: 0.7)
        /// Used for every state change when Reduce Motion is on.
        public static let reduced = Animation.easeInOut(duration: 0.2)
    }
}
