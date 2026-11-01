import SwiftUI

/// What the host hands to every plugin view builder.
public struct NotchViewContext {
    /// Shared namespace, so compact and expanded views can `matchedGeometryEffect` the same element.
    public let namespace: Namespace.ID

    public init(namespace: Namespace.ID) {
        self.namespace = namespace
    }
}
