import SwiftUI

struct CallButton: View {
    let isActive: Bool
    let isConnecting: Bool
    let action: () -> Void

    private var buttonLabel: String {
        if isActive { "End" } else { "Call" }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isActive ? Color.red : Color.green)
                        .frame(width: Design.Size.callButtonDiameter, height: Design.Size.callButtonDiameter)

                    Image(systemName: isActive ? "phone.down.fill" : "phone.fill")
                        .font(.system(size: Design.Size.callButtonIconSize, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(buttonLabel)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .disabled(isConnecting)
        .opacity(isConnecting ? 0.6 : 1.0)
        .accessibilityLabel(buttonLabel)
    }
}

#Preview {
    HStack(spacing: 40) {
        CallButton(isActive: false, isConnecting: false) {}
        CallButton(isActive: true, isConnecting: false) {}
    }
    .padding()
    .background(Color.CallScreen.gradientTop)
}
