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
        } icon: {
            Circle()
                .fill(dotColor)
                .frame(width: Design.Size.statusDot, height: Design.Size.statusDot)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, Design.Spacing.small)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityLabel("Connection status: \(state.displayText)")
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
    .background(.black)
}
