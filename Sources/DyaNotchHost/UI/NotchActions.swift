/// Callbacks from the SwiftUI tree up to the window controller.
struct NotchActions {
    /// Called whenever the derived presentation (or the secondary badge) changes, so the window can resize.
    var presentationChanged: (Presentation, _ hasSecondary: Bool) -> Void
    var expand: () -> Void
    var openSettings: () -> Void
}
