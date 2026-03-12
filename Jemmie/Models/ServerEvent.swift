import Foundation

enum ServerEvent {
    case text(String)
    case transcriptionInput(String)
    case transcriptionOutput(String)
    case audio(Data)
    case turnComplete
    case interrupted
    case error(message: String, recoverable: Bool, code: String?)
    case pong
    case custom(type: String, payload: [String: Any])

    init?(from data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return nil
        }

        let payload = json["payload"] as? [String: Any] ?? [:]

        switch type {
        case "TEXT":
            self = .text(payload["text"] as? String ?? "")
        case "TRANSCRIPTION_INPUT":
            self = .transcriptionInput(payload["text"] as? String ?? "")
        case "TRANSCRIPTION_OUTPUT":
            self = .transcriptionOutput(payload["text"] as? String ?? "")
        case "AUDIO":
            if let b64String = payload["data"] as? String,
               let audioData = Data(base64Encoded: b64String) {
                self = .audio(audioData)
            } else {
                return nil
            }
        case "TURN_COMPLETE":
            self = .turnComplete
        case "INTERRUPTED":
            self = .interrupted
        case "ERROR":
            self = .error(
                message: payload["message"] as? String ?? "Unknown error",
                recoverable: payload["recoverable"] as? Bool ?? false,
                code: payload["code"] as? String
            )
        case "PONG":
            self = .pong
        default:
            self = .custom(type: type, payload: payload)
        }
    }
}
