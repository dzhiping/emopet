import Foundation
import EmoPetKit

public struct DogPlugin: PetPlugin, Sendable {
    public let speciesID: PetSpeciesID = .dog
    public let displayName = "电子狗"
    public let bundleResourceName = "DogAssets"

    public init() {}

    public func animationAsset(for animation: PetAnimation) -> PetAnimationAsset {
        PetAnimationAsset(
            animation: animation,
            resourcePath: "DogAssets/\(animation.rawValue).riv",
            duration: defaultDuration(for: animation),
            loops: animation != .milestoneCelebrate
        )
    }

    public func soundAsset(for sound: PetSound) -> PetSoundAsset? {
        switch sound {
        case .barkHappy, .barkSad, .whine:
            return PetSoundAsset(sound: sound, resourcePath: "DogAssets/sounds/\(sound.rawValue).caf")
        default:
            return nil
        }
    }

    public func speechStyle() -> PetSpeechStyle {
        PetSpeechStyle(
            particle: "汪",
            ellipsisBias: 0.4,
            sentenceFragmentBias: 0.5,
            affectionExpression: "最喜欢主人了汪"
        )
    }

    public func decayProfile() -> PetDecayProfile {
        PetDecayProfile(hungerDecayMultiplier: 1.1, cleanlinessDecayMultiplier: 0.95)
    }

    private func defaultDuration(for animation: PetAnimation) -> TimeInterval {
        switch animation {
        case .idle: 2.5
        case .eat: 2.0
        case .exerciseCompanion: 3.5
        default: 2.0
        }
    }
}
