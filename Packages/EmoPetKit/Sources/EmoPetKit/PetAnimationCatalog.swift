import Foundation

// MARK: - 2.5D 视频素材命名规范（Blender 烘焙 → Bundle）

/// 循环待机状态（首尾帧一致，用于 AVPlayerLooper）
public enum PetLoopState: String, Sendable, CaseIterable {
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

    public var loopFileSuffix: String {
        switch self {
        case .idle: return "Normal"
        case .happy: return "Happy"
        case .hungry: return "Hungry"
        case .tired: return "Tired"
        case .dirty: return "Dirty"
        case .sick: return "Sick"
        case .angry: return "Angry"
        case .cold: return "Cold"
        case .sleeping: return "Sleeping"
        case .reunion: return "Reunion"
        case .playing: return "Playing"
        case .eating: return "Eating"
        }
    }

    public var fileBaseName: String { "Idle_\(loopFileSuffix)" }

    public static func from(visual: PetVisualState) -> PetLoopState {
        switch visual {
        case .idle: return .idle
        case .happy: return .happy
        case .hungry: return .hungry
        case .tired: return .tired
        case .dirty: return .dirty
        case .sick: return .sick
        case .angry: return .angry
        case .cold: return .cold
        case .sleeping: return .sleeping
        case .reunion: return .reunion
        case .playing: return .playing
        case .eating: return .eating
        }
    }
}

/// 一次性动作（喂食、洗澡、对话、助手等），播放完回到当前循环
public enum PetOneShotAction: String, Sendable, CaseIterable {
    // 生理 + 互动
    case feed
    case snack
    case bath
    case clean
    case pet
    case play
    case apologize
    case medicine
    case eatFinish
    // 对话模块
    case talkShort
    case talkFull
    case memoryRecall
    // 生活助手模块
    case alarmWake
    case studyCheer
    case exerciseCheer
    case scheduleNudge

    public var fileBaseName: String {
        switch self {
        case .feed: return "Action_Feed"
        case .snack: return "Action_Snack"
        case .bath: return "Action_Bath"
        case .clean: return "Action_Clean"
        case .pet: return "Action_Pet"
        case .play: return "Action_Play"
        case .apologize: return "Action_Apologize"
        case .medicine: return "Action_Medicine"
        case .eatFinish: return "Action_EatFinish"
        case .talkShort: return "Action_Talk_Short"
        case .talkFull: return "Action_Talk_Full"
        case .memoryRecall: return "Action_Memory_Recall"
        case .alarmWake: return "Action_Alarm_Wake"
        case .studyCheer: return "Action_Study_Cheer"
        case .exerciseCheer: return "Action_Exercise_Cheer"
        case .scheduleNudge: return "Action_Schedule_Nudge"
        }
    }

    public var module: PetModuleTab {
        switch self {
        case .feed, .snack, .bath, .clean, .medicine, .eatFinish:
            return .physiological
        case .pet, .play, .apologize:
            return .interaction
        case .talkShort, .talkFull, .memoryRecall:
            return .dialogue
        case .alarmWake, .studyCheer, .exerciseCheer, .scheduleNudge:
            return .assistant
        }
    }
}

/// 对话/助手场景的专用 Idle 循环（非生理状态机驱动）
public enum PetSpecialLoop: String, Sendable, CaseIterable {
    case listening
    case studyCompanion
    case exerciseCompanion

    public var fileBaseName: String {
        switch self {
        case .listening: return "Idle_Listening"
        case .studyCompanion: return "Idle_Study_Companion"
        case .exerciseCompanion: return "Idle_Exercise_Companion"
        }
    }

    public var module: PetModuleTab {
        switch self {
        case .listening: return .dialogue
        case .studyCompanion, .exerciseCompanion: return .assistant
        }
    }
}

public struct PetVideoClip: Sendable, Equatable {
    public let relativePath: String
    public let fileExtension: String
    public let loops: Bool

    public init(relativePath: String, fileExtension: String = "mov", loops: Bool = true) {
        self.relativePath = relativePath
        self.fileExtension = fileExtension
        self.loops = loops
    }

    public var bundleSubpath: String { "\(relativePath).\(fileExtension)" }
}

public enum RoomTimeOfDay: String, Sendable, CaseIterable {
    case day
    case dusk
    case night

    public static func current(calendar: Calendar = .current, date: Date = Date()) -> RoomTimeOfDay {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 6..<17: return .day
        case 17..<20: return .dusk
        default: return .night
        }
    }

    public var backgroundAssetName: String { "tuscany_\(rawValue)" }
}

public enum PetAnimationCatalog {
    private static let videoExt = "mov"

    public static func idleLoop(species: PetSpeciesID, state: PetLoopState) -> PetVideoClip {
        PetVideoClip(
            relativePath: "\(species.rawValue)/\(state.fileBaseName)",
            fileExtension: videoExt,
            loops: true
        )
    }

    public static func idleLoop(visual: PetVisualState, species: PetSpeciesID) -> PetVideoClip {
        idleLoop(species: species, state: .from(visual: visual))
    }

    /// 过渡：FromState_To_ToState，仅播放一次
    public static func transition(
        from: PetLoopState,
        to: PetLoopState,
        species: PetSpeciesID
    ) -> PetVideoClip? {
        guard from != to else { return nil }
        return PetVideoClip(
            relativePath: "\(species.rawValue)/\(from.loopFileSuffix)_To_\(to.loopFileSuffix)",
            fileExtension: videoExt,
            loops: false
        )
    }

    public static func transition(
        fromVisual: PetVisualState,
        toVisual: PetVisualState,
        species: PetSpeciesID
    ) -> PetVideoClip? {
        transition(
            from: .from(visual: fromVisual),
            to: .from(visual: toVisual),
            species: species
        )
    }

    public static func oneShot(_ action: PetOneShotAction, species: PetSpeciesID) -> PetVideoClip {
        PetVideoClip(
            relativePath: "\(species.rawValue)/\(action.fileBaseName)",
            fileExtension: videoExt,
            loops: false
        )
    }

    public static func specialLoop(_ loop: PetSpecialLoop, species: PetSpeciesID) -> PetVideoClip {
        PetVideoClip(
            relativePath: "\(species.rawValue)/\(loop.fileBaseName)",
            fileExtension: videoExt,
            loops: true
        )
    }

    /// P0 MVP 全部片段（用于预加载与 CSV 清单对齐）
    public static func mvpClips(species: PetSpeciesID) -> [PetVideoClip] {
        var clips: [PetVideoClip] = []
        for state in PetLoopState.allCases where mvpIdleStates.contains(state) {
            clips.append(idleLoop(species: species, state: state))
        }
        for to in PetLoopState.allCases where to != .idle {
            if let t = transition(from: .idle, to: to, species: species) {
                clips.append(t)
            }
        }
        for action in PetOneShotAction.allCases where mvpOneShotActions.contains(action) {
            clips.append(oneShot(action, species: species))
        }
        return clips
    }

    public static let mvpIdleStates: Set<PetLoopState> = [.idle, .happy, .hungry, .dirty, .sick]

    public static let mvpOneShotActions: Set<PetOneShotAction> = [
        .feed, .snack, .bath, .clean, .pet, .play,
    ]

    public static func hasBundledAsset(_ clip: PetVideoClip, species: PetSpeciesID, bundle: Bundle = .main) -> Bool {
        resolveBundledURL(for: clip, species: species, bundle: bundle) != nil
    }

    /// 查找 Bundle 内视频：精确路径 → 同物种默认 Idle → mp4 扩展名
    public static func resolveBundledURL(
        for clip: PetVideoClip,
        species: PetSpeciesID,
        allowSpeciesFallback: Bool = true,
        bundle: Bundle = .main
    ) -> URL? {
        if let exact = bundleURL(for: clip, bundle: bundle) { return exact }

        if allowSpeciesFallback {
            let defaultIdle = idleLoop(species: species, state: .idle)
            if clip.relativePath != defaultIdle.relativePath,
               let fallback = bundleURL(for: defaultIdle, bundle: bundle) {
                return fallback
            }
        }

        if clip.fileExtension != "mp4",
           let mp4 = bundleURL(
               for: PetVideoClip(relativePath: clip.relativePath, fileExtension: "mp4", loops: clip.loops),
               bundle: bundle
           ) {
            return mp4
        }

        return nil
    }

    private static func bundleURL(for clip: PetVideoClip, bundle: Bundle) -> URL? {
        bundle.url(
            forResource: clip.relativePath,
            withExtension: clip.fileExtension,
            subdirectory: "PetVideos"
        )
    }

    /// App 启动预加载的核心片段
    public static func preloadClips(species: PetSpeciesID) -> [PetVideoClip] {
        mvpClips(species: species)
    }
}

public enum PetModuleTab: String, Sendable, CaseIterable {
    case physiological
    case interaction
    case dialogue
    case assistant

    public var l10nKey: String { "module.\(rawValue)" }
}
