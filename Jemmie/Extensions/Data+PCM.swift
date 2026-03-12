import AVFoundation

extension Data {
    /// Create an AVAudioPCMBuffer from raw PCM bytes.
    /// - Parameters:
    ///   - sampleRate: Sample rate (e.g. 24000 for server playback)
    ///   - channels: Number of channels (1 for mono)
    /// - Returns: A filled AVAudioPCMBuffer, or nil on failure
    func toPCMBuffer(sampleRate: Double, channels: UInt32 = 1) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: true
        ) else { return nil }

        let frameCount = UInt32(count / (2 * Int(channels))) // 16-bit = 2 bytes per sample
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let int16Data = buffer.int16ChannelData else { return nil }
        self.withUnsafeBytes { rawPtr in
            guard let src = rawPtr.baseAddress else { return }
            int16Data[0].update(from: src.assumingMemoryBound(to: Int16.self), count: Int(frameCount))
        }

        return buffer
    }
}

extension AVAudioPCMBuffer {
    /// Convert buffer to raw PCM Data (16-bit signed, little-endian).
    func toData() -> Data? {
        guard let int16Data = int16ChannelData else { return nil }
        let count = Int(frameLength)
        return Data(bytes: int16Data[0], count: count * MemoryLayout<Int16>.size)
    }
}
