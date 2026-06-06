import EmoPetKit
import EmoPetCore
import EmoPetPersonality
import EmoPetPersistence
import EmoPetDialogue
import EmoPetAssistant
import PetCat
import PetDog
import SwiftUI

@main
struct EmoPetApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
