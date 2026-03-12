import Foundation
import SwiftUI

@Observable
@MainActor
final class TranscriptViewModel {
    var entries: [TranscriptEntry] = []

    func addEntry(_ entry: TranscriptEntry) {
        entries.append(entry)
    }

    func appendUserSpeech(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        entries.append(TranscriptEntry(speaker: .user, text: text, isComplete: true))
    }

    func appendAgentSpeech(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        entries.append(TranscriptEntry(speaker: .agent, text: text, isComplete: true))
    }

    func appendSystemMessage(_ text: String) {
        entries.append(TranscriptEntry(speaker: .system, text: text, isComplete: true))
    }

    func markLastAgentComplete() {
        guard let idx = entries.indices.last(where: { entries[$0].speaker == .agent }) else { return }
        entries[idx].isComplete = true
    }

    func clear() {
        entries.removeAll()
    }
}
