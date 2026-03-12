import SwiftUI

enum Design {
    // MARK: - Spacing
    enum Spacing {
        static let small: Double = 6
        static let medium: Double = 16
        static let large: Double = 24
        static let extraLarge: Double = 32
        static let controlGap: Double = 40
    }

    // MARK: - Sizes
    enum Size {
        static let orbDiameter: Double = 120
        static let orbGlowDiameter: Double = 200
        static let callButtonDiameter: Double = 84
        static let callButtonRingDiameter: Double = 98
        static let controlButtonDiameter: Double = 84
        static let statusDot: Double = 8
        static let orbIconSize: Double = 32
        static let callButtonIconSize: Double = 30
        static let controlIconSize: Double = 28
    }

    // MARK: - Animation
    enum Animation {
        static let pulseScale: Double = 1.5
        static let orbScale: Double = 1.15
        static let orbPulseDuration: Double = 0.8
        static let callPulseDuration: Double = 1.5
        static let scrollDuration: Double = 0.2
    }

    // MARK: - Layout
    enum Layout {
        static let transcriptMaxHeight: Double = 280
        static let horizontalPadding: Double = 20
        static let topPadding: Double = 8
        static let gridColumnSpacing: Double = 35
        static let gridRowSpacing: Double = 28
    }
}
