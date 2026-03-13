import Foundation
import SwiftUI
import CoreLocation
import UIKit
import UserNotifications

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
    
    // New Feature States
    var isWaitingForBinaryInput = false
    var shouldShowCameraPreview = false

    let transcript = TranscriptViewModel()

    private let callManager = CallManager.shared
    private let webSocket = WebSocketService()
    private let audioEngine = AudioEngine()
    private let hardwareInput = HardwareInputService()
    private let camera = CameraService()
    private let location = LocationService()
    private let timerService = TimerService()
    private let notificationService = NotificationService()
    
    private var callTimer: Timer?
    private var binaryInputTimeoutTask: Task<Void, Never>?

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
                self.shouldShowCameraPreview = false
                self.stopBinaryInputCapture()
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
        hardwareInput.onProximityAway = { [weak self] in
            guard let self else { return }
            if self.shouldShowCameraPreview {
                // When pulled from ear and agent requested a photo
                self.captureAndSendFrame()
            }
        }

        hardwareInput.onVolumeUp = { [weak self] in
            guard let self = self, self.isWaitingForBinaryInput else { return }
            self.webSocket.sendText(.volumeUp())
            Task { @MainActor in
                self.transcript.appendSystemMessage("▲ Answered: YES")
                self.stopBinaryInputCapture()
            }
        }

        hardwareInput.onVolumeDown = { [weak self] in
            guard let self = self, self.isWaitingForBinaryInput else { return }
            self.webSocket.sendText(.volumeDown())
            Task { @MainActor in
                self.transcript.appendSystemMessage("▼ Answered: NO")
                self.stopBinaryInputCapture()
            }
        }
    }

    private func stopBinaryInputCapture() {
        isWaitingForBinaryInput = false
        binaryInputTimeoutTask?.cancel()
        binaryInputTimeoutTask = nil
        hardwareInput.stopVolumeInterception()
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
            
        case "REQUEST_CAMERA_PREVIEW":
            self.shouldShowCameraPreview = true
            transcript.appendSystemMessage("📷 Camera ready. Pull away from ear to snap.")
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()

        case "FETCH_LOCATION":
            self.shareLocation()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            
        case "REQUEST_BINARY_INPUT":
            self.isWaitingForBinaryInput = true
            self.hardwareInput.startVolumeInterception()
            transcript.appendSystemMessage("⏱ Volume override active for Yes/No answer")
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 1.0)
            
            // Revert after 15 seconds if they don't answer
            binaryInputTimeoutTask?.cancel()
            binaryInputTimeoutTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { return }
                self?.stopBinaryInputCapture()
                self?.transcript.appendSystemMessage("⏱ Volume override expired")
            }
            
        case "COPY_TO_CLIPBOARD":
            if let text = payload["text"] as? String {
                UIPasteboard.general.string = text
                transcript.appendSystemMessage("📋 Copied to clipboard")
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            
        case "OPEN_URL":
            if let urlString = payload["url"] as? String, let url = URL(string: urlString) {
                transcript.appendSystemMessage("🔗 Opening link...")
                UIApplication.shared.open(url)
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
            
        case "SET_REMINDER":
            if let message = payload["message"] as? String, let timeIso = payload["time_iso"] as? String {
                Task {
                    let success = await notificationService.scheduleReminder(message: message, at: timeIso)
                    if success {
                        transcript.appendSystemMessage("⏰ Reminder set: \(message)")
                        await MainActor.run {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        }
                    } else {
                        transcript.appendSystemMessage("⚠️ Failed to set reminder (check permissions)")
                        await MainActor.run {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                    }
                }
            }

        default:
            transcript.appendSystemMessage("[\(type)]")
        }
    }

    func dismissTimer(_ timer: ActiveTimer) {
        Task {
            await timerService.cancelTimer(id: timer.id)
            activeTimers.removeAll { $0.id == timer.id }
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

    func captureAndSendFrame() {
        // Reset the flag immediately so we only take one photo per request
        shouldShowCameraPreview = false
        
        camera.captureFrame { [weak self] jpegData in
            guard let self, let data = jpegData else { return }
            let base64 = data.base64EncodedString()
            self.webSocket.sendText(.image(base64Data: base64))
            Task { @MainActor in
                self.transcript.appendSystemMessage("📸 Sent photo")
            }
        }
    }
}
