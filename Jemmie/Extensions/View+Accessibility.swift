import SwiftUI

extension View {
    /// Conditionally hides the view from accessibility tools if it's purely decorative.
    @ViewBuilder
    func decorativeAccessibility(isHidden: Bool = true) -> some View {
        if isHidden {
            self.accessibilityHidden(true)
        } else {
            self
        }
    }
    
    /// A standardized way to make a custom element accessible as a button.
    func accessibleButton(label: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(label)
    }
}
