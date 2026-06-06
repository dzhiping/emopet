# EmoPet 2.5D 视频素材完整清单

> 适用对象：3D 美术 / Blender 渲染 / 外包验收  
> 对应代码：`PetAnimationCatalog.swift`、`PetVisualState.swift`  
> 物种目录：`PetVideos/cat/`、`PetVideos/dog/`（文件名**完全一致**，仅宠物模型不同）

---

## 一、技术规格（强制）

| 项目 | 要求 |
|------|------|
| 格式 | **HEVC (H.265) + Alpha 通道** |
| 容器 | `.mov`（禁止普通无 Alpha 的 MP4） |
| 宠物层画布 | **800 × 800 px** 正方形，透明背景 |
| 宠物占画面 | 高度约 **65%–75%**，居中，留足地面阴影空间 |
| 帧率 | **30 fps**（推荐）或 24 fps（全项目统一） |
| 循环 Idle | **首尾帧像素级一致**，可无缝 Loop |
| 过渡 Transition | 单次播放，**第一帧 = 上一 Idle 尾帧**，**最后一帧 = 下一 Idle 首帧** |
| 动作 Action | 单次播放，结束帧衔接当前 Idle 首帧 |
| 色彩空间 | sRGB，避免过曝高光溢出 |

### Blender 导出检查项

- [ ] 编码 H.265，勾选 **Export Alpha**
- [ ] 仅渲染宠物（无背景），Alpha 全透明
- [ ] 循环片段做「首帧 = 尾帧」验证
- [ ] 文件大小：单段 Idle 建议 **≤ 3 MB**，Action **≤ 5 MB**

---

## 二、背景层（非视频，Assets.xcassets）

| 文件名 | 用途 | 尺寸建议 | 优先级 |
|--------|------|----------|--------|
| `tuscany_day` | 白天客厅 | 1920×1080 或 iPhone 长宽比 | P0 |
| `tuscany_dusk` | 黄昏 | 同上 | P1 |
| `tuscany_night` | 夜晚 | 同上 | P1 |

**场景要素（托斯卡纳风格）：** 泥土色墙面、深色木梁、拱形窗、远景缓坡、暖色地砖。  
**进阶（可选）：** 2–3 帧微动 WebP（窗帘轻动、壁炉光 flicker），包体需控制。

---

## 三、循环待机 Idle（12 种 × 2 物种 = 24 文件）

**命名：** `Idle_{状态}.mov`  
**路径示例：** `PetVideos/cat/Idle_Normal.mov`

| 文件名 | 模块 | 触发条件（游戏内） | 动画描述参考 | 优先级 |
|--------|------|-------------------|-------------|--------|
| `Idle_Normal.mov` | 通用 | 默认健康状态 | 端坐/趴卧，呼吸，偶尔眨眼、摇尾/竖耳 | **P0** |
| `Idle_Happy.mov` | 互动 | 情绪=开心 | 摇尾、蹭地、眼睛弯月 | **P0** |
| `Idle_Hungry.mov` | 生理 | 饥饿值偏低 | 趴下、眼泛泪、望食盆方向 | **P0** |
| `Idle_Tired.mov` | 生理/情感 | 委屈+略饿 | 打盹、半闭眼、无精神 | P1 |
| `Idle_Dirty.mov` | 生理 | 清洁度低/有粪便 | 闻身上、嫌弃表情、略后退 | **P0** |
| `Idle_Sick.mov` | 生理 | 生病/治疗中 | 无精打采、贴退热贴/虚弱姿态 | **P0** |
| `Idle_Angry.mov` | 互动 | 情绪=生气 | 背对、炸毛/低吼、拒绝靠近 | P1 |
| `Idle_Cold.mov` | 互动 | 情绪=冷淡 | 蜷缩角落、不看不理 | P1 |
| `Idle_Sleeping.mov` | 生理 | 48h+ 离线睡眠模式 | 闭眼睡觉，轻微呼吸 | P1 |
| `Idle_Reunion.mov` | 互动 | 主人久别回归 | 睁眼、站起、小步靠近 | P1 |
| `Idle_Playing.mov` | 互动 | 玩耍后/高亲密 | 扑腾、叼玩具、绕圈 | P1 |
| `Idle_Eating.mov` | 生理 | 进食中（可选挂接） | 低头吃食、咀嚼循环 | P2 |

### 猫 vs 狗差异化提示

| 状态 | 猫 | 狗 |
|------|----|----|
| Happy | 踩奶、慢眨眼 | 摇尾、吐舌 |
| Hungry | 喵口型微张 | 耷耳、哼声嘴型 |
| Angry | 飞机耳、尾甩 | 低吼、毛微炸 |
| Reunion | 竖尾迎门 | 扑跳、甩尾 |

---

## 四、过渡 Transition（状态切换，单次播放）

**命名：** `{From}_To_{To}.mov`（状态名用 Idle 后缀，**不含** `Idle_` 前缀）  
**路径示例：** `PetVideos/cat/Normal_To_Hungry.mov`

### P0 必做（11 条 × 2 物种 = 22 文件）

从 **Normal** 出发到所有其他状态（玩家最常见路径）：

```
Normal_To_Happy.mov
Normal_To_Hungry.mov
Normal_To_Tired.mov
Normal_To_Dirty.mov
Normal_To_Sick.mov
Normal_To_Angry.mov
Normal_To_Cold.mov
Normal_To_Sleeping.mov
Normal_To_Reunion.mov
Normal_To_Playing.mov
Normal_To_Eating.mov
```

### P1 推荐（高频互切，16 条 × 2 物种 = 32 文件）

```
Hungry_To_Normal.mov      Sick_To_Normal.mov
Dirty_To_Normal.mov       Happy_To_Normal.mov
Angry_To_Normal.mov       Cold_To_Normal.mov
Reunion_To_Happy.mov      Sleeping_To_Reunion.mov
Hungry_To_Eating.mov      Eating_To_Happy.mov
Dirty_To_Angry.mov        Sick_To_Tired.mov
Happy_To_Playing.mov      Playing_To_Happy.mov
Normal_To_Sick.mov        (若 P0 已做可跳过)
Hungry_To_Tired.mov
Sick_To_Hungry.mov
Angry_To_Cold.mov
Cold_To_Happy.mov
```

### P2 完整矩阵（可选，上线后按需补）

12 状态两两互切，理论最多 **12 × 11 = 132** 条/物种。  
**策略：** 仅补 Analytics 显示的高频切换对，其余由 App **降级**（直接切 Idle，无过渡）。

---

## 五、一次性动作 Action（用户点击触发）

**命名：** `Action_{动作名}.mov`  
**路径示例：** `PetVideos/cat/Action_Feed.mov`  
**播放逻辑：** 播完 → 回到当前 `Idle_*` 循环

### 5.1 生理模块（P0，9 条 × 2 物种 = 18 文件）

| 文件名 | UI 操作 | 动画描述 | 优先级 |
|--------|---------|----------|--------|
| `Action_Feed.mov` | 喂食 | 凑近食盆、大口吃 | **P0** |
| `Action_Snack.mov` | 零食 | 小口快吃、满足表情 | **P0** |
| `Action_Bath.mov` | 洗澡 | 被淋水、甩水、泡沫 | **P0** |
| `Action_Clean.mov` | 清理粪便 | 退后、捂鼻、主人清理后满意 | **P0** |
| `Action_Medicine.mov` | 喂药 | 抗拒→吞药→苦脸 | P1 |
| `Action_EatFinish.mov` | 吃完收尾 | 舔嘴、拍肚、满足 | P2 |

### 5.2 互动模块（P0–P1，3 条 × 2 物种 = 6 文件）

| 文件名 | UI 操作 | 动画描述 | 优先级 |
|--------|---------|----------|--------|
| `Action_Pet.mov` | 抚摸 | 蹭手、眯眼、呼噜/摇尾 | **P0** |
| `Action_Play.mov` | 玩耍 | 追球/扑 yarn、跳起 | **P0** |
| `Action_Apologize.mov` | 道歉 | 低头、蹭腿、和解 | P1 |

### 5.3 对话模块（P1，建议新增，4 条 × 2 物种 = 8 文件）

> 代码 V1 用模板对话；以下素材接入后可在 `PetAssetManager` 挂接。

| 文件名 | 场景 | 动画描述 | 优先级 |
|--------|------|----------|--------|
| `Action_Talk_Short.mov` | 词汇期 | 简单词嘴型+点头 | P1 |
| `Action_Talk_Full.mov` | 完整句 | 说话嘴型循环 2–3s | P1 |
| `Idle_Listening.mov` | 等主人输入 | 歪头、专注 | P2 |
| `Action_Memory_Recall.mov` | 回忆锚点 | 望天、开心回忆 | P2 |

### 5.4 生活助手模块（P1–P2，成熟期，6 条 × 2 物种 = 12 文件）

| 文件名 | 场景 | 动画描述 | 优先级 |
|--------|------|----------|--------|
| `Action_Alarm_Wake.mov` | 闹钟 | 扑向镜头、叫醒 | P1 |
| `Idle_Study_Companion.mov` | 自习陪伴 | 戴镜、趴桌、笔敲 | P1 |
| `Action_Study_Cheer.mov` | 完成目标 | 竖拇指/摇尾鼓励 | P2 |
| `Idle_Exercise_Companion.mov` | 健身陪伴 | 运动服、原地跑 | P1 |
| `Action_Exercise_Cheer.mov` | 打卡成功 | 跳跃庆祝 | P2 |
| `Action_Schedule_Nudge.mov` | 日程提醒 | 指日历、轻推 | P2 |

---

## 六、分阶段交付计划（建议）

### MVP 上线包（约 38 文件/物种，76 合计）

```
12 Idle（可先做 8 个 P0/P1，Normal/Happy/Hungry/Dirty/Sick 必做）
11 Normal_To_* 过渡
 6 Action（Feed, Snack, Bath, Clean, Pet, Play）
 1 背景 tuscany_day
---
猫 38 + 狗 38 = 76 个 .mov + 1~3 张背景
```

### V1.1 补全（+约 30 文件/物种）

```
+ 剩余 Idle（Angry, Cold, Sleeping, Reunion, Playing, Tired）
+ P1 过渡 16 条
+ Action_Medicine, Action_Apologize
+ 对话 2 条 + 助手 2 条
+ tuscany_dusk / tuscany_night
```

### V1.2  polish（按需）

```
+ 完整过渡矩阵热点对
+ 助手/对话剩余 Action
+ 背景微动 WebP
```

---

## 七、验收 Checklist（每文件）

- [ ] 文件名与上表**完全一致**（大小写、下划线）
- [ ] Alpha 通道正常，**无黑边/白边**
- [ ] Idle 循环无「跳帧/闪一下」
- [ ] Transition 与前后 Idle **衔接无瞬移**
- [ ] 时长：Idle **3–6 s/循环**；Action **1.5–3 s**；Transition **0.4–0.8 s**
- [ ] 放入 Xcode 后 `PetVideos/cat/` 可被 Bundle 读取

---

## 八、文件树模板（复制给美术）

```
PetVideos/
├── README.md
├── cat/
│   ├── Idle_Normal.mov
│   ├── Idle_Happy.mov
│   ├── Idle_Hungry.mov
│   ├── Idle_Dirty.mov
│   ├── Idle_Sick.mov
│   ├── Normal_To_Hungry.mov
│   ├── Normal_To_Happy.mov
│   ├── Normal_To_Dirty.mov
│   ├── Normal_To_Sick.mov
│   ├── Action_Feed.mov
│   ├── Action_Snack.mov
│   ├── Action_Bath.mov
│   ├── Action_Clean.mov
│   ├── Action_Pet.mov
│   └── Action_Play.mov
└── dog/
    └── （与 cat/ 同名）
```

---

## 九、数量汇总

| 类别 | P0 | P1 | P2 | 单物种合计（全做） |
|------|----|----|----|-------------------|
| Idle 循环 | 5 | 6 | 1 | 12 |
| Transition | 11 | 16 | ~105 | 132 |
| Action 生理+互动 | 6 | 2 | 1 | 9 |
| Action 对话 | 0 | 2 | 2 | 4 |
| Action 助手 | 0 | 3 | 3 | 6 |
| 背景图 | 1 | 2 | 0 | 3 |
| **MVP 必做/物种** | **~23 mov** | — | — | — |
| **推荐上线/物种** | — | **~+35 mov** | — | — |
| **猫+狗 MVP 合计** | **~46 mov** | | | |

---

## 十、与 App 状态机映射

```
PetSnapshot 数值变化
    → PetVisualStateResolver.resolve()
    → PetLoopState
    → 有过渡素材？播放 {From}_To_{To}.mov : 直接切 Idle
    → 循环 Idle_{State}.mov

用户点击底部模块按钮
    → perform(action, oneShot:)
    → 播放 Action_*.mov
    → 回到当前 Idle 循环
```

如有新动作，文件名须同步更新 `PetOneShotAction` / `PetSpecialLoop`（`PetAnimationCatalog.swift`）。

### 代码已预接入的 P1 对话/助手素材

| 类型 | 文件名 | 触发方式 |
|------|--------|----------|
| Action | `Action_Talk_Short` / `Action_Talk_Full` | 对话按钮（打招呼/安慰） |
| Action | `Action_Memory_Recall` | 对话「回忆」 |
| Idle | `Idle_Listening` | 无 Talk 素材时的降级 |
| Action | `Action_Alarm_Wake` | 助手「闹钟」 |
| Idle | `Idle_Study_Companion` | 助手「自习」 |
| Action | `Action_Study_Cheer` | 助手「完成」 |
| Idle | `Idle_Exercise_Companion` | 助手「运动」 |
| Action | `Action_Exercise_Cheer` | 助手「打卡」 |
| Action | `Action_Schedule_Nudge` | 助手日程（预留） |

---

**文档版本：** 1.0 · 与 EmoPet 工程命名一致  
**维护：** 新增动作/状态时，先改代码枚举，再更新本清单。
