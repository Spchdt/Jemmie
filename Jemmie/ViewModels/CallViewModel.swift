import Foundation
import SwiftUI
import CoreLocation

@Observable
@MainActor
final class CallViewModel {
    var callState: CallState = .idle
    var isMuted = false
    var isSpeakerOn = false
    var isCameraEnabled = false
    var isAgentSpeaking = false
    var activeTimers: [ActiveTimer] = []
    var callDuration: TimeInterval = 0

    let transcript = TranscriptViewModel()

    private let callManager = CallManager.shared
    private let webSocket = WebSocketService()
    private let audioEngine = AudioEngine()
    private let hardwareInput = HardwareInputService()
    private let camera = CameraService()
    private let location = LocationService()
    private let timerService = TimerService()
    private var callTimer: Timer?

    init() {
        bindCallManager()
        bindWebSocket()
        bindHardwareInputs()
    }

    // MARK: - Public Actions

    func startCall() {
        callManager.startCall()
    }

    func endCall() {
        callManager.endCall()
    }

    func toggleMute() {
        audioEngine.toggleMute()
        isMuted = audioEngine.isMuted
    }

    func toggleSpeaker() {
        audioEngine.toggleSpeaker()
        isSpeakerOn = audioEngine.isSpeakerOn
    }

    func toggleCamera() {
        isCameraEnabled.toggle()
    }

    func shareLocation() {
        Task { @MainActor in
            guard let loc = await location.requestLocation() else {
                transcript.appendSystemMessage("⚠️ Location permission denied")
                return
            }
            
            transcript.appendSystemMessage("📍 Sent location (\(loc.latitude.rounded()), \(loc.longitude.rounded()))")
            webSocket.sendText(.shareLocation(lat: loc.latitude, lng: loc.longitude))
        }
    }

    // MARK: - CallManager Bindings

    private func bindCallManager() {
        callManager.onCallStarted = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.webSocket.connect()
                self.hardwareInput.startAll()
                self.transcript.clear()
            }
        }

        callManager.onAudioActivated = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.audioEngine.start()
                self.callManager.markCallConnected()
                self.startCallTimer()
            }
        }

        callManager.onCallEnded = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.audioEngine.stop()
                self.webSocket.disconnect()
                self.hardwareInput.stopAll()
                self.isAgentSpeaking = false
                self.isMuted = false
                self.isSpeakerOn = false
                self.isCameraEnabled = false
                self.stopCallTimer()
            }
        }

        callManager.onStateChanged = { [weak self] state in
            Task { @MainActor in
                self?.callState = state
            }
        }
    }

    // MARK: - WebSocket Bindings

    private func bindWebSocket() {
        audioEngine.onCapturedAudio = { [weak self] data in
            self?.webSocket.sendBinary(data)
        }

        webSocket.onBinaryMessage = { [weak self] data in
            guard let self else { return }
            self.isAgentSpeaking = true
            self.audioEngine.playAudio(data)
        }

        webSocket.onServerEvent = { [weak self] event in
            guard let self else { return }
            self.handleServerEvent(event)
        }
    }

    // MARK: - Hardware Input Bindings

    private func bindHardwareInputs() {
        hardwareInput.onProximityAway = nil

        hardwareInput.onVolumeUp = { [weak self] in
            self?.webSocket.sendText(.volumeUp())
            Task { @MainActor in
                self?.transcript.appendSystemMessage("▲ Confirmed")
            }
        }

        hardwareInput.onVolumeDown = { [weak self] in
            self?.webSocket.sendText(.volumeDown())
            Task { @MainActor in
                self?.transcript.appendSystemMessage("▼ Denied")
            }
        }

        hardwareInput.onFlipDetected = { [weak self] in
            self?.webSocket.sendText(.flipExit())
            Task { @MainActor in
                self?.transcript.appendSystemMessage("📱 Flip detected — ending call")
                try? await Task.sleep(for: .milliseconds(300))
                self?.endCall()
            }
        }
    }

    // MARK: - Server Event Handling

    private func handleServerEvent(_ event: ServerEvent) {
        switch event {
        case .text(let text):
            transcript.appendAgentSpeech(text)

        case .transcriptionInput(let text):
            transcript.appendUserSpeech(text)

        case .transcriptionOutput(let text):
            transcript.appendAgentSpeech(text)

        case .audio(let data):
            print("[AUDIO] 🔊 Received audio via text frame (\(data.count) bytes)")
            isAgentSpeaking = true
            audioEngine.playAudio(data)

        case .turnComplete:
            isAgentSpeaking = false
            transcript.markLastAgentComplete()

        case .interrupted:
            isAgentSpeaking = false
            audioEngine.flushPlayback()
            transcript.appendSystemMessage("(interrupted)")

        case .error(let message, let recoverable, _):
            if recoverable {
                transcript.appendSystemMessage("⚠️ \(message)")
            } else {
                callState = .error(message)
                endCall()
            }

        case .pong:
            break

        case .custom(let type, let payload):
            handleCustomEvent(type: type, payload: payload)
        }
    }

    func dismissTimer(_ timer: ActiveTimer) {
        Task {
            await timerService.cancelTimer(id: timer.id)
            activeTimers.removeAll { $0.id == timer.id }
        }
    }

    private func handleCustomEvent(type: String, payload: [String: Any]) {
        switch type {
        case "SET_TIMER":
            let label = payload["label"] as? String ?? "Timer"
            let duration = payload["duration_seconds"] as? Int ?? 0
            Task {
                if let alarmID = await timerService.scheduleTimer(durationSeconds: duration, label: label) {
                    let timer = ActiveTimer(
                        id: alarmID,
                        label: label,
                        duration: duration,
                        fireDate: Date.now.addingTimeInterval(TimeInterval(duration))
                    )
                    activeTimers.append(timer)
                    transcript.appendSystemMessage("⏱ Timer set: \(label) (\(duration)s)")

                    // Auto-remove when the timer fires
                    Task {
                        try? await Task.sleep(for: .seconds(duration))
                        activeTimers.removeAll { $0.id == alarmID }
                    }
                } else {
                    transcript.appendSystemMessage("⚠️ Could not set timer — AlarmKit permission needed")
                }
            }
        default:
            transcript.appendSystemMessage("[\(type)]")
        }
    }

    // MARK: - Call Duration Timer

    private func startCallTimer() {
        callDuration = 0
        callTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.callDuration += 1
            }
        }
    }

    private func stopCallTimer() {
        callTimer?.invalidate()
        callTimer = nil
        callDuration = 0
    }

    // MARK: - Camera

    private func captureAndSendFrame() {
        camera.captureFrame { [weak self] jpegData in
            guard let self, let data = jpegData else { return }
            let base64 = data.base64EncodedString()
            self.webSocket.sendText(.image(base64Data: base64))
            Task { @MainActor in
                self.transcript.appendSystemMessage("📸 Sent camera frame")
            }
        }
    }
}
