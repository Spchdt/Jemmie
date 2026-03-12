import Foundation

@Observable
@MainActor
final class WebSocketService {
    private(set) var isConnected = false

    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var pingTask: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?
    private var reconnectAttempt = 0
    private var intentionalDisconnect = false

    // Callbacks
    var onBinaryMessage: ((Data) -> Void)?
    var onServerEvent: ((ServerEvent) -> Void)?
    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?

    // MARK: - Public API

    func connect() {
        intentionalDisconnect = false
        reconnectAttempt = 0
        establishConnection()
    }

    func disconnect() {
        intentionalDisconnect = true
        teardown()
    }

    func sendBinary(_ data: Data) {
        guard let ws = webSocketTask else { return }
        ws.send(.data(data)) { error in
            if let error {
                print("[WebSocket] Binary send error: \(error.localizedDescription)")
            }
        }
    }

    func sendText(_ frame: ClientFrame) {
        guard let ws = webSocketTask, let text = frame.jsonString() else { return }
        ws.send(.string(text)) { error in
            if let error {
                print("[WebSocket] Text send error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Connection

    private func establishConnection() {
        let url = AppConfig.websocketURL(deviceId: DeviceIdentity.deviceId)
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)

        guard let session else { return }
        let task = session.webSocketTask(with: url)
        webSocketTask = task
        task.resume()

        print("[WebSocket] 🌍 Attempting connection to: \(url)")

        startReceiveLoop()
        startPingLoop()

        isConnected = true
        reconnectAttempt = 0
        print("[WebSocket] ✅ Successfully connected to backend host!")
        onConnected?()
    }

    // MARK: - Receive Loop (async/await)

    private func startReceiveLoop() {
        receiveTask?.cancel()
        receiveTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                guard let ws = webSocketTask else { break }
                do {
                    let message = try await ws.receive()
                    handleMessage(message)
                } catch {
                    if !Task.isCancelled {
                        print("[WebSocket] Receive error: \(error.localizedDescription)")
                        handleDisconnection()
                    }
                    break
                }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            print("[WebSocket] 🎵 Received binary audio chunk (\(data.count) bytes)")
            onBinaryMessage?(data)
        case .string(let text):
            print("[WebSocket] 💬 Received text frame: \(text)")
            if let data = text.data(using: .utf8),
               let event = ServerEvent(from: data) {
                onServerEvent?(event)
            }
        @unknown default:
            break
        }
    }

    // MARK: - Keepalive

    private func startPingLoop() {
        pingTask?.cancel()
        pingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(AppConfig.pingInterval))
                guard !Task.isCancelled else { break }
                self?.sendText(.ping)
            }
        }
    }

    // MARK: - Reconnection

    private func handleDisconnection() {
        isConnected = false
        onDisconnected?()

        guard !intentionalDisconnect else { return }

        let delay = min(
            AppConfig.reconnectBaseDelay * pow(2, Double(reconnectAttempt)),
            AppConfig.reconnectMaxDelay
        )
        reconnectAttempt += 1
        print("[WebSocket] Reconnecting in \(delay)s (attempt \(reconnectAttempt))")

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self, !self.intentionalDisconnect else { return }
            self.establishConnection()
        }
    }

    // MARK: - Teardown

    private func teardown() {
        receiveTask?.cancel()
        receiveTask = nil
        pingTask?.cancel()
        pingTask = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        session?.invalidateAndCancel()
        session = nil
        isConnected = false
        onDisconnected?()
    }
}
