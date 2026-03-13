import SwiftUI

struct ControlButton: View {
    let title: String
    let systemImage: String
    let isActive: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isActive ? Color.white.opacity(0.25) : Color.white.opacity(0.08))
                        .frame(width: Design.Size.controlButtonDiameter, height: Design.Size.controlButtonDiameter)

                    Image(systemName: systemImage)
                        .font(.system(size: Design.Size.controlIconSize, weight: .medium))
                        .foregroundStyle(isActive ? .white : .white.opacity(0.85))
                }
                .modifier(GlassCircleModifier(isActive: isActive))

                Text(title)
                    .font(.callout)
                    .foregroundStyle(.white)
            }
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.35)
        .accessibilityLabel(title)
    }
}

private struct GlassCircleModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(
                    isActive ? .regular.tint(.white.opacity(0.15)).interactive() : .regular.interactive(),
                    in: .circle
                )
        } else {
            content
        }
    }
}

#Preview {
    HStack(spacing: 36) {
        ControlButton(title: "Mute", systemImage: "mic.fill", isActive: false, isEnabled: true) {}
        ControlButton(title: "Camera", systemImage: "camera.fill", isActive: true, isEnabled: true) {}
        ControlButton(title: "Mute", systemImage: "mic.slash.fill", isActive: false, isEnabled: false) {}
    }
    .padding()
    .background(Color.CallScreen.gradientTop)
}
