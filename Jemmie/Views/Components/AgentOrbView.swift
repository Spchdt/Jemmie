import SwiftUI

struct AgentOrbView: View {
    let isConnected: Bool
    let isSpeaking: Bool

    @State private var orbScale: Double = 1.0

    private var orbColors: [Color] {
        if isConnected {
            [Color.Orb.connectedFillStart, Color.Orb.connectedFillEnd]
        } else {
            [Color.Orb.idleFillStart, Color.Orb.idleFillEnd]
        }
    }

    private var strokeColor: Color {
        isConnected ? Color.Orb.connectedStroke : Color.Orb.idleStroke
    }

    private var iconColor: Color {
        isConnected ? Color.Orb.connectedIcon : Color.Orb.idleIcon
    }

    var body: some View {
        ZStack {
            if isSpeaking {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.Orb.glowActive, Color.clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: Design.Size.orbGlowDiameter, height: Design.Size.orbGlowDiameter)
                    .scaleEffect(orbScale)
                    .animation(
                        .easeInOut(duration: Design.Animation.orbPulseDuration)
                            .repeatForever(autoreverses: true),
                        value: orbScale
                    )
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: orbColors,
                        center: .center,
                        startRadius: 10,
                        endRadius: 60
                    )
                )
                .stroke(strokeColor, lineWidth: 1.5)
                .frame(width: Design.Size.orbDiameter, height: Design.Size.orbDiameter)

            Image(systemName: isConnected ? "waveform" : "phone.fill")
                .font(.system(size: Design.Size.orbIconSize, weight: .light))
                .foregroundStyle(iconColor)
                .symbolEffect(.variableColor, isActive: isSpeaking)
        }
        .onAppear {
            orbScale = Design.Animation.orbScale
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isSpeaking ? "Agent is speaking" : isConnected ? "Connected to agent" : "Agent idle")
    }
}

#Preview {
    VStack(spacing: 40) {
        AgentOrbView(isConnected: false, isSpeaking: false)
        AgentOrbView(isConnected: true, isSpeaking: true)
    }
    .padding()
    .background(.black)
}
