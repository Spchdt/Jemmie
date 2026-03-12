import SwiftUI

/// ContentView now delegates to HomeView which is the main app interface.
struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
}
