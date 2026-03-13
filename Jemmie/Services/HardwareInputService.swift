import Foundation
import CoreMotion
import UIKit
import MediaPlayer
import AVFoundation

@Observable
@MainActor
final class HardwareInputService {
    private(set) var isProximityNear = false

    private var volumeObservation: NSKeyValueObservation?
    private var previousVolume: Float = 0
    private var volumeView: MPVolumeView?

    // Callbacks
    var onProximityAway: (() -> Void)?
    var onVolumeUp: (() -> Void)?
    var onVolumeDown: (() -> Void)?

    // MARK: - Public API

    func startAll() {
        startProximityMonitoring()
    }

    func stopAll() {
        stopProximityMonitoring()
        stopVolumeInterception()
    }

    // MARK: - Proximity Sensor

    private func startProximityMonitoring() {
        let device = UIDevice.current
        device.isProximityMonitoringEnabled = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(proximityChanged),
            name: UIDevice.proximityStateDidChangeNotification,
            object: device
        )
    }

    private func stopProximityMonitoring() {
        UIDevice.current.isProximityMonitoringEnabled = false
        NotificationCenter.default.removeObserver(
            self,
            name: UIDevice.proximityStateDidChangeNotification,
            object: nil
        )
    }

    @objc private func proximityChanged() {
        let isNear = UIDevice.current.proximityState
        let wasNear = isProximityNear
        isProximityNear = isNear

        if wasNear && !isNear {
            print("[Hardware] Proximity: pulled from ear → triggering callback")
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(AppConfig.proximityCaptureDelay))
                self?.onProximityAway?()
            }
        }
    }

    // MARK: - Volume Button Interception

    func startVolumeInterception() {
        guard volumeObservation == nil else { return }
        let volumeView = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
        volumeView.isHidden = false
        self.volumeView = volumeView

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(volumeView)
        }

        let audioSession = AVAudioSession.sharedInstance()
        previousVolume = audioSession.outputVolume

        volumeObservation = audioSession.observe(\.outputVolume, options: [.new, .old]) { [weak self] _, change in
            guard let self,
                  let newVolume = change.newValue,
                  let oldVolume = change.oldValue else { return }

            let delta = newVolume - oldVolume
            guard abs(delta) > 0.001 else { return }

            Task { @MainActor in
                if delta > 0 {
                    print("[Hardware] Volume UP pressed")
                    self.onVolumeUp?()
                } else {
                    print("[Hardware] Volume DOWN pressed")
                    self.onVolumeDown?()
                }
            }

            self.resetVolume(to: 0.5)
        }

        resetVolume(to: 0.5)
    }

    func stopVolumeInterception() {
        volumeObservation?.invalidate()
        volumeObservation = nil
        volumeView?.removeFromSuperview()
        volumeView = nil
    }

    private func resetVolume(to value: Float) {
        guard let slider = volumeView?.subviews.compactMap({ $0 as? UISlider }).first else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            slider.value = value
        }
    }
}
