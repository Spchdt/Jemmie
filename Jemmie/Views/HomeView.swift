import SwiftUI

struct HomeView: View {
    @State private var viewModel = CallViewModel()
    @State private var showLog = false
    @State private var showHelp = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            ZStack {
                LinearGradient(
                    colors: [Color.mint.opacity(0.7), Color.cyan.opacity(0.7), Color.mint.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Color.black.opacity(0.6)
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)

            VStack(spacing: 0) {
                // Status indicator above name
                StatusBadge(state: viewModel.callState, callDuration: viewModel.callDuration)
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
                    isSpeakerOn: viewModel.isSpeakerOn,
                    isConnected: viewModel.callState.isConnected,
                    isConnecting: viewModel.callState == .connecting,
                    showLog: showLog,
                    onToggleMute: viewModel.toggleMute,
                    onToggleCall: handleCallToggle,
                    onToggleSpeaker: viewModel.toggleSpeaker,
                    onToggleLog: { showLog.toggle() },
                    onShowHelp: { showHelp = true },
                    onShowSettings: { showSettings = true }
                )
                .padding(.bottom, Design.Spacing.extraLarge)
            }
            
            if viewModel.shouldShowCameraPreview {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: Design.Spacing.large) {
                    Text("Snap a Photo")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let session = viewModel.camera.captureSession {
                        CameraPreviewView(session: session)
                            .frame(width: 300, height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.black)
                            .frame(width: 300, height: 300)
                            .overlay(ProgressView().tint(.white))
                    }
                    
                    HStack(spacing: Design.Spacing.large) {
                        Button("Cancel") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.dismissCameraPreview()
                            }
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .modifier(GlassButtonModifier(isProminent: false))
                        
                        Button("Snap") {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.captureAndSendFrame()
                            }
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .modifier(GlassButtonModifier(isProminent: true))
                    }
                }
                .padding(Design.Spacing.large)
                .modifier(CameraPopupGlassModifier())
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.shouldShowCameraPreview)
    }

    private func handleCallToggle() {
        if viewModel.callState.isConnected {
            viewModel.endCall()
        } else if viewModel.callState == .idle {
            viewModel.startCall()
        }
    }
}

private struct CameraPopupGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(
                    .regular.tint(.white.opacity(0.15)),
                    in: .rect(cornerRadius: 36, style: .continuous)
                )
        } else {
            content
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        }
    }
}

private struct GlassButtonModifier: ViewModifier {
    let isProminent: Bool
    
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            if isProminent {
                content.glassEffect(.regular.tint(.white).interactive(), in: .capsule)
            } else {
                content.glassEffect(.regular.tint(.white.opacity(0.15)).interactive(), in: .capsule)
            }
        } else {
            if isProminent {
                content
                    .background(Color.white)
                    .clipShape(Capsule())
            } else {
                content
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    HomeView()
}
