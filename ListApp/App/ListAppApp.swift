import SwiftUI

@main
struct ListAppApp: App {
    @State private var appState = AppState()

    private var preferredColorScheme: ColorScheme? {
        switch appState.selectedTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(preferredColorScheme)
        }
    }
}
