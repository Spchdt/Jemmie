import SwiftUI

struct TopBarView: View {
    let callState: CallState
    let callDuration: TimeInterval

    var body: some View {
        // Centered caller-ID style header
        VStack(spacing: 4) {
            Text("Jemmie")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.horizontal, Design.Layout.horizontalPadding)
    }
}

#Preview {
    TopBarView(callState: .active, callDuration: 125)
        .background(Color.CallScreen.gradientTop)
}
