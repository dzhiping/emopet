import EmoPetKit
import EmoPetPersistence
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private var lang: PetLanguage { appState.uiLanguage }

    var body: some View {
        NavigationStack {
            List {
                if let pets = appState.session?.pets, !pets.isEmpty {
                    Section(L10n.text("settings.section.pets", language: lang)) {
                        ForEach(pets) { pet in
                            Button {
                                appState.switchPet(to: pet.id)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(pet.adoption.petName)
                                            .font(.body.weight(.medium))
                                        Text(L10n.text("species.\(pet.adoption.speciesID.rawValue)", language: lang))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if appState.session?.activePetID == pet.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color(red: 0.95, green: 0.55, blue: 0.28))
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                        if appState.canAdoptMore {
                            Button(L10n.text("button.adoptAnother", language: lang)) {
                                dismiss()
                                appState.phase = .adoption
                            }
                        }
                    }
                }

                Section(L10n.text("settings.section.language", language: lang)) {
                    ForEach(PetLanguage.allCases, id: \.self) { language in
                        Button {
                            appState.setAppLanguage(language)
                        } label: {
                            HStack {
                                Text(L10n.text(language.l10nKey, language: lang))
                                Spacer()
                                if appState.uiLanguage == language {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color(red: 0.95, green: 0.55, blue: 0.28))
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section(L10n.text("settings.section.data", language: lang)) {
                    NavigationLink(L10n.text("menu.backup", language: lang)) {
                        BackupView()
                    }
                }
            }
            .navigationTitle(L10n.text("settings.title", language: lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("settings.done", language: lang)) { dismiss() }
                }
            }
        }
    }
}

struct BackupView: View {
    @EnvironmentObject var appState: AppState

    private var lang: PetLanguage { appState.uiLanguage }

    var body: some View {
        VStack(spacing: 20) {
            Text(L10n.text("settings.backup.hint", language: lang))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            ShareLink(item: exportURL, preview: SharePreview("EmoPet Backup"))
        }
        .padding()
        .navigationTitle(L10n.text("menu.backup", language: lang))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var exportURL: URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("emopet_backup.json")
        if let store = try? LocalDataStore.defaultStore(),
           let session = appState.session,
           let data = try? store.exportBackup(session: session) {
            try? data.write(to: url)
        }
        return url
    }
}
