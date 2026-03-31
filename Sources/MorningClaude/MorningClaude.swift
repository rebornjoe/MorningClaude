import SwiftUI

@main
struct MorningClaudeApp: App {

    init() {
        // Force the raw executable to behave like a standard macOS app
        // so it can receive keyboard focus and text input.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}