import Foundation
import CallKit
import AVFoundation

@Observable
@MainActor
final class CallManager: NSObject {
    static let shared = CallManager()

    private(set) var callState: CallState = .idle

    private let provider: CXProvider
    private let callController = CXCallController()
    private var activeCallUUID: UUID?

    // Callbacks
    var onCallStarted: (() -> Void)?
    var onAudioActivated: (() -> Void)?
    var onCallEnded: (() -> Void)?
    var onStateChanged: ((CallState) -> Void)?


    private override init() {
        let config = CXProviderConfiguration()
        config.maximumCallGroups = 1
        config.maximumCallsPerCallGroup = 1
        config.supportsVideo = false
        config.supportedHandleTypes = [.generic]

        provider = CXProvider(configuration: config)
        super.init()
        provider.setDelegate(self, queue: .main)
    }

    // MARK: - Public API

    func startCall() {
        guard callState == .idle else { return }
        
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self = self else { return }
            guard granted else {
                print("[CallManager] Microphone permission denied")
                Task { @MainActor in
                    self.updateState(.error("Microphone permission required"))
                }
                return
            }
            
            Task { @MainActor in
                let uuid = UUID()
                self.activeCallUUID = uuid
                self.updateState(.connecting)

                let handle = CXHandle(type: .generic, value: "Jemmie")
                let action = CXStartCallAction(call: uuid, handle: handle)
                action.isVideo = false

                let transaction = CXTransaction(action: action)
                self.callController.request(transaction) { error in
                    if let error {
                        print("[CallManager] Start call failed: \(error.localizedDescription)")
                        Task { @MainActor in
                            self.updateState(.error(error.localizedDescription))
                            self.activeCallUUID = nil
                        }
                    }
                }
            }
        }
    }

    func endCall() {
        guard let uuid = activeCallUUID else { return }
        updateState(.ending)

        let action = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: action)
        callController.request(transaction) { error in
            if let error {
                print("[CallManager] End call failed: \(error.localizedDescription)")
            }
        }
    }

    func markCallConnected() {
        guard let uuid = activeCallUUID else { return }
        provider.reportOutgoingCall(with: uuid, connectedAt: .now)
        updateState(.active)
    }

    // MARK: - State

    private func updateState(_ state: CallState) {
        callState = state
        onStateChanged?(state)
    }
}

// MARK: - CXProviderDelegate

extension CallManager: CXProviderDelegate {
    nonisolated func providerDidReset(_ provider: CXProvider) {
        print("[CallManager] Provider did reset")
        Task { @MainActor in
            activeCallUUID = nil
            updateState(.idle)
            onCallEnded?()
        }
    }

    nonisolated func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("[CallManager] Performing start call action")

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth])
        } catch {
            print("[CallManager] Audio session error: \(error)")
        }

        Task { @MainActor in
            onCallStarted?()
        }

        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: .now)
        action.fulfill()
    }

    nonisolated func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("[CallManager] Performing end call action")
        Task { @MainActor in
            activeCallUUID = nil
            updateState(.idle)
            onCallEnded?()
        }
        action.fulfill()
    }

    nonisolated func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("[CallManager] Audio session activated")
        Task { @MainActor in
            onAudioActivated?()
        }
    }

    nonisolated func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("[CallManager] Audio session deactivated")
    }

    nonisolated func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        action.fulfill()
    }
}
