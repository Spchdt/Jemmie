import SwiftUI

struct BottomControlsView: View {
    let isMuted: Bool
    let isSpeakerOn: Bool
    let isConnected: Bool
    let isConnecting: Bool
    let showLog: Bool
    let onToggleMute: () -> Void
    let onToggleCall: () -> Void
    let onToggleSpeaker: () -> Void
    let onToggleLog: () -> Void
    let onShowHelp: () -> Void
    let onShowSettings: () -> Void

    var body: some View {
        VStack(spacing: Design.Layout.gridRowSpacing) {
            // Row 1: Mute, Speaker, Log
            HStack(spacing: Design.Layout.gridColumnSpacing) {
                ControlButton(
                    title: isMuted ? "Unmute" : "Mute",
                    systemImage: isMuted ? "mic.slash.fill" : "mic.fill",
                    isActive: isMuted,
                    isEnabled: isConnected,
                    action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onToggleMute()
                    }
                )

                ControlButton(
                    title: "Speaker",
                    systemImage: isSpeakerOn ? "speaker.wave.3.fill" : "speaker",
                    isActive: isSpeakerOn,
                    isEnabled: isConnected,
                    action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        onToggleSpeaker()
                    }
                )

                ControlButton(
                    title: "Log",
                    systemImage: showLog ? "text.bubble.fill" : "text.bubble",
                    isActive: showLog,
                    isEnabled: true,
                    action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            onToggleLog()
                        }
                    }
                )
            }

            // Row 2: Help, Call, About
            HStack(spacing: Design.Layout.gridColumnSpacing) {
                ControlButton(
                    title: "Help",
                    systemImage: "questionmark.circle.fill",
                    isActive: false,
                    isEnabled: true,
                    action: {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        onShowHelp()
                    }
                )

                CallButton(
                    isActive: isConnected,
                    isConnecting: isConnecting,
                    action: {
                        let style: UIImpactFeedbackGenerator.FeedbackStyle = isConnected ? .heavy : .medium
                        UIImpactFeedbackGenerator(style: style).impactOccurred()
                        onToggleCall()
                    }
                )

                ControlButton(
                    title: "About",
                    systemImage: "info.circle.fill",
                    isActive: false,
                    isEnabled: true,
                    action: {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        onShowSettings()
                    }
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
        isSpeakerOn: false,
        isConnected: true,
        isConnecting: false,
        showLog: false,
        onToggleMute: {},
        onToggleCall: {},
        onToggleSpeaker: {},
        onToggleLog: {},
        onShowHelp: {},
        onShowSettings: {}
    )
    .padding()
    .background(Color.CallScreen.gradientBottom)
}
