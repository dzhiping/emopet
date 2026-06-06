import EmoPetDialogue
import EmoPetKit

public enum DefaultDialogueTemplates {
    public static let shared: [DialogueLevel: [DialogueTopic: [String]]] = [
        .vocabulary: [
            .greeting: ["嗨", "嗯", "在"],
            .hunger: ["饿", "吃"],
            .affection: ["喜欢", "乖"],
            .memory: ["记得"],
            .comfort: ["乖", "没事"],
            .milestone: ["长大"],
        ],
        .shortPhrase: [
            .greeting: ["主人……在呀", "今天……也好", "嗯……"],
            .hunger: ["肚子……空空的", "想吃东西", "饿了……"],
            .affection: ["喜欢你", "靠着主人", "好温暖"],
            .memory: ["上周……玩了好久", "记得……一起睡"],
            .comfort: ["没事的……", "我在呢", "慢慢来"],
            .milestone: ["我会说话了", "新阶段"],
        ],
        .fullSentence: [
            .greeting: ["今天……吃了很多……很满足", "主人回来……我就安心了"],
            .hunger: ["要是……现在有小鱼干……就好了", "肚子叫……但不想催主人"],
            .affection: ["最喜欢……靠在主人旁边", "被摸头……会融化"],
            .memory: ["你上周陪我玩了好久……我还记得", "那天洗澡……虽然怕但很开心"],
            .comfort: ["今天不顺利吗……我陪你", "慢慢来……不着急"],
            .milestone: ["谢谢你……陪我长大", "解锁新能力……好开心"],
        ],
    ]
}
