# EmoPet · 电子宠物情感陪伴 APP

离线优先的 iOS 情感陪伴型电子宠物应用。核心引擎统一，猫/狗形象以独立 Plugin 包接入，动画资源可单独更新。

## 架构概览

```
App/EmoPet              SwiftUI 壳层
Packages/
  EmoPetKit             共享模型、PetPlugin 协议、通知文案库
  EmoPetCore            生理/情感引擎、衰减、睡眠模式、成长解锁
  EmoPetPersonality     用户个性评估（本地）
  EmoPetPersistence     JSON 本地存储 + 导出/导入
  EmoPetDialogue        V1 模板渐进对话（V2 LLM 扩展点）
  EmoPetAssistant       生活助手（成熟期解锁）
  PetCat / PetDog       宠物形象插件（动画/音效/说话风格）
```

### 设计原则（已实现于引擎）

| 原则 | 实现 |
|------|------|
| 离线运行 | 全部状态 JSON 本地持久化，无网络依赖 |
| 睡眠模式 | 48h 未打开 → 数值冻结 → 重逢剧情 |
| 解锁不可逆 | `UnlockedFeatures.applyUnlocks` 只升不降 |
| 弹性惩罚 | 饥饿 4h / 清洁 12h 宽限窗口 |
| 生病多条件 | 饥饿 & 清洁同时 <20 且持续 6h |
| 文案轮换 | 每类 5~8 条，`RotatingCopyLibrary` |
| 形象解耦 | `PetPlugin` 协议，核心与 `.riv` 资源分离 |

## 打开项目

双击或在 Xcode 中打开：

```
EmoPet.xcodeproj
```

路径示例：`/Users/king/Documents/App project/emopet/EmoPet.xcodeproj`

首次打开后：
1. 选择 **EmoPet** Target → **Signing & Capabilities** → 设置你的 **Team**
2. 选择模拟器或真机，点击 **Run (⌘R)**

工程已自动关联 `Packages/` 下全部 8 个本地 Swift Package，无需手动添加依赖。

## 运行测试

```bash
cd Packages/EmoPetCore && swift test
```

## V2 路线图

- [ ] 本地 LLM + 宠物记忆向量 RAG（`DialogueProvider` 协议已预留）
- [ ] Rive/Lottie 动画资源接入 `PetAnimationAsset`
- [ ] 本地推送通知（`NotificationScheduler` + UNUserNotificationCenter）
- [ ] Core Haptics 抚摸反馈
- [ ] 宠物形象热更新 Bundle（无需发版核心引擎）

## 成长阶段

| 阶段 | 天数 | 解锁 |
|------|------|------|
| 幼崽期 | 0–21 | 基础照料 + 情感互动 |
| 成长期 | 22–45 | 亲密度≥60 → 词汇萌芽对话 |
| 青年期 | 46–90 | 亲密度≥75 → 完整句对话 |
| 成熟期 | 90+ | 亲密度≥85 → 生活助手 |
