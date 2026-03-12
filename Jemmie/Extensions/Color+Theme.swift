import SwiftUI

extension Color {
    /// Deep background color for Jemmie UI
    static let jemmieBackground = Color(white: 0.08)

    /// Apple call screen teal gradient
    struct CallScreen {
        static let gradientTop = Color(red: 0.04, green: 0.22, blue: 0.30)
        static let gradientBottom = Color(red: 0.02, green: 0.32, blue: 0.38)
        static let bubbleUser = Color.white.opacity(0.15)
        static let bubbleAgent = Color.white.opacity(0.10)
        static let bubbleSystem = Color.white.opacity(0.06)
    }

    struct Orb {
        static let glowActive = Color.green.opacity(0.2)

        static let connectedFillStart = Color.green.opacity(0.6)
        static let connectedFillEnd = Color.green.opacity(0.1)

        static let idleFillStart = Color.gray.opacity(0.3)
        static let idleFillEnd = Color.gray.opacity(0.05)

        static let connectedStroke = Color.green.opacity(0.5)
        static let idleStroke = Color.gray.opacity(0.2)

        static let connectedIcon = Color.green
        static let idleIcon = Color.gray
    }
}
