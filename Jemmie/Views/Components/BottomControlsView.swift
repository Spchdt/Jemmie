import SwiftUI

struct BottomControlsView: View {
    let isMuted: Bool
    let isSpeakerOn: Bool
    let isCameraEnabled: Bool
    let isConnected: Bool
    let isConnecting: Bool
    let onToggleMute: () -> Void
    let onToggleSpeaker: () -> Void
    let onToggleCall: () -> Void
    let onToggleCamera: () -> Void

    var body: some View {
        HStack(spacing: Design.Spacing.controlGap) {
            ControlButton(
                title: isMuted ? "Unmute" : "Mute",
                systemImage: isMuted ? "mic.slash.fill" : "mic.fill",
                isActive: isMuted,
                isEnabled: isConnected,
                action: onToggleMute
            )

            ControlButton(
                title: "Speaker",
                systemImage: isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill",
                isActive: isSpeakerOn,
                isEnabled: isConnected,
                action: onToggleSpeaker
            )

            CallButton(
                isActive: isConnected,
                isConnecting: isConnecting,
                action: onToggleCall
            )

            ControlButton(
                title: "Camera",
                systemImage: isCameraEnabled ? "camera.fill" : "camera",
                isActive: isCameraEnabled,
                isEnabled: isConnected,
                action: onToggleCamera
            )
        }
    }
}

#Preview {
    BottomControlsView(
        isMuted: false,
        isSpeakerOn: false,
        isCameraEnabled: false,
        isConnected: true,
        isConnecting: false,
        onToggleMute: {},
        onToggleSpeaker: {},
        onToggleCall: {},
        onToggleCamera: {}
    )
    .padding()
    .background(.black)
}
