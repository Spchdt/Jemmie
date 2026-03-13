import SwiftUI

struct BottomControlsView: View {
    let isMuted: Bool
    let isCameraEnabled: Bool
    let isConnected: Bool
    let isConnecting: Bool
    let showLog: Bool
    let onToggleMute: () -> Void
    let onToggleCall: () -> Void
    let onToggleCamera: () -> Void
    let onToggleLog: () -> Void
    let onShowHelp: () -> Void
    let onShowSettings: () -> Void

    var body: some View {
        VStack(spacing: Design.Layout.gridRowSpacing) {
            // Row 1: Mute, Camera, Log
            HStack(spacing: Design.Layout.gridColumnSpacing) {
                ControlButton(
                    title: isMuted ? "Unmute" : "Mute",
                    systemImage: isMuted ? "mic.slash.fill" : "mic.fill",
                    isActive: isMuted,
                    isEnabled: isConnected,
                    action: onToggleMute
                )

                ControlButton(
                    title: "Camera",
                    systemImage: isCameraEnabled ? "camera.fill" : "camera",
                    isActive: isCameraEnabled,
                    isEnabled: isConnected,
                    action: onToggleCamera
                )

                ControlButton(
                    title: "Log",
                    systemImage: showLog ? "text.bubble.fill" : "text.bubble",
                    isActive: showLog,
                    isEnabled: true,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            onToggleLog()
                        }
                    }
                )
            }

            // Row 2: Help, Call, Settings
            HStack(spacing: Design.Layout.gridColumnSpacing) {
                ControlButton(
                    title: "Help",
                    systemImage: "questionmark.circle.fill",
                    isActive: false,
                    isEnabled: true,
                    action: onShowHelp
                )

                CallButton(
                    isActive: isConnected,
                    isConnecting: isConnecting,
                    action: onToggleCall
                )

                ControlButton(
                    title: "Settings",
                    systemImage: "gearshape.fill",
                    isActive: false,
                    isEnabled: true,
                    action: onShowSettings
                )
            }
        }
        .modifier(ControlsGlassContainerModifier())
    }
}

private struct ControlsGlassContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            GlassEffectContainer {
                content
            }
        } else {
            content
        }
    }
}

#Preview {
    BottomControlsView(
        isMuted: false,
        isCameraEnabled: false,
        isConnected: true,
        isConnecting: false,
        showLog: false,
        onToggleMute: {},
        onToggleCall: {},
        onToggleCamera: {},
        onToggleLog: {},
        onShowHelp: {},
        onShowSettings: {}
    )
    .padding()
    .background(Color.CallScreen.gradientBottom)
}
