import Foundation
import EmoPetKit

/// 核心宠物引擎：统一驱动四大模块，与具体宠物形象无关
public final class PetEngine: @unchecked Sendable {
    public private(set) var snapshot: PetSnapshot
    private let policy: OfflinePolicy
    private var plugin: (any PetPlugin)?

    public init(snapshot: PetSnapshot, policy: OfflinePolicy = OfflinePolicy()) {
        self.snapshot = snapshot
        self.policy = policy
    }

    public func bind(plugin: any PetPlugin) {
        self.plugin = plugin
    }

    // MARK: - Session Lifecycle

    /// APP 打开时调用：处理离线时长、睡眠模式、数值衰减
    @discardableResult
    public func onAppOpen(now: Date = Date()) -> [PetEngineEvent] {
        var events: [PetEngineEvent] = []
        let offlineDuration = now.timeIntervalSince(snapshot.lastOpenedAt)

        if offlineDuration >= policy.sleepModeThreshold {
            if snapshot.presence != .sleepWaiting {
                snapshot.presence = .sleepWaiting
                events.append(.enteredSleepMode)
            }
            snapshot.presence = .reunionPending
            events.append(.reunionPending)
            addMemory(.reunion, summary: "主人回来了……等了好久")
        } else {
            snapshot.presence = .active
            events.append(contentsOf: applyDecay(from: snapshot.lastUpdatedAt, to: now))
        }

        snapshot.lastOpenedAt = now
        snapshot.lastUpdatedAt = now
        refreshGrowth(now: now)
        refreshUnlocks()
        refreshEmotionBaseline()
        return events
    }

    /// 定期 tick（前台运行时每 N 分钟）
    public func tick(now: Date = Date()) -> [PetEngineEvent] {
        guard snapshot.presence == .active else { return [] }
        let events = applyDecay(from: snapshot.lastUpdatedAt, to: now)
        snapshot.lastUpdatedAt = now
        evaluateSickness(now: now)
        refreshEmotionBaseline()
        return events
    }

    // MARK: - Physiological Actions

    public func feed(_ food: FoodType) -> [PetEngineEvent] {
        guard snapshot.presence == .active || snapshot.presence == .reunionPending else { return [] }
        snapshot.stats.hunger = (snapshot.stats.hunger + food.hungerRestore).clamped(to: 0...100)
        snapshot.stats.health = (snapshot.stats.health + food.healthDelta).clamped(to: 0...100)
        snapshot.stats.emotion = (snapshot.stats.emotion + food.emotionDelta).clamped(to: 0...100)
        if food == .snack {
            snapshot.stats.intimacy = (snapshot.stats.intimacy + 1).clamped(to: 0...100)
        }
        if snapshot.stats.hunger >= 30 { snapshot.hungerDangerSince = nil }
        snapshot.stats.growthXP += 1
        refreshUnlocks()
        return [.fed(food), .animation(.eat)]
    }

    public func bathe() -> [PetEngineEvent] {
        snapshot.stats.cleanliness = min(100, snapshot.stats.cleanliness + 40)
        snapshot.stats.emotion = min(100, snapshot.stats.emotion + 5)
        snapshot.cleanlinessDangerSince = nil
        snapshot.stats.growthXP += 0.5
        return [.bathed, .animation(.bath)]
    }

    public func cleanWaste() -> [PetEngineEvent] {
        snapshot.wasteNeedsCleaning = false
        snapshot.stats.emotion = min(100, snapshot.stats.emotion + 3)
        snapshot.stats.cleanliness = min(100, snapshot.stats.cleanliness + 5)
        return [.wasteCleaned, .animation(.cleanWaste)]
    }

    public func buyAndFeedMedicine() -> [PetEngineEvent] {
        guard snapshot.sickness == .sick || snapshot.sickness == .subHealthy else {
            return []
        }
        snapshot.sickness = .treating
        _ = feed(.medicine)
        return [.medicineGiven, .animation(.sick)]
    }

    public func completeReunion() -> [PetEngineEvent] {
        snapshot.presence = .active
        snapshot.emotion = .happy
        snapshot.stats.emotion = min(100, snapshot.stats.emotion + 15)
        snapshot.stats.intimacy = min(100, snapshot.stats.intimacy + 3)
        return [.reunionCelebration, .animation(.wakeUpReunion)]
    }

    // MARK: - Emotional Actions

    public func pet(duration: TimeInterval = 2.0) -> [PetEngineEvent] {
        guard snapshot.emotion.allowsPetting else {
            return [.interactionRejected(reason: snapshot.emotion), .animation(snapshot.emotion == .angry ? .angry : .cold)]
        }
        snapshot.stats.intimacy = min(100, snapshot.stats.intimacy + 2)
        snapshot.stats.emotion = min(100, snapshot.stats.emotion + 8)
        improveEmotion()
        return [.petted(duration: duration), .animation(.petting), .haptic(.light)]
    }

    public func apologize() -> [PetEngineEvent] {
        guard snapshot.emotion.requiresApology else { return [] }
        snapshot.emotion = .wronged
        snapshot.stats.emotion = min(100, snapshot.stats.emotion + 10)
        addMemory(.gentleApology, summary: "主人道歉了")
        return [.apologyAccepted, .animation(.apologize)]
    }

    public func playMiniGame() -> [PetEngineEvent] {
        snapshot.stats.intimacy = min(100, snapshot.stats.intimacy + 3)
        snapshot.stats.emotion = min(100, snapshot.stats.emotion + 12)
        snapshot.stats.growthXP += 2
        addMemory(.longPlaySession, summary: "今天玩了好久")
        improveEmotion()
        refreshUnlocks()
        return [.playedTogether, .animation(.happy)]
    }

    // MARK: - Private Engine Logic

    private func applyDecay(from: Date, to: Date) -> [PetEngineEvent] {
        guard snapshot.presence == .active else { return [] }
        var events: [PetEngineEvent] = []
        let hours = to.timeIntervalSince(from) / 3600
        guard hours > 0 else { return [] }

        let hungerMult = plugin?.decayProfile().hungerDecayMultiplier ?? 1.0
        let cleanMult = plugin?.decayProfile().cleanlinessDecayMultiplier ?? 1.0

        // 饥饿：每 2~4 小时 -10（取 3h 均值）
        let hungerTicks = hours / 3.0 * hungerMult
        snapshot.stats.hunger = (snapshot.stats.hunger - hungerTicks * 10).clamped(to: 0...100)

        // 清洁：每 8~12 小时 -10（取 10h 均值）
        let cleanTicks = hours / 10.0 * cleanMult
        snapshot.stats.cleanliness = (snapshot.stats.cleanliness - cleanTicks * 10).clamped(to: 0...100)

        // 粪便随机产生（约每 12 小时概率）
        if hours >= 8, Double.random(in: 0...1) < min(1.0, hours / 12.0 * 0.6) {
            snapshot.wasteNeedsCleaning = true
            events.append(.wasteProduced)
        }

        trackDangerZones(now: to)
        applyGracePunishments(now: to)
        evaluateSickness(now: to)

        if snapshot.stats.hunger < 30 {
            events.append(.signalHungerLow)
        }
        if snapshot.wasteNeedsCleaning {
            snapshot.stats.emotion = max(0, snapshot.stats.emotion - 2)
        }

        return events
    }

    private func trackDangerZones(now: Date) {
        if snapshot.stats.hunger < 30 {
            snapshot.hungerDangerSince = snapshot.hungerDangerSince ?? now
        } else {
            snapshot.hungerDangerSince = nil
        }
        if snapshot.stats.cleanliness < 30 {
            snapshot.cleanlinessDangerSince = snapshot.cleanlinessDangerSince ?? now
        } else {
            snapshot.cleanlinessDangerSince = nil
        }
    }

    private func applyGracePunishments(now: Date) {
        if let since = snapshot.hungerDangerSince,
           now.timeIntervalSince(since) > policy.hungerGraceWindow {
            snapshot.stats.intimacy = max(0, snapshot.stats.intimacy - 5)
            snapshot.hungerDangerSince = now
            addMemory(.forgotFeeding, summary: "主人忘记喂饭了")
            worsenEmotion()
        }
        if let since = snapshot.cleanlinessDangerSince,
           now.timeIntervalSince(since) > policy.cleanlinessGraceWindow {
            snapshot.stats.intimacy = max(0, snapshot.stats.intimacy - 3)
            snapshot.stats.emotion = max(0, snapshot.stats.emotion - 10)
            snapshot.cleanlinessDangerSince = now
            worsenEmotion()
        }
    }

    private func evaluateSickness(now: Date) {
        let hungerLow = snapshot.stats.hunger < 20
        let cleanLow = snapshot.stats.cleanliness < 20

        if hungerLow && cleanLow {
            if snapshot.lowStatsSince == nil { snapshot.lowStatsSince = now }
            if let since = snapshot.lowStatsSince,
               now.timeIntervalSince(since) > policy.sicknessPersistThreshold,
               snapshot.sickness == .healthy || snapshot.sickness == .subHealthy {
                snapshot.sickness = .sick
                snapshot.stats.health = max(0, snapshot.stats.health - 15)
            }
        } else {
            snapshot.lowStatsSince = nil
            if snapshot.sickness == .treating {
                snapshot.sickness = .recovering
            } else if snapshot.sickness == .recovering {
                snapshot.sickness = .healthy
                snapshot.stats.health = min(100, snapshot.stats.health + 20)
            } else if snapshot.sickness == .subHealthy, !hungerLow, !cleanLow {
                snapshot.sickness = .healthy
            }
        }

        if snapshot.sickness == .sick {
            snapshot.emotion = .wronged
        }
    }

    private func refreshGrowth(now: Date) {
        let days = Calendar.current.dateComponents([.day], from: snapshot.createdAt, to: now).day ?? 0
        snapshot.ageDays = max(snapshot.ageDays, days)
        snapshot.stage = GrowthStage.from(ageDays: snapshot.ageDays)
    }

    private func refreshUnlocks() {
        snapshot.unlocked.applyUnlocks(
            stage: snapshot.stage,
            intimacy: snapshot.stats.intimacy,
            ageDays: snapshot.ageDays
        )
    }

    private func refreshEmotionBaseline() {
        let tags = snapshot.memoryTags.suffix(10)
        var baseline = snapshot.stats.emotion

        for tag in tags {
            switch tag.category {
            case .forgotFeeding, .neglectInteraction:
                baseline -= 5 * tag.weight
            case .longPlaySession, .gentleApology, .reunion, .studyTogether, .exerciseTogether:
                baseline += 4 * tag.weight
            case .milestone:
                baseline += 6 * tag.weight
            }
        }

        snapshot.stats.emotion = baseline.clamped(to: 0...100)
        mapEmotionState()
    }

    private func mapEmotionState() {
        let e = snapshot.stats.emotion
        let i = snapshot.stats.intimacy
        switch (e, i) {
        case (75...100, _): snapshot.emotion = .happy
        case (50..<75, _): snapshot.emotion = .normal
        case (35..<50, _): snapshot.emotion = .wronged
        case (20..<35, 40...): snapshot.emotion = .angry
        default: snapshot.emotion = .cold
        }
    }

    private func improveEmotion() {
        if snapshot.emotion == .cold { snapshot.emotion = .wronged }
        else if snapshot.emotion == .wronged { snapshot.emotion = .normal }
        else if snapshot.emotion == .normal { snapshot.emotion = .happy }
    }

    private func worsenEmotion() {
        if snapshot.emotion == .happy { snapshot.emotion = .normal }
        else if snapshot.emotion == .normal { snapshot.emotion = .wronged }
        else if snapshot.emotion == .wronged { snapshot.emotion = .angry }
        else { snapshot.emotion = .cold }
    }

    private func addMemory(_ category: MemoryCategory, summary: String) {
        let tag = MemoryTag(category: category, summary: summary)
        snapshot.memoryTags.append(tag)
        if snapshot.memoryTags.count > 200 {
            snapshot.memoryTags.removeFirst(snapshot.memoryTags.count - 200)
        }
    }
}

public enum PetEngineEvent: Sendable, Equatable {
    case enteredSleepMode
    case reunionPending
    case reunionCelebration
    case fed(FoodType)
    case bathed
    case wasteProduced
    case wasteCleaned
    case medicineGiven
    case signalHungerLow
    case petted(duration: TimeInterval)
    case interactionRejected(reason: EmotionState)
    case apologyAccepted
    case playedTogether
    case animation(PetAnimation)
    case haptic(HapticKind)
    case featureUnlocked(String)
}

public enum HapticKind: Sendable {
    case light, medium, success
}
