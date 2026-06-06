import Foundation
import EmoPetKit

/// V1 渐进式对话：词汇 → 短句 → 完整句（V2 可替换为 LLM + RAG）
public enum DialogueLevel: Int, Sendable, Comparable {
    case none = 0
    case vocabulary = 1   // 成长期 + 亲密度≥60
    case shortPhrase = 2
    case fullSentence = 3 // 青年期 + 亲密度≥75

    public static func < (lhs: DialogueLevel, rhs: DialogueLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public static func from(unlocked: UnlockedFeatures, stage: GrowthStage) -> DialogueLevel {
        if unlocked.fullDialogue { return .fullSentence }
        if unlocked.vocabularyBudding { return stage >= .growth ? .shortPhrase : .vocabulary }
        return .none
    }
}

public struct DialogueContext: Sendable {
    public let level: DialogueLevel
    public let speechStyle: PetSpeechStyle
    public let memoryTags: [MemoryTag]
    public let emotion: EmotionState
    public let topic: DialogueTopic

    public init(level: DialogueLevel, speechStyle: PetSpeechStyle, memoryTags: [MemoryTag], emotion: EmotionState, topic: DialogueTopic) {
        self.level = level
        self.speechStyle = speechStyle
        self.memoryTags = memoryTags
        self.emotion = emotion
        self.topic = topic
    }
}

public enum DialogueTopic: String, Sendable {
    case greeting
    case hunger
    case affection
    case memory
    case comfort
    case milestone
}

public struct TemplateDialogueEngine: Sendable {
    private let templates: [DialogueLevel: [DialogueTopic: [String]]]

    public init(templates: [DialogueLevel: [DialogueTopic: [String]]]) {
        self.templates = templates
    }

    public func generate(context: DialogueContext) -> String {
        guard context.level != .none else { return "……" }
        let pool = templates[context.level]?[context.topic] ?? ["……"]
        var line = pool.randomElement() ?? "……"
        line = applySpeechStyle(line, style: context.speechStyle, level: context.level)
        if context.topic == .memory, let tag = context.memoryTags.last {
            line = injectMemoryAnchor(line, tag: tag, level: context.level)
        }
        return line
    }

    private func applySpeechStyle(_ line: String, style: PetSpeechStyle, level: DialogueLevel) -> String {
        var result = line
        if level >= .shortPhrase, style.ellipsisBias > 0.5, !result.contains("……") {
            result = result.replacingOccurrences(of: "，", with: "……")
        }
        if level >= .vocabulary {
            result += style.particle
        }
        return result
    }

    private func injectMemoryAnchor(_ line: String, tag: MemoryTag, level: DialogueLevel) -> String {
        guard level >= .shortPhrase else { return line }
        return "记得……\(tag.summary)……\(line)"
    }
}

/// V2 扩展点：LLM + 宠物记忆向量 RAG
public protocol DialogueProvider: Sendable {
    func reply(context: DialogueContext, userMessage: String) async -> String
}

public struct TemplateDialogueProvider: DialogueProvider {
    private let engine: TemplateDialogueEngine

    public init(engine: TemplateDialogueEngine) {
        self.engine = engine
    }

    public func reply(context: DialogueContext, userMessage: String) async -> String {
        engine.generate(context: context)
    }
}
