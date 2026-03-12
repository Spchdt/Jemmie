import SwiftUI

struct TopBarView: View {
    let callState: CallState
    let callDuration: TimeInterval

    var body: some View {
        // Centered caller-ID style header
        VStack(spacing: 4) {
            if callState.isConnected {
                Text(formattedDuration)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.green)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            Text("Jemmie")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, callState.isConnected ? 0 : 8)
        .padding(.horizontal, Design.Layout.horizontalPadding)
    }

    private var formattedDuration: String {
        let minutes = Int(callDuration) / 60
        let seconds = Int(callDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    TopBarView(callState: .active, callDuration: 125)
        .background(Color.CallScreen.gradientTop)
}
