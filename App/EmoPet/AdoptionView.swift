import EmoPetKit
import SwiftUI

struct AdoptionView: View {
    @EnvironmentObject var appState: AppState

    @State private var petName = ""
    @State private var species: PetSpeciesID = .cat
    @State private var gender: PetGender = .neutral
    @State private var personality: ExpectedPetPersonality = .gentle
    @State private var language: PetLanguage = .chinese

    private var lang: PetLanguage { language }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(L10n.text("adoption.subtitle", language: lang))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section(L10n.text("field.petName", language: lang)) {
                    TextField(L10n.text("field.petName", language: lang), text: $petName)
                }
                Section(L10n.text("field.species", language: lang)) {
                    Picker(L10n.text("field.species", language: lang), selection: $species) {
                        ForEach(availableSpecies, id: \.self) { s in
                            Text(L10n.text(s.l10nKey, language: lang)).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section(L10n.text("field.gender", language: lang)) {
                    Picker(L10n.text("field.gender", language: lang), selection: $gender) {
                        ForEach(PetGender.allCases, id: \.self) { g in
                            Text(L10n.text(g.l10nKey, language: lang)).tag(g)
                        }
                    }
                }
                Section(L10n.text("field.personality", language: lang)) {
                    Picker(L10n.text("field.personality", language: lang), selection: $personality) {
                        ForEach(ExpectedPetPersonality.allCases, id: \.self) { p in
                            Text(L10n.text(p.l10nKey, language: lang)).tag(p)
                        }
                    }
                }
                Section(L10n.text("field.language", language: lang)) {
                    Picker(L10n.text("field.language", language: lang), selection: $language) {
                        ForEach(PetLanguage.allCases, id: \.self) { l in
                            Text(L10n.text(l.l10nKey, language: lang)).tag(l)
                        }
                    }
                }
                Section {
                    CartoonPetPreview(species: species, state: .idle, size: 120)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
                if let err = appState.authError {
                    Section {
                        Text(err).foregroundStyle(.red).font(.caption)
                    }
                }
                Section {
                    Button(L10n.text("button.adopt", language: lang)) {
                        appState.adoptPet(
                            name: petName,
                            species: species,
                            gender: gender,
                            personality: personality,
                            language: language
                        )
                    }
                    .disabled(petName.trimmingCharacters(in: .whitespaces).isEmpty)
                    if appState.session?.pets.isEmpty == false {
                        Button(L10n.text("button.skipAdoption", language: lang)) {
                            appState.enterHome()
                        }
                    }
                }
            }
            .navigationTitle(L10n.text("adoption.title", language: lang))
            .onAppear { pickDefaultSpecies() }
        }
    }

    private var availableSpecies: [PetSpeciesID] {
        PetSpeciesID.allCases.filter { appState.session?.canAdopt(species: $0) ?? true }
    }

    private func pickDefaultSpecies() {
        if let first = availableSpecies.first {
            species = first
        }
    }
}
