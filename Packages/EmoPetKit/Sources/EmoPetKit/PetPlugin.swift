import Foundation

// MARK: - Pet Plugin Protocol
// 核心功能与宠物形象解耦：所有宠物共享同一套引擎，仅通过 Plugin 注入差异

public enum PetSpeciesID: String, Codable, Sendable, CaseIterable {
    case cat
    case dog
}

public enum PetAnimation: String, Codable, Sendable, CaseIterable {
    case idle
    case walkToEdge
    case pawScratch
    case lieDown
    case eat
    case bath
    case cleanWaste
    case sick
    case recover
    case happy
    case angry
    case cold
    case petting
    case apologize
    case sleep
    case wakeUpReunion
    case studyCompanion
    case exerciseCompanion
    case alarmWake
    case milestoneCelebrate
}

public enum PetSound: String, Codable, Sendable {
    case meowSoft
    case meowHungry
    case barkHappy
    case barkSad
    case purr
    case whine
    case sickGroan
}

/// 宠物插件：形象、动画、文案风格独立打包，可单独更新
public protocol PetPlugin: Sendable {
    var speciesID: PetSpeciesID { get }
    var displayName: String { get }
    var bundleResourceName: String { get }

    func animationAsset(for animation: PetAnimation) -> PetAnimationAsset
    func soundAsset(for sound: PetSound) -> PetSoundAsset?
    func speechStyle() -> PetSpeechStyle
    func decayProfile() -> PetDecayProfile
}

public struct PetAnimationAsset: Sendable {
    public let animation: PetAnimation
    public let resourcePath: String
    public let duration: TimeInterval
    public let loops: Bool

    public init(animation: PetAnimation, resourcePath: String, duration: TimeInterval, loops: Bool = true) {
        self.animation = animation
        self.resourcePath = resourcePath
        self.duration = duration
        self.loops = loops
    }
}

public struct PetSoundAsset: Sendable {
    public let sound: PetSound
    public let resourcePath: String

    public init(sound: PetSound, resourcePath: String) {
        self.sound = sound
        self.resourcePath = resourcePath
    }
}

/// 宠物说话风格（猫/狗差异化，V1 模板对话 & V2 LLM System Prompt 共用）
public struct PetSpeechStyle: Sendable {
    public let particle: String          // 喵 / 汪
    public let ellipsisBias: Double      // 省略号使用倾向 0~1
    public let sentenceFragmentBias: Double
    public let affectionExpression: String

    public init(particle: String, ellipsisBias: Double, sentenceFragmentBias: Double, affectionExpression: String) {
        self.particle = particle
        self.ellipsisBias = ellipsisBias
        self.sentenceFragmentBias = sentenceFragmentBias
        self.affectionExpression = affectionExpression
    }
}

/// 宠物可选的衰减微调（默认统一，特殊宠物可覆盖）
public struct PetDecayProfile: Sendable {
    public let hungerDecayMultiplier: Double
    public let cleanlinessDecayMultiplier: Double

    public static let standard = PetDecayProfile(hungerDecayMultiplier: 1.0, cleanlinessDecayMultiplier: 1.0)

    public init(hungerDecayMultiplier: Double, cleanlinessDecayMultiplier: Double) {
        self.hungerDecayMultiplier = hungerDecayMultiplier
        self.cleanlinessDecayMultiplier = cleanlinessDecayMultiplier
    }
}

public struct PetPluginRegistry: Sendable {
    private let plugins: [PetSpeciesID: any PetPlugin]

    public init(plugins: [any PetPlugin]) {
        self.plugins = Dictionary(uniqueKeysWithValues: plugins.map { ($0.speciesID, $0) })
    }

    public func plugin(for species: PetSpeciesID) -> (any PetPlugin)? {
        plugins[species]
    }

    public var allSpecies: [PetSpeciesID] {
        Array(plugins.keys).sorted { $0.rawValue < $1.rawValue }
    }
}
