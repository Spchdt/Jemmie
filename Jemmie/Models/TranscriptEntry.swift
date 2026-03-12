import Foundation
import SwiftUI

struct TranscriptEntry: Identifiable {
    let id = UUID()
    let speaker: Speaker
    var text: String
    let timestamp: Date
    var isComplete: Bool

    enum Speaker {
        case user, agent, system

        var label: String {
            switch self {
            case .user: "You"
            case .agent: "Jemmie"
            case .system: "System"
            }
        }

        var color: Color {
            switch self {
            case .user: .blue
            case .agent: .green
            case .system: .orange
            }
        }
    }

    init(speaker: Speaker, text: String, isComplete: Bool = false) {
        self.speaker = speaker
        self.text = text
        self.timestamp = .now
        self.isComplete = isComplete
    }
}
