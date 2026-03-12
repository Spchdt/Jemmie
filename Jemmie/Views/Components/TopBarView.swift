import SwiftUI

struct TopBarView: View {
    let callState: CallState

    var body: some View {
        HStack {
            Text("Jemmie")
                .font(.title3)
                .bold()
                .foregroundStyle(.white)

            Spacer()

            if callState.isConnected {
                Text(callState.displayText)
                    .font(.callout)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, Design.Layout.horizontalPadding)
    }
}

#Preview {
    TopBarView(callState: .active)
        .background(.black)
}
