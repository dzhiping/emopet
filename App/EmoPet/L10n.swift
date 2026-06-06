import EmoPetKit

enum L10n {
    static func text(_ key: String, language: PetLanguage) -> String {
        table[language]?[key] ?? table[.chinese]?[key] ?? key
    }

    private static let table: [PetLanguage: [String: String]] = [
        .chinese: [
            "app.title": "EmoPet",
            "register.title": "欢迎加入 EmoPet",
            "register.subtitle": "创建你的本地账户，数据仅保存在本机",
            "field.name": "姓名",
            "field.password": "密码",
            "field.confirmPassword": "确认密码",
            "button.register": "注册并开始",
            "login.title": "欢迎回来",
            "login.subtitle": "首次登录后将自动记住密码，下次打开无需再输入",
            "button.login": "登录",
            "adoption.title": "领养宠物",
            "adoption.subtitle": "每位主人最多领养两只不同种类的宠物",
            "field.petName": "宠物名字",
            "field.species": "宠物类型",
            "field.gender": "期望性别",
            "field.personality": "期望个性",
            "field.language": "交流语言",
            "species.cat": "电子猫",
            "species.dog": "电子狗",
            "gender.male": "男孩",
            "gender.female": "女孩",
            "gender.neutral": "不限",
            "personality.gentle": "温柔",
            "personality.playful": "活泼",
            "personality.quiet": "安静",
            "personality.clingy": "粘人",
            "language.zh": "中文",
            "language.en": "English",
            "language.ja": "日本語",
            "button.adopt": "确认领养",
            "button.adoptAnother": "再领养一只",
            "button.skipAdoption": "稍后再说",
            "stat.hunger": "饱腹",
            "stat.cleanliness": "清洁",
            "stat.health": "健康",
            "stat.intimacy": "亲密",
            "stat.emotion": "心情",
            "stat.hint.excellent": "状态极佳",
            "stat.hint.good": "状态良好",
            "stat.hint.fair": "需要关注",
            "stat.hint.low": "状态偏低",
            "stat.hint.poor": "状态较差",
            "stat.hint.critical": "非常危急",
            "emotion.happy": "开心",
            "emotion.normal": "普通",
            "emotion.wronged": "委屈",
            "emotion.angry": "生气",
            "emotion.cold": "冷淡",
            "stage.cub": "幼崽期",
            "stage.growth": "成长期",
            "stage.youth": "青年期",
            "stage.mature": "成熟期",
            "error.passwordMismatch": "两次密码不一致",
            "error.invalidRegistration": "请填写姓名和至少4位密码",
            "error.wrongPassword": "密码错误",
            "error.petLimit": "已达到领养上限或该种类已领养",
            "error.petNameRequired": "请填写宠物名字",
            "menu.more": "更多",
            "menu.switchPet": "切换宠物",
            "menu.backup": "数据备份",
            "module.physiological": "生理",
            "module.interaction": "互动",
            "module.dialogue": "对话",
            "module.assistant": "助手",
            "button.reunion": "重逢",
            "greeting.user": "你好，%@",
        ],
        .english: [
            "app.title": "EmoPet",
            "register.title": "Welcome to EmoPet",
            "register.subtitle": "Create a local account — data stays on this device",
            "field.name": "Name",
            "field.password": "Password",
            "field.confirmPassword": "Confirm Password",
            "button.register": "Register",
            "login.title": "Welcome Back",
            "login.subtitle": "Your password will be saved after first login for automatic sign-in",
            "button.login": "Log In",
            "adoption.title": "Adopt a Pet",
            "adoption.subtitle": "Up to two pets of different species",
            "field.petName": "Pet Name",
            "field.species": "Species",
            "field.gender": "Gender",
            "field.personality": "Personality",
            "field.language": "Language",
            "species.cat": "Digital Cat",
            "species.dog": "Digital Dog",
            "gender.male": "Boy",
            "gender.female": "Girl",
            "gender.neutral": "Any",
            "personality.gentle": "Gentle",
            "personality.playful": "Playful",
            "personality.quiet": "Quiet",
            "personality.clingy": "Clingy",
            "language.zh": "中文",
            "language.en": "English",
            "language.ja": "日本語",
            "button.adopt": "Adopt",
            "button.adoptAnother": "Adopt Another",
            "button.skipAdoption": "Not Now",
            "stat.hunger": "Fullness",
            "stat.cleanliness": "Clean",
            "stat.health": "Health",
            "stat.intimacy": "Bond",
            "stat.emotion": "Mood",
            "stat.hint.excellent": "Excellent",
            "stat.hint.good": "Good",
            "stat.hint.fair": "Fair",
            "stat.hint.low": "Low",
            "stat.hint.poor": "Poor",
            "stat.hint.critical": "Critical",
            "emotion.happy": "Happy",
            "emotion.normal": "Calm",
            "emotion.wronged": "Sad",
            "emotion.angry": "Angry",
            "emotion.cold": "Cold",
            "stage.cub": "Cub",
            "stage.growth": "Growth",
            "stage.youth": "Youth",
            "stage.mature": "Mature",
            "error.passwordMismatch": "Passwords do not match",
            "error.invalidRegistration": "Enter name and password (min 4 chars)",
            "error.wrongPassword": "Wrong password",
            "error.petLimit": "Adoption limit reached or species taken",
            "error.petNameRequired": "Pet name required",
            "menu.more": "More",
            "menu.switchPet": "Switch Pet",
            "menu.backup": "Backup",
            "module.physiological": "Care",
            "module.interaction": "Play",
            "module.dialogue": "Chat",
            "module.assistant": "Helper",
            "button.reunion": "Reunion",
            "greeting.user": "Hi, %@",
        ],
        .japanese: [
            "app.title": "EmoPet",
            "register.title": "EmoPet へようこそ",
            "register.subtitle": "ローカルアカウントを作成（データは端末内のみ）",
            "field.name": "名前",
            "field.password": "パスワード",
            "field.confirmPassword": "確認",
            "button.register": "登録",
            "login.title": "おかえりなさい",
            "login.subtitle": "初回ログイン後、次回から自動ログインします",
            "button.login": "ログイン",
            "adoption.title": "ペットを迎える",
            "adoption.subtitle": "異なる種類最大2匹まで",
            "field.petName": "ペットの名前",
            "field.species": "種類",
            "field.gender": "性別",
            "field.personality": "性格",
            "field.language": "言語",
            "species.cat": "ネコ",
            "species.dog": "イヌ",
            "gender.male": "男の子",
            "gender.female": "女の子",
            "gender.neutral": "こだわらない",
            "personality.gentle": "おとなしい",
            "personality.playful": "元気",
            "personality.quiet": "静か",
            "personality.clingy": "甘えん坊",
            "language.zh": "中文",
            "language.en": "English",
            "language.ja": "日本語",
            "button.adopt": "迎える",
            "button.adoptAnother": "もう一匹",
            "button.skipAdoption": "あとで",
            "stat.hunger": "満腹",
            "stat.cleanliness": "清潔",
            "stat.health": "健康",
            "stat.intimacy": "親密度",
            "stat.emotion": "気分",
            "stat.hint.excellent": "とても良い",
            "stat.hint.good": "良い",
            "stat.hint.fair": "注意",
            "stat.hint.low": "低い",
            "stat.hint.poor": "悪い",
            "stat.hint.critical": "危険",
            "emotion.happy": "うれしい",
            "emotion.normal": "普通",
            "emotion.wronged": "さびしい",
            "emotion.angry": "おこり",
            "emotion.cold": "つれない",
            "stage.cub": "幼少期",
            "stage.growth": "成長期",
            "stage.youth": "青年期",
            "stage.mature": "成熟期",
            "error.passwordMismatch": "パスワードが一致しません",
            "error.invalidRegistration": "名前と4文字以上のパスワード",
            "error.wrongPassword": "パスワードが違います",
            "error.petLimit": "上限または同種類済み",
            "error.petNameRequired": "名前を入力",
            "menu.more": "その他",
            "menu.switchPet": "ペット切替",
            "menu.backup": "バックアップ",
            "module.physiological": "生理",
            "module.interaction": "互动",
            "module.dialogue": "对话",
            "module.assistant": "助手",
            "button.reunion": "再会",
            "greeting.user": "こんにちは、%@",
        ],
    ]
}

extension PetLanguage {
    var l10nKey: String {
        switch self {
        case .chinese: return "language.zh"
        case .english: return "language.en"
        case .japanese: return "language.ja"
        }
    }
}

extension PetSpeciesID {
    var l10nKey: String { "species.\(rawValue)" }
}

extension PetGender {
    var l10nKey: String { labelKey }
}

extension ExpectedPetPersonality {
    var l10nKey: String { labelKey }
}

extension StatKind {
    var l10nKey: String { "stat.\(rawValue)" }
}

extension EmotionState {
    var l10nKey: String { "emotion.\(rawValue)" }
}

extension GrowthStage {
    var l10nKey: String {
        switch self {
        case .cub: return "stage.cub"
        case .growth: return "stage.growth"
        case .youth: return "stage.youth"
        case .mature: return "stage.mature"
        }
    }
}
