import Foundation

struct ClientFrame: Encodable {
    let type: String
    let payload: [String: AnyCodable]

    init(type: String, payload: [String: Any] = [:]) {
        self.type = type
        self.payload = payload.mapValues { AnyCodable($0) }
    }

    func jsonData() -> Data? {
        try? JSONEncoder().encode(self)
    }

    func jsonString() -> String? {
        guard let data = jsonData() else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Convenience constructors

    static func image(base64Data: String, mimeType: String = "image/jpeg") -> ClientFrame {
        ClientFrame(type: "IMAGE", payload: ["data": base64Data, "mime_type": mimeType])
    }

    static let ping = ClientFrame(type: "PING")

    static func volumeUp() -> ClientFrame {
        ClientFrame(type: "VOLUME_UP", payload: ["intent": "confirm"])
    }

    static func volumeDown() -> ClientFrame {
        ClientFrame(type: "VOLUME_DOWN", payload: ["intent": "deny"])
    }

    static func flipExit() -> ClientFrame {
        ClientFrame(type: "FLIP_EXIT", payload: ["intent": "end_session"])
    }

    static func shareLocation(lat: Double, lng: Double) -> ClientFrame {
        ClientFrame(type: "SHARE_LOCATION", payload: ["lat": lat, "lng": lng])
    }
}

// MARK: - Type-erased Codable wrapper

struct AnyCodable: Encodable {
    private let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as String: try container.encode(v)
        case let v as Int: try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as Bool: try container.encode(v)
        case let v as [String: Any]:
            try container.encode(v.mapValues { AnyCodable($0) })
        case let v as [Any]:
            try container.encode(v.map { AnyCodable($0) })
        default:
            try container.encode(String(describing: value))
        }
    }
}
