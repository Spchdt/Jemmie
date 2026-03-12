import SwiftUI

struct TimerCardView: View {
    let timer: ActiveTimer
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Timer icon with animated ring
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    .frame(width: 36, height: 36)

                Image(systemName: "timer")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.blue)
            }

            // Label + countdown
            VStack(alignment: .leading, spacing: 2) {
                Text(timer.label)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(timer.fireDate, style: .timer)
                    .font(.system(.caption, design: .monospaced, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Close button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.white.opacity(0.1), in: Circle())
            }
            .accessibilityLabel("Dismiss \(timer.label) timer")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .modifier(GlassRoundedRectModifier(cornerRadius: 14))
    }
}

private struct GlassRoundedRectModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
        }
    }
}

/// Stacks multiple timer cards vertically.
struct ActiveTimersOverlay: View {
    let timers: [ActiveTimer]
    let onDismiss: (ActiveTimer) -> Void

    var body: some View {
        VStack(spacing: 8) {
            ForEach(timers) { timer in
                TimerCardView(timer: timer) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        onDismiss(timer)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, Design.Layout.horizontalPadding)
        .animation(.easeInOut(duration: 0.3), value: timers.map(\.id))
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 12) {
            ActiveTimersOverlay(
                timers: [
                    ActiveTimer(
                        id: UUID(),
                        label: "Pasta",
                        duration: 600,
                        fireDate: Date.now.addingTimeInterval(480)
                    ),
                    ActiveTimer(
                        id: UUID(),
                        label: "Laundry",
                        duration: 3600,
                        fireDate: Date.now.addingTimeInterval(2100)
                    )
                ],
                onDismiss: { _ in }
            )
        }
    }
    .preferredColorScheme(.dark)
}
