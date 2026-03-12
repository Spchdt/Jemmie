//
//  JemmieTimerMetadata.swift
//  alarm
//
//  Duplicated from main app target so the widget extension
//  can decode AlarmAttributes<JemmieTimerMetadata>.
//

import AlarmKit

/// Metadata attached to Jemmie timer alarms.
struct JemmieTimerMetadata: AlarmMetadata {
    var label: String
}
