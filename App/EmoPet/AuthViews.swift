import EmoPetKit
import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private let lang: PetLanguage = .chinese

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(L10n.text("register.subtitle", language: lang))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section {
                    TextField(L10n.text("field.name", language: lang), text: $name)
                        .textContentType(.name)
                    SecureField(L10n.text("field.password", language: lang), text: $password)
                    SecureField(L10n.text("field.confirmPassword", language: lang), text: $confirmPassword)
                }
                if let err = appState.authError {
                    Section {
                        Text(err).foregroundStyle(.red).font(.caption)
                    }
                }
                Section {
                    Button(L10n.text("button.register", language: lang)) {
                        appState.register(displayName: name, password: password, confirmPassword: confirmPassword)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty)
                }
            }
            .navigationTitle(L10n.text("register.title", language: lang))
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let name = appState.session?.account.displayName {
                        Text(String(format: L10n.text("greeting.user", language: .chinese), name))
                    }
                    Text(L10n.text("login.subtitle", language: .chinese))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section {
                    SecureField(L10n.text("field.password", language: .chinese), text: $password)
                        .textContentType(.password)
                }
                if let err = appState.authError {
                    Section {
                        Text(err).foregroundStyle(.red).font(.caption)
                    }
                }
                Section {
                    Button(L10n.text("button.login", language: .chinese)) {
                        appState.login(password: password)
                    }
                    .disabled(password.isEmpty)
                }
            }
            .navigationTitle(L10n.text("login.title", language: .chinese))
        }
    }
}
