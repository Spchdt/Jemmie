import ActivityKit
import AlarmKit
import SwiftUI

/// Metadata attached to Jemmie timer alarms.
struct JemmieTimerMetadata: AlarmMetadata {
    var label: String
}

@MainActor
final class TimerService {

    private let alarmManager = AlarmManager.shared

    /// Request AlarmKit authorization up front.
    func requestAuthorization() async -> Bool {
        do {
            let state = try await alarmManager.requestAuthorization()
            return state == .authorized
        } catch {
            print("[TimerService] Authorization error: \(error)")
            return false
        }
    }

    /// Schedule a countdown timer using AlarmKit.
    func scheduleTimer(durationSeconds: Int, label: String) async -> Bool {
        let alert = AlarmPresentation.Alert(
            title: "\(label) — Time's up!",
            stopButton: AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.fill")
        )
        let countdown = AlarmPresentation.Countdown(title: "\(label)")
        let paused = AlarmPresentation.Paused(
            title: "\(label) — Paused",
            resumeButton: AlarmButton(text: "Resume", textColor: .white, systemImageName: "play.fill")
        )

        let presentation = AlarmPresentation(alert: alert, countdown: countdown, paused: paused)
        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: JemmieTimerMetadata(label: label),
            tintColor: .blue
        )

        let configuration = AlarmManager.AlarmConfiguration.timer(
            duration: TimeInterval(max(durationSeconds, 1)),
            attributes: attributes,
            sound: .default
        )

        let id = UUID()
        do {
            _ = try await alarmManager.schedule(id: id, configuration: configuration)
            print("[TimerService] Scheduled timer: \(label) for \(durationSeconds)s (id=\(id))")
            return true
        } catch {
            print("[TimerService] Failed to schedule: \(error)")
            return false
        }
    }
}
