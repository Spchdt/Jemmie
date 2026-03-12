import SwiftUI

struct CallButton: View {
    let isActive: Bool
    let isConnecting: Bool
    let action: () -> Void

    @State private var pulseScale: Double = 1.0

    private var buttonLabel: String {
        if isActive { "End Call" } else { "Start Call" }
    }

    var body: some View {
        Button(buttonLabel, systemImage: isActive ? "phone.down.fill" : "phone.fill", action: action)
            .labelStyle(CallButtonLabelStyle(isActive: isActive, pulseScale: pulseScale))
            .disabled(isConnecting)
            .opacity(isConnecting ? 0.6 : 1.0)
            .onChange(of: isActive) { _, active in
                pulseScale = active ? Design.Animation.pulseScale : 1.0
            }
            .onAppear {
                if isActive {
                    pulseScale = Design.Animation.pulseScale
                }
            }
            .accessibilityLabel(buttonLabel)
    }
}

struct CallButtonLabelStyle: LabelStyle {
    let isActive: Bool
    let pulseScale: Double

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            if isActive {
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 3)
                    .frame(width: Design.Size.callButtonRingDiameter, height: Design.Size.callButtonRingDiameter)
                    .scaleEffect(pulseScale)
                    .opacity(2 - pulseScale)
                    .animation(
                        .easeInOut(duration: Design.Animation.callPulseDuration)
                            .repeatForever(autoreverses: false),
                        value: pulseScale
                    )
            }

            Circle()
                .fill(isActive ? Color.red : Color.green)
                .frame(width: Design.Size.callButtonDiameter, height: Design.Size.callButtonDiameter)
                .shadow(color: (isActive ? Color.red : Color.green).opacity(0.4), radius: 12)

            configuration.icon
                .font(.system(size: Design.Size.callButtonIconSize, weight: .semibold))
                .foregroundStyle(.white)
                .rotationEffect(isActive ? .degrees(135) : .zero)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        CallButton(isActive: false, isConnecting: false) {}
        CallButton(isActive: true, isConnecting: false) {}
    }
    .padding()
    .background(.black)
}
