import SwiftUI

@main
struct JemmieApp: App {
    init() {
        // Initialize CallManager singleton early so it's ready for CallKit events
        _ = CallManager.shared
        print("[Jemmie] Device ID: \(DeviceIdentity.deviceId)")
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
