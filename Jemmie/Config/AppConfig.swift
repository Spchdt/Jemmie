import Foundation

enum AppConfig {
    #if DEBUG
    // WARNING: To test on a physical device, change this to your Mac's local IP (e.g., "192.168.1.50:8080")
    static let backendHost = "jemmie-backend-387166258123.us-central1.run.app"
    static let websocketScheme = "wss"
    #else
    static let backendHost = "jemmie-backend-387166258123.us-central1.run.app"
    static let websocketScheme = "wss"
    #endif

    static func websocketURL(deviceId: String) -> URL {
        URL(string: "\(websocketScheme)://\(backendHost)/ws/\(deviceId)")!
    }

    static let pingInterval: TimeInterval = 15
    static let reconnectBaseDelay: TimeInterval = 1
    static let reconnectMaxDelay: TimeInterval = 30
    static let proximityCaptureDelay: TimeInterval = 0.5
    static let flipDebounceInterval: TimeInterval = 0.5
    static let audioChunkDuration: TimeInterval = 0.02 // 20ms
}
