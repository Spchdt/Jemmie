import SwiftUI

struct TranscriptRow: View {
    let entry: TranscriptEntry

    private var isUser: Bool { entry.speaker == .user }
    private var isSystem: Bool { entry.speaker == .system }

    var body: some View {
        if isSystem {
            systemRow
        } else {
            chatBubbleRow
        }
    }

    private var chatBubbleRow: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 2) {
                if !isUser {
                    Text(entry.speaker.label)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.leading, 4)
                }

                Text(entry.text)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .modifier(BubbleGlassModifier(
                        isUser: isUser,
                        backgroundColor: isUser
                            ? Color.CallScreen.bubbleUser
                            : Color.CallScreen.bubbleAgent
                    ))
            }

            if !isUser { Spacer(minLength: 48) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.speaker.label) said: \(entry.text)")
    }

    private var systemRow: some View {
        HStack {
            Spacer()
            Text(entry.text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .modifier(BubbleGlassModifier(
                    isUser: false,
                    backgroundColor: Color.CallScreen.bubbleSystem
                ))
            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("System: \(entry.text)")
    }
}

private struct BubbleGlassModifier: ViewModifier {
    let isUser: Bool
    let backgroundColor: Color

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: 18))
        } else {
            content
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: 18))
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        TranscriptRow(entry: TranscriptEntry(speaker: .agent, text: "Hi, how can I help you today?"))
        TranscriptRow(entry: TranscriptEntry(speaker: .user, text: "What's the weather?"))
        TranscriptRow(entry: TranscriptEntry(speaker: .agent, text: "It's sunny and 72°F in your area."))
        TranscriptRow(entry: TranscriptEntry(speaker: .system, text: "📸 Sent camera frame"))
    }
    .padding()
    .background(Color.CallScreen.gradientTop)
}
