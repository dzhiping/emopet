import EmoPetKit
import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch appState.phase {
            case .registration:
                RegistrationView()
            case .login:
                LoginView()
            case .adoption:
                AdoptionView()
            case .home:
                HomeView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.phase)
    }
}

#Preview {
    RootView().environmentObject(AppState())
}
