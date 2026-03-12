import AVFoundation

@Observable
@MainActor
final class AudioEngine {
    private(set) var isRunning = false
    var isMuted = false

    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var playbackFormat: AVAudioFormat?

    var onCapturedAudio: ((Data) -> Void)?

    private let captureSampleRate: Double = 16000
    private let playbackSampleRate: Double = 24000

    // MARK: - Public API

    /// Start the audio engine. MUST only be called after CallKit's didActivate callback.
    func start() {
        guard !isRunning else { return }

        let engine = AVAudioEngine()
        self.engine = engine

        let player = AVAudioPlayerNode()
        self.playerNode = player
        engine.attach(player)

        playbackFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: playbackSampleRate,
            channels: 1,
            interleaved: true
        )
        if let fmt = playbackFormat {
            engine.connect(player, to: engine.mainMixerNode, format: fmt)
        }

        let inputNode = engine.inputNode
        let hwFormat = inputNode.outputFormat(forBus: 0)

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: captureSampleRate,
            channels: 1,
            interleaved: true
        ) else {
            print("🚨 [AudioEngine] CRITICAL: Failed to create target AVAudioFormat (16kHz PCM). Check device audio capabilities.")
            return
        }

        guard let converter = AVAudioConverter(from: hwFormat, to: targetFormat) else {
            print("🚨 [AudioEngine] CRITICAL: Failed to create AVAudioConverter from \(hwFormat.sampleRate)Hz to 16kHz.")
            return
        }

        let bufferSize = UInt32(captureSampleRate * AppConfig.audioChunkDuration)
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: hwFormat) { [weak self] buffer, _ in
            guard let self, !self.isMuted else { return }

            let frameCount = UInt32(Double(buffer.frameLength) * targetFormat.sampleRate / hwFormat.sampleRate)
            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCount) else {
                return
            }

            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            if status == .haveData, let data = convertedBuffer.toData() {
                self.onCapturedAudio?(data)
            }
        }

        do {
            try engine.start()
            player.play()
            isRunning = true
            applySpeakerRoute()
            print("🎙️ [AudioEngine] Started tracking microphone inputs (capture: \(captureSampleRate)Hz, playback: \(playbackSampleRate)Hz)")
        } catch {
            print("🚨 [AudioEngine] CRITICAL: Engine start failed - \(error.localizedDescription). Did the user grant Microphone permissions?")
        }
    }

    func stop() {
        engine?.inputNode.removeTap(onBus: 0)
        playerNode?.stop()
        engine?.stop()
        engine = nil
        playerNode = nil
        isRunning = false
        print("[AudioEngine] Stopped")
    }

    func playAudio(_ data: Data) {
        guard let player = playerNode else { return }
        guard let buffer = data.toPCMBuffer(sampleRate: playbackSampleRate) else { return }
        player.scheduleBuffer(buffer, completionHandler: nil)
    }

    func flushPlayback() {
        playerNode?.stop()
        playerNode?.play()
    }

    var isSpeakerOn = false

    func toggleMute() {
        isMuted.toggle()
    }

    func toggleSpeaker() {
        isSpeakerOn.toggle()
        applySpeakerRoute()
    }

    /// Apply the current speaker preference by reconfiguring the audio session category.
    /// Unlike overrideOutputAudioPort (which is temporary and resets on any route change),
    /// setting the category options is persistent.
    func applySpeakerRoute() {
        let session = AVAudioSession.sharedInstance()
        do {
            var opts: AVAudioSession.CategoryOptions = [.allowBluetooth]
            if isSpeakerOn {
                opts.insert(.defaultToSpeaker)
            }
            try session.setCategory(.playAndRecord, mode: .default, options: opts)
            print("[AudioEngine] Route set to \(isSpeakerOn ? "speaker" : "receiver")")
        } catch {
            print("[AudioEngine] Failed to set speaker route: \(error)")
        }
    }
}
