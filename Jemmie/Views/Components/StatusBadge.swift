import SwiftUI

struct StatusBadge: View {
    let state: CallState

    private var dotColor: Color {
        switch state {
        case .active: .green
        case .connecting, .reconnecting: .orange
        case .error: .red
        case .ending: .yellow
        case .idle: .gray
        }
    }

    var body: some View {
        Label {
            Text(state.displayText)
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
        StatusBadge(state: .active)
        StatusBadge(state: .error("Connection lost"))
    }
    .padding()
    .background(Color.CallScreen.gradientTop)
}
