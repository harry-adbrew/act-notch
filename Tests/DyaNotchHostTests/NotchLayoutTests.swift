import CoreGraphics
import Testing
@testable import DyaNotchHost

@Suite struct NotchLayoutTests {
    /// A 14" MacBook Pro-like screen: 1512×982 pt, 185×32 pt notch.
    let notched = NotchGeometry(
        displayID: 1,
        screenFrame: CGRect(x: 0, y: 0, width: 1512, height: 982),
        visibleFrame: CGRect(x: 0, y: 0, width: 1512, height: 950),
        hardwareNotch: CGSize(width: 185, height: 32)
    )
    let external = NotchGeometry(
        displayID: 2,
        screenFrame: CGRect(x: 1512, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 1512, y: 0, width: 1920, height: 1055),
        hardwareNotch: nil
    )

    @Test func closedCoversTheHardwareNotchWithBleed() {
        let layout = NotchLayout(geometry: notched)
        #expect(layout.body(.closed) == CGSize(width: 189, height: 32))
        #expect(layout.shape(.closed).width == CGFloat(189 + 2 * 6)) // plus both flares
    }

    @Test func compactAddsTwoEqualWings() {
        let layout = NotchLayout(geometry: notched)
        #expect(layout.wing == 36)
        #expect(layout.body(.compact).width == CGFloat(189 + 2 * 36))
    }

    @Test func expandedAndPeekRespectMinimums() {
        let layout = NotchLayout(geometry: notched)
        #expect(layout.body(.expanded).width == NotchLayout.expandedMinWidth)
        #expect(layout.body(.peek).width == NotchLayout.peekMinWidth)
    }

    @Test func secondaryBadgeWidensOnlyTheCompactCanvas() {
        let layout = NotchLayout(geometry: notched)
        let extra = 2 * (NotchLayout.secondaryDiameter + NotchLayout.secondaryGap)
        #expect(layout.canvas(.compact, hasSecondary: true).width == layout.shape(.compact).width + extra)
        #expect(layout.canvas(.closed, hasSecondary: true).width == layout.shape(.closed).width)
    }

    @Test func pillScreensHaveNoFlares() {
        let layout = NotchLayout(geometry: external)
        #expect(layout.radii(.expanded).top == 0)
        #expect(layout.body(.hidden).height == 0)
    }

    @Test func notchedWindowIsPinnedToTheTopCentre() {
        let frame = notched.windowFrame(canvas: CGSize(width: 300, height: 40), hidden: false)
        #expect(frame.maxY == 982)
        #expect(frame.midX == 756)
    }

    @Test func pillWindowFloatsUnderTheMenuBarOrBecomesAHotEdge() {
        let floating = external.windowFrame(canvas: CGSize(width: 300, height: 40), hidden: false)
        #expect(floating.maxY == 1055 - NotchGeometry.pillGap)

        let hotEdge = external.windowFrame(canvas: CGSize(width: 300, height: 40), hidden: true)
        #expect(hotEdge.size == NotchGeometry.hotEdgeSize)
        #expect(hotEdge.maxY == 1080)
    }
}
