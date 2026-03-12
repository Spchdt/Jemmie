# Jemmie iOS App — Frontend Master Plan

> **Project:** Gemini Live Agent Challenge (Deadline: March 16, 2026)
> **Category:** Live Agents — Real-time audio/vision interaction
> **Team:** Kopibara
> **Concept:** Stealth multimodal AI disguised as a native phone call

---

## 1. Product Vision

Jemmie wraps the Gemini Multimodal Live API inside a **native CallKit phone call**. Users interact with the AI agent as if answering a regular call — audio routed to the earpiece, the call appears on the lock screen and in the system call log. The key innovation is **zero-speech interaction**: the user can operate entirely through hardware sensors (volume buttons, proximity sensor, gyroscope) without speaking aloud, eliminating the social friction of talking to an AI in public.

### Core Differentiators

| Feature | How It Works |
|---------|-------------|
| **CallKit Illusion** | The AI session looks and feels like a real incoming phone call |
| **Earpiece Audio** | Agent voice routed to earpiece or AirPods — not speakerphone |
| **Proximity Vision** | Pulling phone from ear triggers a camera snapshot → Gemini Vision |
| **Volume Binary Input** | Volume Up/Down buttons send silent intent signals to the agent |
| **Kinetic Exit** | Flipping phone face-down pauses stream and triggers session summary |
| **Post-Call Summary** | Cloud Function summarises transcript → local notification |

---

## 2. System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  iOS App (Swift / SwiftUI)                                  │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────────┐│
│  │ CallKit     │  │ Audio Engine │  │ Hardware Sensors     ││
│  │ Provider    │──│ (AVAudio)   │  │ ├─ Proximity         ││
│  │ + CXCall    │  │ earpiece    │  │ ├─ Volume Buttons    ││
│  └──────┬──────┘  └──────┬──────┘  │ └─ Gyroscope (flip) ││
│         │                │         └──────────┬───────────┘│
│         │     ┌──────────┴──────────┐         │            │
│         │     │  WebSocket Service  │◄────────┘            │
│         │     └──────────┬──────────┘                      │
│  ┌──────┴────────────────┴──────────────────────────────┐  │
│  │         UI Layer (SwiftUI + MVVM)                    │  │
│  │  ├─ CallKit native call screen (primary)             │  │
│  │  └─ In-app transcript view (secondary)               │  │
│  └──────────────────────────────────────────────────────┘  │
└──────────────────────────┬──────────────────────────────────┘
                           │ WebSocket: ws(s)://{host}/ws/{device_id}
                           │ Binary: PCM audio (16kHz up / 24kHz down)
                           │ Text:   JSON frames
┌──────────────────────────▼──────────────────────────────────┐
│  Backend (Cloud Run — Python + FastAPI)                      │
│  → Gemini Live API (gemini-2.5-flash-native-audio)          │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Backend Contract Summary

*(Full reference: `Backend/docs/frontend-integration.md`)*

| Item | Detail |
|------|--------|
| Endpoint | `ws(s)://{host}/ws/{device_id}` |
| Identity | UUID generated on first launch, persisted in `UserDefaults` |
| Session resumption | Automatic within 10-minute grace window |
| Audio up | PCM 16 kHz, 16-bit signed, mono |
| Audio down | PCM 24 kHz, 16-bit signed, mono |
| JSON client → server | `IMAGE`, `PING`, custom actions (e.g. `VOLUME_UP`, `VOLUME_DOWN`, `FLIP_EXIT`) |
| JSON server → client | `TEXT`, `TRANSCRIPTION_INPUT`, `TRANSCRIPTION_OUTPUT`, `TURN_COMPLETE`, `INTERRUPTED`, `ERROR`, `PONG`, custom events |

---

## 4. Tech Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| UI | SwiftUI | In-app views (transcript, settings) |
| Call UI | CallKit (`CXProvider`, `CXCallController`) | Native call screen on lock screen & system UI |
| Audio | AVFoundation / `AVAudioEngine` | PCM capture & earpiece playback |
| Networking | `URLSessionWebSocketTask` | WebSocket connection to backend |
| Camera | AVCaptureSession | Single-frame capture on proximity trigger |
| Sensors | CoreMotion (`CMMotionManager`) | Gyroscope for flip-to-exit gesture |
| Sensors | UIDevice proximity | Proximity state for camera trigger |
| Volume input | MediaPlayer / `MPVolumeView` | Intercept hardware volume buttons |
| Location | CoreLocation | Optional location sharing action |
| Notifications | UserNotifications | Post-call summary notification |

> **Zero third-party dependencies.** All built on Apple system frameworks.

---

## 5. Implementation Phases

### Phase 0 — Project Scaffold & Device Identity

**Goal:** Set up project structure and persistent device identity.

**Directory structure:**

```
Jemmie/
├── JemmieApp.swift
├── Config/
│   └── AppConfig.swift                # Backend URL, environment
├── Models/
│   ├── ServerEvent.swift              # Decodable server JSON frames
│   ├── ClientFrame.swift              # Encodable client JSON frames
│   └── CallState.swift                # Call lifecycle state enum
├── Services/
│   ├── DeviceIdentity.swift           # UUID generation & UserDefaults
│   ├── CallManager.swift              # CallKit CXProvider + CXCallController
│   ├── WebSocketService.swift         # WebSocket lifecycle
│   ├── AudioEngine.swift              # AVAudioEngine capture + playback
│   ├── CameraService.swift            # Single-frame JPEG capture
│   └── HardwareInputService.swift     # Proximity, volume, gyroscope
├── ViewModels/
│   ├── CallViewModel.swift            # Orchestrates all services
│   └── TranscriptViewModel.swift      # Live transcript state
├── Views/
│   ├── HomeView.swift                 # Main screen with "call" trigger
│   ├── TranscriptView.swift           # Post-call / live transcript
│   └── Components/
│       ├── CallButton.swift           # Trigger button
│       └── StatusBadge.swift          # Connection indicator
└── Extensions/
    └── Data+PCM.swift                 # PCM byte helpers
```

---

### Phase 1 — CallKit Integration (Core)

**Goal:** Make the AI session appear as a native iOS phone call.

This is the **foundation** of the entire app. All other features plug into the CallKit lifecycle.

**Key components:**

| Component | Responsibility |
|-----------|---------------|
| `CXProvider` | Reports incoming/outgoing calls to the system |
| `CXCallController` | Requests call actions (start, end, hold) |
| `CXProviderDelegate` | Handles system callbacks (audio activation, call answers) |
| `AVAudioSession` | Configured for `.playAndRecord` with `.builtInReceiver` (earpiece) |

**Call lifecycle:**

```
User taps "Call" button
    → CXCallController.request(CXStartCallAction)
    → System shows native call UI (earpiece icon, green bar, lock screen)
    → provider(_:perform startCallAction:)
        → Connect WebSocket
        → Wait for provider(_:didActivate audioSession:)
            → Start AVAudioEngine (ONLY after system grants audio)
            → Begin streaming PCM ↔ backend

User taps "End" / system ends
    → CXCallController.request(CXEndCallAction)
    → provider(_:perform endCallAction:)
        → Stop AVAudioEngine
        → Close WebSocket
        → Trigger post-call summary
```

**Critical constraint:** `AVAudioEngine` must **only** start inside `provider(_:didActivate:)`. Starting it before the system activates the audio session will fail silently or crash.

**Audio routing:**

```swift
let session = AVAudioSession.sharedInstance()
try session.setCategory(.playAndRecord, mode: .voiceChat, options: [])
try session.overrideOutputAudioPort(.none) // earpiece, not speaker
```

- Earpiece by default → private listening
- AirPods if connected → automatic route
- No speakerphone unless user explicitly switches

---

### Phase 2 — WebSocket Service

**Goal:** Manage the WebSocket connection within the CallKit lifecycle.

- Connect to `ws(s)://{host}/ws/{device_id}` when call starts
- Send binary PCM frames from mic capture
- Receive binary PCM frames for playback + text JSON events
- Ping/PONG keepalive every 15 seconds
- Auto-reconnect with exponential backoff (1s → 2s → 4s → max 30s)
- Clean disconnect when call ends

**State machine:**

```
disconnected → connecting → connected → active → disconnecting → disconnected
                                           ↑                          │
                                           └── reconnecting ──────────┘
```

---

### Phase 3 — Audio Engine

**Goal:** Capture microphone PCM and play earpiece PCM, strictly within CallKit audio session.

**Capture (mic → server):**

- `AVAudioEngine` input tap
- Convert to 16 kHz, 16-bit signed, mono
- Chunk into ~20ms frames (640 bytes)
- Send as binary WebSocket frames
- Mute support: stop sending PCM without disconnecting

**Playback (server → phone earpiece):**

- Buffer incoming 24 kHz PCM in a circular buffer
- Feed to `AVAudioPlayerNode` → earpiece output
- On `INTERRUPTED` event: flush buffer + stop playback immediately
- On `TURN_COMPLETE`: let remaining buffer drain naturally

---

### Phase 4 — Hardware Interaction Layer (Silent UI)

**Goal:** Enable zero-speech interaction through hardware sensors.

This is the **key innovation** — users can interact without speaking aloud.

#### 4A — Proximity Vision

| Trigger | Action |
|---------|--------|
| Phone pulled away from ear (`proximityState = false`) | Capture single camera frame |

- Monitor `UIDevice.current.isProximityMonitoringEnabled`
- On state change `true → false` (ear → away): trigger 1-second `AVCaptureSession`
- Capture rear camera JPEG, base64-encode, send as `IMAGE` frame
- Gemini processes the visual and responds via audio
- Use case: *"What am I looking at?"* without saying a word

#### 4B — Volume Button Binary Input

| Button | Signal Sent |
|--------|------------|
| Volume Up | `{ "type": "VOLUME_UP", "payload": { "intent": "confirm" } }` |
| Volume Down | `{ "type": "VOLUME_DOWN", "payload": { "intent": "deny" } }` |

- Intercept volume changes via `AVAudioSession.outputVolume` KVO or `MPVolumeView`
- Suppress the system volume HUD (use hidden `MPVolumeView`)
- Send as client action frame → backend translates to agent context
- Use case: Agent asks *"Would you like option A?"* → user clicks Volume Up to confirm

#### 4C — Kinetic Exit (Flip-to-End)

| Gesture | Action |
|---------|--------|
| Flip phone face-down (180° rotation) | End call + trigger summary |

- `CMMotionManager.startDeviceMotionUpdates()`
- Detect when device attitude crosses face-down threshold (gravity.z > 0.9)
- Debounce (require sustained position for ~0.5s)
- End the CallKit call → triggers post-call summary flow

---

### Phase 5 — Camera Service

**Goal:** Single-frame capture triggered by proximity sensor.

- `AVCaptureSession` with back camera (brief capture, not continuous)
- Capture a single `AVCapturePhoto`
- Compress to JPEG (quality ~0.5 for fast transfer)
- Base64-encode and send as `IMAGE` JSON frame
- Auto-release capture session after frame is sent (battery friendly)
- Request `NSCameraUsageDescription` permission

---

### Phase 6 — Transcript & Post-Call UI

**Goal:** Show conversation history and post-call summary.

**During call (minimal — the system call UI is primary):**

- Transcript runs in background, not shown during call
- CallKit's native UI is the user-facing interface

**After call:**

- Show scrollable transcript with user/agent entries
- Display post-call summary (from backend Cloud Function)
- Local notification with summary link

**Transcript model:**

```swift
struct TranscriptEntry: Identifiable {
    let id: UUID
    let speaker: Speaker    // .user, .agent, .system
    let text: String
    let timestamp: Date
    let type: EntryType      // .speech, .vision, .action
}
```

---

### Phase 7 — Custom Client Actions & Server Events

**Goal:** Extend the action system beyond hardware inputs.

**Client actions (already supported by hardware layer):**

| Action | Source |
|--------|--------|
| `VOLUME_UP` | Volume button |
| `VOLUME_DOWN` | Volume button |
| `FLIP_EXIT` | Gyroscope flip |
| `IMAGE` | Proximity camera |

**Optional additional actions:**

| Action | Source | Payload |
|--------|--------|---------|
| `SHARE_LOCATION` | User permission | `latitude`, `longitude` |

**Server events to handle:**

| Event | UI Response |
|-------|------------|
| `SET_TIMER` | Local notification / in-app timer |
| `TEXT` | Append to transcript |
| `TRANSCRIPTION_INPUT` | Append user speech to transcript |
| `TRANSCRIPTION_OUTPUT` | Append agent speech to transcript |
| `TURN_COMPLETE` | Mark turn boundary |
| `INTERRUPTED` | Flush audio buffer |
| `ERROR` (non-recoverable) | End call + show error |

---

### Phase 8 — Polish & Edge Cases

- **Real phone calls:** Handle actual incoming calls gracefully (CallKit prioritisation)
- **Audio interruptions:** Siri, alarms, other audio sessions
- **Network transitions:** WiFi ↔ cellular seamless reconnect
- **Background:** Maintain audio session while app is backgrounded (CallKit keeps it alive)
- **Battery:** Camera service is brief and on-demand; gyroscope monitoring is low-power
- **Accessibility:** VoiceOver support for in-app views
- **Haptics:** Subtle feedback on volume-button input and flip gesture detection

---

## 6. Info.plist Required Entries

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Jemmie uses the microphone for AI voice conversations.</string>

<key>NSCameraUsageDescription</key>
<string>Jemmie can capture images to give the AI visual context.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Jemmie can share your location with the AI when requested.</string>

<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>voip</string>
</array>
```

**CallKit entitlement:** The app needs the `com.apple.developer.pushkit.voip` entitlement if using PushKit for incoming call simulation (optional — can also use `CXCallController` to report outgoing calls).

---

## 7. Key Technical Decisions

| Decision | Rationale |
|----------|-----------|
| **CallKit as core** | Native call UI = indistinguishable from real call. Earpiece routing. Lock screen integration. Background audio. |
| **AVAudioEngine only after `didActivate`** | System controls audio session during CallKit — starting early causes silent failure |
| **Outgoing call model** (not incoming) | Simpler to implement: user taps button → `CXStartCallAction`. Incoming call simulation requires PushKit VoIP which needs a push server. |
| **Hidden `MPVolumeView`** | Only reliable way to intercept volume buttons without system HUD appearing |
| **`URLSessionWebSocketTask`** | Native, no dependencies, sufficient for single persistent connection |
| **Zero third-party deps** | Hackathon: no dependency risk, faster build, smaller binary |
| **Single-frame camera** (not continuous) | Battery efficient, privacy respecting, triggered only by conscious gesture (pull from ear) |

---

## 8. Implementation Priority

| Priority | Phase | Est. | Dependency |
|----------|-------|------|------------|
| 🔴 P0 | Phase 0 — Scaffold | 1h | None |
| 🔴 P0 | Phase 1 — CallKit Integration | 4h | Phase 0 |
| 🔴 P0 | Phase 2 — WebSocket Service | 2h | Phase 0 |
| 🔴 P0 | Phase 3 — Audio Engine | 3h | Phase 1, 2 |
| 🔴 P0 | Phase 4A — Proximity Vision | 2h | Phase 1, 5 |
| 🟡 P1 | Phase 4B — Volume Input | 2h | Phase 1, 2 |
| 🟡 P1 | Phase 4C — Flip-to-Exit | 1h | Phase 1 |
| 🟡 P1 | Phase 5 — Camera Service | 2h | Phase 0 |
| 🟡 P1 | Phase 6 — Transcript & Post-Call | 2h | Phase 2 |
| 🟢 P2 | Phase 7 — Client Actions & Events | 1h | Phase 2 |
| 🟢 P2 | Phase 8 — Polish | 2h | All |

**Total estimated: ~22 hours**

**Critical path for MVP demo:** Phase 0 → 1 → 2 → 3 → 4A (~12 hours)
This gives: CallKit call UI + voice conversation + proximity camera trigger.

---

## 9. Hackathon Judging Alignment

| Criteria (Weight) | How Jemmie Addresses It |
|--------------------|------------------------|
| **Innovation & Multimodal UX (40%)** | "Stealth AI" via CallKit illusion + hardware sensor inputs — no other submission will use volume buttons as AI input. Proximity-triggered vision is a novel interaction pattern. |
| **Technical Implementation (30%)** | CallKit audio session management, real-time PCM streaming, CoreMotion gesture detection, native WebSocket, multi-sensor fusion — all without third-party deps. |
| **Demo & Presentation (30%)** | 60-second zero-speech demo: answer a "call", flip phone to look at something, volume-click to confirm, flip face-down to end. Visually indistinguishable from a real phone call. |

---

## 10. Success Criteria

1. **Indistinguishable from real call** — lock screen UI, earpiece audio, green status bar
2. **Zero-speech interaction** — 60s demo using only hardware sensors
3. **Proximity vision** — pull from ear → AI describes what it sees
4. **Volume binary input** — confirm/deny without speaking
5. **Flip-to-end** — face-down gesture ends call cleanly
6. **Post-call summary** — notification with conversation summary
