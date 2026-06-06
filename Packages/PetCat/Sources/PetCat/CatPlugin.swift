import Foundation
import EmoPetKit

public struct CatPlugin: PetPlugin, Sendable {
    public let speciesID: PetSpeciesID = .cat
    public let displayName = "电子猫"
    public let bundleResourceName = "CatAssets"

    public init() {}

    public func animationAsset(for animation: PetAnimation) -> PetAnimationAsset {
        PetAnimationAsset(
            animation: animation,
            resourcePath: "CatAssets/\(animation.rawValue).riv",
            duration: defaultDuration(for: animation),
            loops: animation != .milestoneCelebrate
        )
    }

    public func soundAsset(for sound: PetSound) -> PetSoundAsset? {
        switch sound {
        case .meowSoft, .meowHungry, .purr:
            return PetSoundAsset(sound: sound, resourcePath: "CatAssets/sounds/\(sound.rawValue).caf")
        default:
            return nil
        }
    }

    public func speechStyle() -> PetSpeechStyle {
        PetSpeechStyle(
            particle: "喵",
            ellipsisBias: 0.8,
            sentenceFragmentBias: 0.7,
            affectionExpression: "……喜欢你喵"
        )
    }

    public func decayProfile() -> PetDecayProfile { .standard }

    private func defaultDuration(for animation: PetAnimation) -> TimeInterval {
        switch animation {
        case .idle: 3.0
        case .eat: 2.5
        case .milestoneCelebrate: 4.0
        default: 2.0
        }
    }
}
