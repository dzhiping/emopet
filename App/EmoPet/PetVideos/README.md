# PetVideos 素材规范

将 Blender 导出的 HEVC Alpha (.mov) 放入对应目录，App 会自动加载；缺失时降级为 SwiftUI 矢量宠物。

**完整制作清单见 → [ASSET_MANIFEST.md](./ASSET_MANIFEST.md)**（含 P0/P1/P2 优先级、猫狗全状态、四大模块、验收标准）  
**P0/P1 勾选表（Excel 可打开）→ [P0_MVP_CHECKLIST.csv](./P0_MVP_CHECKLIST.csv)**

## 目录结构

```
PetVideos/
  cat/
    Idle_Normal.mov          # 正常呼吸循环（首尾帧一致）
    Idle_Hungry.mov
    Idle_Happy.mov
    Normal_To_Hungry.mov     # 过渡，只播一次
    Action_Feed.mov          # 一次性动作
    ...
  dog/
    （同上）
```

## 导出要求

- 编码：H.265 (HEVC)，勾选 Export Alpha
- 容器：.mov（iOS 原生支持透明通道）
- 宠物层分辨率：约 800×800，透明背景
- 循环片段首尾帧必须完全一致

## 背景图

Assets.xcassets 中：
- tuscany_day / tuscany_dusk / tuscany_night（WebP 或 PNG，1920×1080 比例）
