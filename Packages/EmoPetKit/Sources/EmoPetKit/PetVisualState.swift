import Foundation

/// 卡通形象状态：不同生理/心理组合映射到不同视觉
public enum PetVisualState: String, Codable, Sendable, CaseIterable {
    case idle
    case happy
    case hungry
    case tired
    case dirty
    case sick
    case angry
    case cold
    case sleeping
    case reunion
    case playing
    case eating
}

public enum PetVisualStateResolver {
    public static func resolve(snapshot: PetSnapshot) -> PetVisualState {
        if snapshot.presence == .sleepWaiting { return .sleeping }
        if snapshot.presence == .reunionPending { return .reunion }
        if snapshot.sickness == .sick || snapshot.sickness == .treating { return .sick }
        if snapshot.emotion == .angry { return .angry }
        if snapshot.emotion == .cold { return .cold }
        if snapshot.stats.hunger < 40 { return .hungry }
        if snapshot.wasteNeedsCleaning || snapshot.stats.cleanliness < 40 { return .dirty }
        if snapshot.stats.hunger < 60 && snapshot.emotion == .wronged { return .tired }
        if snapshot.emotion == .happy { return .happy }
        return .idle
    }
}

public extension PetPlugin {
    func cartoonAssetName(for state: PetVisualState) -> String {
        "\(speciesID.rawValue)_\(state.rawValue)"
    }
}
