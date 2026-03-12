import SwiftUI

struct TranscriptView: View {
    var transcript: TranscriptViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(transcript.entries) { entry in
                        TranscriptRow(entry: entry)
                            .id(entry.id)
                    }
                }
                .padding(.horizontal, Design.Spacing.medium)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .onChange(of: transcript.entries.count) { _, _ in
                if let lastId = transcript.entries.last?.id {
                    withAnimation(.easeOut(duration: Design.Animation.scrollDuration)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }
}

#Preview {
    let vm = TranscriptViewModel()
    vm.appendUserSpeech("What's the weather like?")
    vm.appendAgentSpeech("It's currently 72°F and sunny.")
    vm.appendSystemMessage("📸 Sent camera frame")

    return TranscriptView(transcript: vm)
        .frame(height: 300)
        .background(.black)
}
