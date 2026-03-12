import SwiftUI

struct HomeView: View {
    @State private var viewModel = CallViewModel()
    @State private var showLog = false

    var body: some View {
        ZStack {
            ZStack {
                LinearGradient(
                    colors: [Color.cyan.opacity(0.7), Color.mint.opacity(0.7), Color.cyan.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Color.black.opacity(0.7)
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)

            VStack(spacing: 0) {
                // Status indicator above name
                StatusBadge(state: viewModel.callState)
                    .padding(.top, Design.Layout.topPadding)

                // Caller-ID style header
                TopBarView(
                    callState: viewModel.callState,
                    callDuration: viewModel.callDuration
                )
                .padding(.top, Design.Spacing.small)

                Spacer()

                // Timers
                if !viewModel.activeTimers.isEmpty {
                    ActiveTimersOverlay(
                        timers: viewModel.activeTimers,
                        onDismiss: viewModel.dismissTimer
                    )
                    .padding(.horizontal, Design.Layout.horizontalPadding)
                    .padding(.bottom, Design.Spacing.small)
                }

                // Transcript chat bubbles
                if showLog {
                    TranscriptView(transcript: viewModel.transcript)
                        .frame(maxHeight: Design.Layout.transcriptMaxHeight)
                        .mask(
                            LinearGradient(
                                colors: [.clear, .white, .white],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(.bottom, Design.Spacing.medium)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                // Bottom: Apple-style 3-column grid
                BottomControlsView(
                    isMuted: viewModel.isMuted,
                    isCameraEnabled: viewModel.isCameraEnabled,
                    isConnected: viewModel.callState.isConnected,
                    isConnecting: viewModel.callState == .connecting,
                    showLog: showLog,
                    onToggleMute: viewModel.toggleMute,
                    onToggleCall: handleCallToggle,
                    onToggleCamera: viewModel.toggleCamera,
                    onToggleLog: { showLog.toggle() }
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
