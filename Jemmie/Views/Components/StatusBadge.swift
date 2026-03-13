import SwiftUI

struct StatusBadge: View {
    let state: CallState
    var callDuration: TimeInterval? = nil

    private var dotColor: Color {
        switch state {
        case .active: .green
        case .connecting, .reconnecting: .orange
        case .error: .red
        case .ending: .yellow
        case .idle: .gray
        }
    }

    private var formattedDuration: String? {
        guard let duration = callDuration, state == .active else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        Label {
            HStack(spacing: 4) {
                Text(state.displayText)
                    .layoutPriority(1)
                
                if let durationStr = formattedDuration {
                    HStack(spacing: 4) {
                        Text("-")
                            .foregroundStyle(.white.opacity(0.8))
                        Text(durationStr)
                            .monospacedDigit()
                            .contentTransition(.numericText(countsDown: false))
                    }
                    .transition(.blurReplace.combined(with: .push(from: .trailing)))
                }
            }
            .font(.callout)
            .bold()
            .foregroundStyle(.white.opacity(0.9))
        } icon: {
            Circle()
                .fill(dotColor)
                .frame(width: Design.Size.statusDot, height: Design.Size.statusDot)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .modifier(GlassCapsuleModifier())
        .clipShape(Capsule())
        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.1), value: formattedDuration != nil)
        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.1), value: state)
        .animation(.default, value: callDuration)
        .accessibilityLabel("Connection status: \(state.displayText)")
    }
}

private struct GlassCapsuleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(.regular, in: .capsule)
        } else {
            content.background(.ultraThinMaterial, in: Capsule())
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusBadge(state: .idle)
        StatusBadge(state: .connecting)
        StatusBadge(state: .active, callDuration: 125)
        StatusBadge(state: .error("Connection lost"))
    }
    .padding()
    .background(Color.CallScreen.gradientTop)
}
