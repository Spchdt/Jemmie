# Jemmie

**AI shouldn't feel like a chatbot, it should feel like a friend. Jemmie is a voice-first iOS AI companion powered by Gemini Live. Combining native CallKit, real-time audio streaming, and multimodal vision, we transformed AI from a clunky text box into a natural, empathetic phone call.**

---

## 📖 About the Project

### 💡 What Inspired Us
We recognized a massive paradox in modern technology: Large Language Models are now capable of human-level reasoning and profound empathy, yet the interfaces we use to interact with them are stuck in the past. Today's AI lives in sterile text boxes, requires clunky "push-to-talk" buttons, and enforces rigid, robotic turn-taking. This friction strips away the emotional resonance of the interaction.

Typing limits human expression. We were inspired by the concept of "invisible UI"—technology that fades into the background so the connection can take center stage. We wanted to build something for the **post-text era of AI**: an always-on, highly empathetic companion that feels exactly like picking up a phone call from your best friend. We set out to break the fourth wall, creating an AI that you can interrupt naturally, share your physical environment with, and talk to effortlessly while walking down the street.

### 🛠️ How We Built It
We engineered Jemmie using a true native, voice-first architecture designed to minimize latency and maximize human immersion.

*   **Native iOS Frontend:** We built a high-performance Swift application that completely bypasses standard UI text paradigms. We natively integrated **Apple's CallKit**, meaning Jemmie triggers the actual iPhone lock-screen phone interface. To the OS, talking to Jemmie *is* a standard VoIP phone call.
*   **Zero-Latency Audio Engine:** We utilized `AVFoundation` to tap the microphone’s input nodes, capturing raw 16-bit PCM audio chunks and streaming them out seamlessly.
*   **Multimodal Live Backend:** Our native app talks to a Python/FastAPI async gateway via bidirectional WebSockets. This gateway acts as the bridge to the **Gemini Live API** (`StreamingMode.BIDI`). Because we stream raw audio buffers bidirectionally—without waiting for intermediate Speech-to-Text (STT) or Text-to-Speech (TTS) layers—the response times are staggering.
*   **Vision & Environment:** We didn't stop at voice. We hooked into the iOS `AVCaptureSession`, enabling Jemmie to "see" frames through your camera in real-time, allowing the AI to organically comment on what you are looking at.

### ⚠️ Challenges We Faced
Building real-time, bidirectional voice applications is notoriously unforgiving. We faced two critical, make-or-break engineering hurdles:

1.  **The Acoustic Echo Loop:** When Jemmie spoke out of the iPhone’s loudspeaker, the device's microphone would pick up her voice. Gemini would hear itself speaking, assume it was the user interrupting, and immediately cut itself off in a catastrophic audio feedback loop. We spent days diving into the murky depths of `AVFoundation` to fix this. Ultimately, we had to enforce strict `AVAudioSession.Mode.voiceChat` routing and explicitly unlock Apple's low-level hardware Acoustic Echo Cancellation (AEC).
2.  **Trigger-Happy VAD (Voice Activity Detection):** Humans naturally pause to take breaths, think, or laugh when they speak. Early in development, the Gemini endpoint's VAD was too aggressive—cutting the user off mid-sentence any time there was a fraction of a second of silence. We had to build a custom `RealtimeInputConfig` injected directly into the GenAI SDK, bumping the `silence_duration_ms` threshold up to 1200ms and significantly lowering the start-of-speech sensitivities. This allowed the conversation to breathe and feel fundamentally human.

### 📚 What We Learned
This project was a masterclass in low-latency infrastructure and human-computer interaction. We learned how to manipulate raw audio buffers natively in Swift and structure an event-driven state machine to handle the chaos of bi-directional streams.

More profoundly, we learned that **latency is the killer of empathy**. Shaving off even 200 milliseconds transforms an AI from a "tool" into a "companion." We also discovered how radically different prompt engineering becomes when designing for *voice* instead of text. We had to teach Jemmie to use filler words, to match our emotional cadence, and to abandon standard markdown formatting entirely. We learned that to make an AI feel human, you have to engineer it to embrace the messy, beautiful reality of human conversation.

---

## 🧱 Built With
*   **Languages:** Swift, Python (3.12)
*   **iOS & Apple Frameworks:** SwiftUI, AVFoundation, CallKit
*   **AI & APIs:** Google Gemini Live API (Multimodal Live API), Google GenAI SDK
*   **Backend Framework:** FastAPI, WebSockets
*   **Cloud & Deployment:** Google Cloud Run, Cloud Firestore (for session persistence), Docker, GitHub Actions
*   **Protocols/Formats:** Bidirectional WebSockets, Raw 16-bit PCM Audio, base64 JPEG

---

## 💻 Getting Started (iOS Client)

### Prerequisites
*   **macOS** (latest version recommended)
*   **Xcode 15+**
*   **iOS 17.0+** Target Device or Simulator (Note: AVFoundation AEC features perform best on physical devices).
*   Backend endpoint running (see the `Backend/jemmie-backend/` directory).

### Installation & Running
1. Clone the repository and open `Jemmie.xcodeproj`.
2. Wait for Swift Package Manager to resolve any dependencies.
3. If running on a physical device, select your Development Team under **Signing & Capabilities**.
4. Configure the Backend WebSocket URL in `Config/AppConfig.swift` (if applicable).
5. Build and run `CMD + R`.

### 🧪 Reproducible Testing

To ensure the client is stable and passing all tests, you can run tests directly via command line using `xcodebuild`:

```bash
# Run the iOS test suite on a targeted simulator
xcodebuild test \
  -project Jemmie.xcodeproj \
  -scheme Jemmie \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest' \
  -enableCodeCoverage YES
```

Make sure the required Background Modes (`Voice over IP` and `Audio, AirPlay, and Picture in Picture`) remain enabled in Xcode to prevent interrupted testing.
