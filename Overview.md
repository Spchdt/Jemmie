Project GemKit: Invisible Multimodal AI for iOS

1. Vision & Problem Statement

Problem: Voice AI has massive "Social Friction." Users are hesitant to use multimodal voice agents in public (cafes, libraries, transit) because talking to a phone out loud and holding it like a walkie-talkie is awkward and conspicuous.
Solution: GemKit is a stealth, hardware-hijacking iOS application that wraps the Gemini Multimodal Live API in a native CallKit interface. It allows users to interact with AI through a "fake phone call" using silent hardware sensors (Volume buttons, Proximity, Gyroscope) instead of speech.

2. The Tech Stack

Frontend: Swift / SwiftUI (Native iOS)

AI Engine: Google GenAI SDK (Gemini Multimodal Live API)

Audio/UI Hooks: CallKit, AVFoundation, CoreMotion, MediaPlayer

Backend: Google Cloud Functions (Node.js/Python) & Cloud Firestore

Communication: Bidirectional WebSockets (PCM 16-bit 16kHz Up / 24kHz Down)

3. Core Feature Roadmap (MVP)

Phase 1: The "CallKit" Illusion

Implement CXProviderDelegate to simulate an incoming call UI.

Use AVAudioSession to route audio to the earpiece (Receiver) and AirPods.

Establish a WebSocket connection to Gemini Live via the Google GenAI SDK.

Phase 2: The Hardware Interaction Layer (Silent UI)

Proximity Vision: Observe UIDevice.proximityState.

Logic: When state is false (phone pulled from ear), trigger a 1-second AVCaptureSession to grab a frame and send to Gemini Vision.

Volume Binary Input: Use MPVolumeView or AVAudioSession observers to detect physical Volume Up/Down clicks.

Logic: Intercept the event, prevent the system volume HUD from showing, and send a data message to Gemini as a hidden text prompt (e.g., "User confirmed Option A").

Kinetic Exit: Use CoreMotion (CMMotionManager) to detect a 180-degree flip (Face Down).

Logic: Pause the stream and trigger the backend summarization.

Phase 3: The Cloud "Brain"

Trigger a Google Cloud Function on session end.

Use Gemini 1.5 Pro to summarize the transcript stored in Firestore.

Push a local notification to the user with a summary link.

4. Implementation Details for the AI Coding Assistant

A. Audio Format Requirements (CRITICAL)

Gemini Live API requires a very specific byte format. Do not use standard AAC/MP3.

Input: 16-bit Linear PCM, 16000Hz, Mono.

Output: 16-bit Linear PCM, 24000Hz, Mono.

Constraint: Use AVAudioEngine with a tap on the input node to capture and downsample in real-time.

B. CallKit Integration

The app must manage the AudioSession strictly. When CallKit starts, the system takes control of the audio. Ensure provider(_:didActivate:) is used to start the AVAudioEngine only after the system grants permission.

C. Multimodal Payload Structure

Every interaction should be sent over the single WebSocket.

Audio Parts: Base64 encoded PCM chunks.

Image Parts: Base64 encoded JPEG (low compression) for visual context.

Tool/Content Parts: JSON strings for the hardware button intents.

5. Success Criteria for Hackathon

Zero-Speech Interaction: Demonstrate a 60-second interaction where the user only clicks buttons and looks at the phone, yet the AI provides complex advice.

Native Look & Feel: The app must be indistinguishable from a real iOS incoming call.

Google Cloud Integration: Architecture must show data persistence and serverless processing for the post-call summary.