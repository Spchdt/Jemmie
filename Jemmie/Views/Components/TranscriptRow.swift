import SwiftUI

struct TranscriptRow: View {
    let entry: TranscriptEntry

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(entry.speaker.label)
                .font(.caption)
                .bold()
                .foregroundStyle(entry.speaker.color)
                .frame(width: 50, alignment: .trailing)

            Text(entry.text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.speaker.label) said: \(entry.text)")
    }
}

#Preview {
    VStack {
        TranscriptRow(entry: TranscriptEntry(speaker: .user, text: "What's the weather?"))
        TranscriptRow(entry: TranscriptEntry(speaker: .agent, text: "It's sunny and 72°F."))
        TranscriptRow(entry: TranscriptEntry(speaker: .system, text: "📸 Sent camera frame"))
    }
    .padding()
    .background(.black)
}
