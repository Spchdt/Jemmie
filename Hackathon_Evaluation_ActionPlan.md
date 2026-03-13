# 🏆 Project Jemmie: Comprehensive Devpost Submission & Action Plan

This document is a deeply expanded guide for your Devpost submission. It breaks down the exact technical narratives, provides copy-pasteable sections for your Devpost page, and outlines a shot-by-shot script for your demo video to maximize your chances of winning the **Gemini Live Agent Challenge**.

---

## 1. The Core Narrative: Why This Project Wins
Judges for the Gemini Multimodal Live Challenge are going to be flooded with hundreds of web-based React/Next.js dashboard wrappers connecting to the API via browser microphones. 

**Your Differentiator:** Jemmie is a native, deeply-integrated iOS companion. It’s not just *talking* to an AI; it's an AI that *operates the device* on the user's behalf. 

**Key Selling Points to Emphasize:**
1. **Zero-Touch OS Integration:** Jemmie can interact with the physical device through custom hooks. By capturing physical volume button presses (`request_binary_input`), Jemmie allows users to answer Yes/No without looking at the screen or speaking.
2. **True Multimodal Execution:** Real-time camera feeds aren't just uploaded as static images; they are actively streamed using background `AVCaptureSession` pipelines while the UI remains fluid and Apple-esque.
3. **Advanced Tool Calling Architecture:** You didn't just use standard function calling. You built a **Bi-directional Tool Hook System** where the Python backend triggers actions on the iOS client (like `END_CALL` or popup UI changes) and the iOS client triggers native OS actions (Location, Pasteboard, opening URLs) to feed right back into Gemini.

---

## 2. Devpost "Story" Template (Copy-Paste Ready)

Use this structure for the main description on your Devpost project page.

### 💡 Inspiration
"Current AI voice agents are trapped inside a chat window. We didn't want an AI that just answers questions; we wanted a true companion that acts on our behalf while we go about our day. We drew inspiration from Apple's accessibility features and the dream of a genuinely 'Zero-Touch' interface. We imagined an assistant that could see what we see through the camera, know where we are, and let us confirm actions using hardware buttons while the phone is securely in a pocket."

### ⚙️ What it does
"Jemmie is a native iOS application powered by the Gemini Multimodal Live API. It operates beautifully as an ambient, real-time voice assistant with several 'superpowers':
* **Physical Hardware Hooks:** Ever wanted to silently answer your AI? Jemmie intercepts the physical volume hardware buttons so you can 'click' Yes or No to the agent's questions without speaking.
* **Bi-Directional OS Operations:** Jemmie doesn't just return text; it executes OS-level functions. It can end phone calls on its own, trigger the iOS native camera stream, fetch GPS location via CoreLocation, and open deep links.
* **Real-time Multimodal Vision:** Users can manually override the standard pipeline to snap and stream Base64 JPEG frames directly into the Gemini Live WebSocket, allowing Jemmie to analyze surroundings instantly.
* **Apple-Native UI:** Built with SwiftUI's latest iOS 26+ `glassEffect` modifiers, offering dynamic blurs, haptic feedback matching Apple's HIG (Human Interface Guidelines), and an accessible transcript interface."

### 🛠️ How we built it
"Jemmie is split into a highly optimized iOS 16+ SwiftUI client and a responsive Python/FastAPI WebSocket backend. 
* **The Backend (Python/FastAPI):** We wrapped the Gemini Multimodal Live API in an asynchronous WebSocket gateway. This gateway manages session states and intercepts standard NLP tool calls, morphing them into `ServerEvents` pushed to the client.
* **The Client (Swift/Combine):** We bypassed standard high-level audio players and built a custom `AudioEngine` using `AVFoundation`. We manage 16kHz PCM audio buffers natively to ensure ultra-low latency streaming back to PyAudio and Gemini. 
* **The UI:** We extensively utilized SwiftUI `Combine` observables to manage connection states, marrying them with advanced view modifiers (`.regular.tint` liquid glass) to make the UI look indistinguishable from a first-party Apple application."

### 🚧 Challenges we ran into
"Real-time bidirectional audio streaming is notoriously difficult on iOS. Handling the conversion of raw audio buffers to Base64 PCM_16 chunks while ensuring `AVAudioEngine` didn't block the main UI thread took massive iteration. Furthermore, managing the `AVCaptureSession` for the camera alongside an active microphone session required precise threading checks to prevent app crashes and memory leaks. Finally, architecting a way for the Server to 'command' the client (like initiating an `END_CALL` command) required designing a completely custom JSON payload schema on top of the Gemini API."

### 🚀 What's next for Jemmie
"We plan to deepen our OS integrations by hooking into iOS Shortcuts, allowing Jemmie to trigger complex local automations. We also aim to implement background-mode execution, so Jemmie can live entirely in the Dynamic Island while the user navigates other apps."

---

## 3. The "Killer Demo" Video Script (Shot-by-Shot)

A 2-3 minute video is your absolute best marketing tool. Do not do a screen recording unedited. Film this dynamically. 

**Duration:** ~2m 30s
**Format:** Over-the-shoulder filming of the physical iPhone, mixed with direct screen-recording inserts.

* **[0:00 - 0:15] The Hook (The Real World)**
  * *Visual:* Filming over the user's shoulder. They are walking outside or in a unique room. 
  * *Action:* User opens Jemmie. "Hey Jemmie, can you check my location and tell me what the weather might be like here?"
  * *AI Action:* Jemmie triggers `FETCH_LOCATION`, processes GPS, and responds with contextual context instantly within 500ms.
* **[0:15 - 0:45] The "Zero-Touch" Wow Factor (Volume Buttons)**
  * *Action:* User asks: "Can you set a reminder for me to check my code later?" 
  * *AI Action:* "Sure, do you want me to set that for 30 minutes from now?" 
  * *Visual:* User deliberately presses the **Physical Volume Up Button** on the side of the phone. User explicitly does *not* speak. 
  * *AI Action:* Jemmie instantly responds: "Great, 30 minutes. I've noted it." 
  * *Caption/Popup on Video:* "Intercepts physical hardware buttons for silent confirmation."
* **[0:45 - 1:15] Multimodal Vision Breakdown**
  * *Visual:* User taps the custom Camera Glass UI button. 
  * *Action:* Camera overlay pops up fluidly. User holds the phone up to a complex object (e.g., a messy plate of food, a snippet of code on a monitor, or a confusing street sign).
  * *User:* "Jemmie, what exactly am I looking at, and what should I do with this?"
  * *AI Action:* In real-time, Jemmie analyzes the Base64 frame and gives a highly detailed, multimodal response.
* **[1:15 - 1:45] Haptics and UI Polish**
  * *Visual:* B-roll/montage of the UI. Show the clean transcript view, the liquid glass effect behind the visual elements, and the buttons graying out beautifully. Prove that it looks like a million-dollar app.
* **[1:45 - 2:00] The Reverse Hang-Up (Bi-directional tooling)**
  * *Action:* User says, "Alright Jemmie, I've got to run. Talk to you later, go ahead and hang up."
  * *AI Action:* "Goodbye! Talk soon."
  * *Visual:* The AI triggers the `END_CALL` event. The UI fluidly disconnects, changes to the disconnect state, and standard Apple tactile haptics trigger. (Show this interaction to prove the AI controls the app, not just the other way around).

---

## 4. Final Engineering & Polish Checklist

Before you hit submit on Devpost, ensure these specific engineering edge-cases are locked down:

* [ ] **Audio Latency Check:** Is there an echo? Ensure `AVAudioSession` is set to `voiceChat` or `playAndRecord` with `defaultToSpeaker` to prevent feedback loops.
* [ ] **Error Handling UI:** What happens if the Python backend is strictly offline? Make sure the UI catches the WebSocket disconnect and elegantly shows a "Disconnected" state rather than spinning forever.
* [ ] **Backend Repo Cleanliness:** Your `jemmie-backend` has `make check` (mypy and ruff) passing flawlessly. Make sure to mention in the README that the codebase uses strict typing and is production-grade.
* [ ] **README Architecture Diagram:** Since Devpost doesn't support complex charts easily, put a high-res image of your architecture in the GitHub/Devpost gallery. Just a simple graphic: `Client (Audio/Video/Sensors) <--> FastAPI WebSockets <--> Gemini Multimodal API`.
