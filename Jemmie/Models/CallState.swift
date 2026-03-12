import Foundation

enum CallState: Equatable {
    case idle
    case connecting
    case active
    case reconnecting
    case ending
    case error(String)

    var isConnected: Bool {
        switch self {
        case .active, .reconnecting: true
        default: false
        }
    }

    var displayText: String {
        switch self {
        case .idle: "Ready"
        case .connecting: "Connecting…"
        case .active: "Connected"
        case .reconnecting: "Reconnecting…"
        case .ending: "Ending…"
        case .error(let msg): "Error: \(msg)"
        }
    }
}
