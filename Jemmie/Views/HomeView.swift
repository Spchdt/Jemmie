import SwiftUI

struct HomeView: View {
    @State private var viewModel = CallViewModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.jemmieBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .accessibilityHidden(true)

            VStack(spacing: 0) {
                TopBarView(callState: viewModel.callState)
                    .padding(.top, Design.Layout.topPadding)

                Spacer()

                AgentOrbView(
                    isConnected: viewModel.callState.isConnected,
                    isSpeaking: viewModel.isAgentSpeaking
                )
                .padding(.bottom, Design.Spacing.large)

                StatusBadge(state: viewModel.callState)
                    .padding(.bottom, Design.Spacing.medium)

                TranscriptView(transcript: viewModel.transcript)
                    .frame(maxHeight: Design.Layout.transcriptMaxHeight)
                    .mask(
                        LinearGradient(
                            colors: [.clear, .white, .white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .accessibilityHidden(true)
                    .padding(.bottom, Design.Spacing.medium)

                Spacer()

                BottomControlsView(
                    isMuted: viewModel.isMuted,
                    isSpeakerOn: viewModel.isSpeakerOn,
                    isCameraEnabled: viewModel.isCameraEnabled,
                    isConnected: viewModel.callState.isConnected,
                    isConnecting: viewModel.callState == .connecting,
                    onToggleMute: viewModel.toggleMute,
                    onToggleSpeaker: viewModel.toggleSpeaker,
                    onToggleCall: handleCallToggle,
                    onToggleCamera: viewModel.toggleCamera
                )
                .padding(.bottom, Design.Spacing.extraLarge)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func handleCallToggle() {
        if viewModel.callState.isConnected {
            viewModel.endCall()
        } else if viewModel.callState == .idle {
            viewModel.startCall()
        }
    }
}

#Preview {
    HomeView()
}
