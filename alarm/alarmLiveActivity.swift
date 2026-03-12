//
//  alarmLiveActivity.swift
//  alarm
//
//  Created by Supachod Trakansirorut on 12/3/26.
//

import AlarmKit
import SwiftUI
import WidgetKit

struct JemmieTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<JemmieTimerMetadata>.self) { context in
            // Lock Screen / StandBy UI
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    modeIndicator(for: context.state.mode)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.metadata?.label ?? "Timer")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    countdownContent(for: context.state.mode)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                compactTrailingContent(for: context.state.mode)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - Lock Screen

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<AlarmAttributes<JemmieTimerMetadata>>) -> some View {
        let label = context.attributes.metadata?.label ?? "Timer"

        VStack(spacing: 8) {
            HStack {
                Image(systemName: "timer")
                    .font(.title3)
                Text(label)
                    .font(.headline)
                Spacer()
                modeIndicator(for: context.state.mode)
            }

            countdownContent(for: context.state.mode)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .activityBackgroundTint(.blue.opacity(0.15))
        .activitySystemActionForegroundColor(.primary)
    }

    // MARK: - Mode-based content

    @ViewBuilder
    private func countdownContent(for mode: AlarmPresentationState.Mode) -> some View {
        switch mode {
        case .countdown(let countdown):
            Text(countdown.fireDate, style: .timer)
                .font(.system(.title, design: .monospaced, weight: .bold))
                .monospacedDigit()

        case .alert:
            Text("Time's up!")
                .font(.title2.bold())
                .foregroundStyle(.red)

        case .paused(let paused):
            let remaining = paused.totalCountdownDuration - paused.previouslyElapsedDuration
            Text(Duration.seconds(remaining), format: .time(pattern: .minuteSecond))
                .font(.system(.title, design: .monospaced, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.secondary)

        @unknown default:
            Text("—")
        }
    }

    @ViewBuilder
    private func modeIndicator(for mode: AlarmPresentationState.Mode) -> some View {
        switch mode {
        case .countdown:
            Text("Running")
                .font(.caption.bold())
                .foregroundStyle(.green)
        case .alert:
            Text("Alert")
                .font(.caption.bold())
                .foregroundStyle(.red)
        case .paused:
            Text("Paused")
                .font(.caption.bold())
                .foregroundStyle(.orange)
        @unknown default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func compactTrailingContent(for mode: AlarmPresentationState.Mode) -> some View {
        switch mode {
        case .countdown(let countdown):
            Text(countdown.fireDate, style: .timer)
                .monospacedDigit()
                .frame(minWidth: 32)
        case .alert:
            Image(systemName: "bell.fill")
                .foregroundStyle(.red)
        case .paused:
            Image(systemName: "pause.fill")
                .foregroundStyle(.orange)
        @unknown default:
            EmptyView()
        }
    }
}
