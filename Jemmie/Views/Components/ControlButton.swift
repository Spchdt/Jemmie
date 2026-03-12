import SwiftUI

struct ControlButton: View {
    let title: String
    let systemImage: String
    let isActive: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(title, systemImage: systemImage, action: action)
            .labelStyle(VerticalControlLabelStyle(isActive: isActive))
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1.0 : 0.4)
    }
}

struct VerticalControlLabelStyle: LabelStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: Design.Spacing.small) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
                    .frame(width: Design.Size.controlButtonDiameter, height: Design.Size.controlButtonDiameter)

                configuration.icon
                    .font(.system(size: Design.Size.controlIconSize))
                    .foregroundStyle(isActive ? .white : .gray)
            }

            configuration.title
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        ControlButton(title: "Mute", systemImage: "mic.fill", isActive: false, isEnabled: true) {}
        ControlButton(title: "Camera", systemImage: "camera.fill", isActive: true, isEnabled: true) {}
        ControlButton(title: "Mute", systemImage: "mic.slash.fill", isActive: false, isEnabled: false) {}
    }
    .padding()
    .background(.black)
}
