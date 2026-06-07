import EmoPetKit
import EmoPetCore
import EmoPetPersonality
import EmoPetPersistence
import EmoPetDialogue
import EmoPetAssistant
import PetCat
import PetDog
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var phase: AppFlowPhase = .registration
    @Published var session: UserSession?
    @Published var isAuthenticated = false

    @Published var pet: PetSnapshot
    @Published var personality: PersonalityProfile
    @Published var engine: PetEngine
    @Published var lastDialogue: String = ""
    @Published var proactiveMessage: String?
    @Published var registry: PetPluginRegistry
    @Published var authError: String?
    @Published var petAssets = PetAssetManager()

    /// 设置页选择的 App 界面语言（持久化）
    @Published var appLanguageOverride: PetLanguage? = {
        guard let raw = UserDefaults.standard.string(forKey: "app.uiLanguage"),
              let lang = PetLanguage(rawValue: raw) else { return nil }
        return lang
    }()

    private var assessment = PersonalityAssessmentEngine()
    private let store: LocalDataStore
    private let auth = AuthService()
    private let credentialStore = KeychainCredentialStore()
    private let dialogueEngine: TemplateDialogueEngine

    init() {
        let registry = PetPluginRegistry(plugins: [CatPlugin(), DogPlugin()])
        self.registry = registry
        self.store = (try? LocalDataStore.defaultStore()) ?? LocalDataStore(
            directoryURL: FileManager.default.temporaryDirectory.appendingPathComponent("EmoPet")
        )
        let initialSnapshot = PetSnapshot(speciesID: .cat)
        self.pet = initialSnapshot
        self.personality = .neutral
        self.engine = PetEngine(snapshot: initialSnapshot)
        self.dialogueEngine = TemplateDialogueEngine(templates: DefaultDialogueTemplates.shared)
        bootstrapFlow()
    }

    var activeOwnedPet: OwnedPet? {
        session?.activePet
    }

    var uiLanguage: PetLanguage {
        appLanguageOverride ?? activeOwnedPet?.adoption.language ?? .chinese
    }

    func setAppLanguage(_ language: PetLanguage) {
        appLanguageOverride = language
        UserDefaults.standard.set(language.rawValue, forKey: "app.uiLanguage")
        guard var session, let id = session.activePetID,
              let index = session.pets.firstIndex(where: { $0.id == id }) else { return }
        session.pets[index].adoption.language = language
        self.session = session
        try? store.save(session: session)
    }

    var canAdoptMore: Bool {
        session?.canAdoptMore ?? false
    }

    var visualState: PetVisualState {
        PetVisualStateResolver.resolve(snapshot: pet)
    }

    private func bootstrapFlow() {
        guard store.hasSession(), var loaded = try? store.loadSession() else {
            phase = .registration
            return
        }
        store.migrateLegacyIfNeeded(into: &loaded)
        session = loaded
        if attemptAutoLogin(session: loaded) {
            return
        }
        phase = .login
    }

    /// 使用 Keychain 中记住的密码自动登录
    @discardableResult
    private func attemptAutoLogin(session: UserSession) -> Bool {
        guard let saved = credentialStore.load(),
              saved.displayName == session.account.displayName,
              auth.verify(password: saved.password, account: session.account) else {
            if credentialStore.load() != nil {
                credentialStore.clear()
            }
            return false
        }
        finishAuthentication(session: session)
        return true
    }

    private func rememberCredentials(displayName: String, password: String) {
        try? credentialStore.save(displayName: displayName, password: password)
    }

    private func finishAuthentication(session: UserSession) {
        self.session = session
        isAuthenticated = true
        if session.pets.isEmpty {
            phase = .adoption
        } else {
            loadActivePet()
            phase = .home
        }
    }

    func register(displayName: String, password: String, confirmPassword: String) {
        authError = nil
        guard password == confirmPassword else {
            authError = L10n.text("error.passwordMismatch", language: .chinese)
            return
        }
        do {
            let account = try auth.register(displayName: displayName, password: password)
            session = UserSession(account: account)
            try store.save(session: session!)
            rememberCredentials(displayName: account.displayName, password: password)
            finishAuthentication(session: session!)
        } catch {
            authError = L10n.text("error.invalidRegistration", language: .chinese)
        }
    }

    func login(password: String) {
        authError = nil
        guard let session else {
            phase = .registration
            return
        }
        guard auth.verify(password: password, account: session.account) else {
            authError = L10n.text("error.wrongPassword", language: .chinese)
            return
        }
        rememberCredentials(displayName: session.account.displayName, password: password)
        finishAuthentication(session: session)
    }

    func adoptPet(
        name: String,
        species: PetSpeciesID,
        gender: PetGender,
        personality: ExpectedPetPersonality,
        language: PetLanguage
    ) {
        authError = nil
        guard var session else { return }
        guard session.canAdopt(species: species) else {
            authError = L10n.text("error.petLimit", language: uiLanguage)
            return
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            authError = L10n.text("error.petNameRequired", language: language)
            return
        }
        let profile = PetAdoptionProfile(
            petName: trimmed,
            speciesID: species,
            gender: gender,
            expectedPersonality: personality,
            language: language
        )
        do {
            try session.adopt(profile)
            self.session = session
            try store.save(session: session)
            if let newPet = session.pets.last {
                session.activePetID = newPet.id
                self.session = session
                loadPet(newPet)
            }
            phase = .home
        } catch {
            authError = L10n.text("error.petLimit", language: language)
        }
    }

    func switchPet(to petID: UUID) {
        guard var session else { return }
        persistActivePet()
        session.activePetID = petID
        self.session = session
        if let owned = session.pets.first(where: { $0.id == petID }) {
            loadPet(owned)
        }
        try? store.save(session: session)
    }

    func showAdoptionIfNeeded() {
        guard isAuthenticated, session?.canAdoptMore == true else { return }
        phase = .adoption
    }

    func enterHome() {
        loadActivePet()
        phase = .home
    }

    private func loadActivePet() {
        guard let owned = session?.activePet else { return }
        loadPet(owned)
        refreshFromEngine()
    }

    private func loadPet(_ owned: OwnedPet) {
        pet = owned.snapshot
        personality = PersonalityProfile(from: owned.personality)
        engine = PetEngine(snapshot: pet)
        if let plugin = registry.plugin(for: pet.speciesID) {
            engine.bind(plugin: plugin)
        }
        _ = engine.onAppOpen()
        refreshFromEngine()
        petAssets.preload(species: pet.speciesID)
        petAssets.sync(snapshot: pet)
    }

    private func persistActivePet() {
        guard var session, let id = session.activePetID,
              let index = session.pets.firstIndex(where: { $0.id == id }) else { return }
        session.pets[index].snapshot = engine.snapshot
        session.pets[index].personality = personality.asData
        self.session = session
        try? store.save(session: session)
    }

    func refreshFromEngine(syncAssets: Bool = true) {
        pet = engine.snapshot
        proactiveMessage = ProactiveInteractionGenerator().suggest(for: pet)?.message
        if syncAssets {
            petAssets.sync(snapshot: pet)
        }
    }

    func save() {
        persistActivePet()
    }

    func perform(_ action: CareAction, oneShot: PetOneShotAction? = nil) {
        let events: [PetEngineEvent]
        switch action {
        case .feed(let food):
            events = engine.feed(food)
            assessment.observe(food == .regularMeal ? .fedOnTime : .fedLate, profile: &personality)
        case .bathe:
            events = engine.bathe()
        case .cleanWaste:
            events = engine.cleanWaste()
        case .medicine:
            events = engine.buyAndFeedMedicine()
        case .pet:
            events = engine.pet()
            assessment.observe(.pettingSession(seconds: 2), profile: &personality)
        case .apologize:
            events = engine.apologize()
        case .play:
            events = engine.playMiniGame()
            assessment.observe(.playedMiniGame, profile: &personality)
        case .completeReunion:
            events = engine.completeReunion()
        }
        refreshFromEngine(syncAssets: oneShot == nil)
        if let oneShot {
            petAssets.playOneShot(oneShot, resumeWith: pet)
        }
        save()
        _ = events
    }

    func speak(topic: DialogueTopic) {
        guard let plugin = registry.plugin(for: pet.speciesID) else { return }
        let level = DialogueLevel.from(unlocked: pet.unlocked, stage: pet.stage)
        let context = DialogueContext(
            level: level,
            speechStyle: plugin.speechStyle(),
            memoryTags: pet.memoryTags,
            emotion: pet.emotion,
            topic: topic
        )
        lastDialogue = dialogueEngine.generate(context: context)
        playDialogueAnimation(for: topic, level: level)
    }

    func playDialogueAnimation(for topic: DialogueTopic, level: DialogueLevel? = nil) {
        let lv = level ?? DialogueLevel.from(unlocked: pet.unlocked, stage: pet.stage)
        switch topic {
        case .memory:
            if petAssets.hasOneShot(.memoryRecall) {
                petAssets.playOneShot(.memoryRecall)
            } else if petAssets.hasAsset(for: PetAnimationCatalog.specialLoop(.listening, species: pet.speciesID)) {
                petAssets.playSpecialLoop(.listening)
            }
        default:
            let action: PetOneShotAction = lv >= .fullSentence ? .talkFull : .talkShort
            if petAssets.hasOneShot(action) {
                petAssets.playOneShot(action)
            } else if petAssets.hasAsset(for: PetAnimationCatalog.specialLoop(.listening, species: pet.speciesID)) {
                petAssets.playSpecialLoop(.listening)
            }
        }
    }

    func playAssistantAnimation(_ feature: PetAssistantFeature) {
        switch feature {
        case .alarm:
            if petAssets.hasOneShot(.alarmWake) { petAssets.playOneShot(.alarmWake) }
        case .study:
            if petAssets.hasAsset(for: PetAnimationCatalog.specialLoop(.studyCompanion, species: pet.speciesID)) {
                petAssets.playSpecialLoop(.studyCompanion, duration: 5)
            }
        case .studyDone:
            if petAssets.hasOneShot(.studyCheer) { petAssets.playOneShot(.studyCheer) }
        case .exercise:
            if petAssets.hasAsset(for: PetAnimationCatalog.specialLoop(.exerciseCompanion, species: pet.speciesID)) {
                petAssets.playSpecialLoop(.exerciseCompanion, duration: 5)
            }
        case .exerciseDone:
            if petAssets.hasOneShot(.exerciseCheer) { petAssets.playOneShot(.exerciseCheer) }
        case .schedule:
            if petAssets.hasOneShot(.scheduleNudge) { petAssets.playOneShot(.scheduleNudge) }
        }
    }

    enum PetAssistantFeature {
        case alarm, study, studyDone, exercise, exerciseDone, schedule
    }

    enum CareAction {
        case feed(FoodType)
        case bathe
        case cleanWaste
        case medicine
        case pet
        case apologize
        case play
        case completeReunion
    }
}
