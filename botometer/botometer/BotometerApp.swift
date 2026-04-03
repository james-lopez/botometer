import SwiftUI

@main
struct BotometerApp: App {
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .preferredColorScheme(.dark)
                .frame(width: 320)
            Divider()
            Button("Quit Bot-o-Meter") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
                .padding(.bottom, 8)
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)
    }
}
