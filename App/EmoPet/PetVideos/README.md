# PetVideos 素材规范

将宠物视频放入 `cat/` 或 `dog/` 子目录，App 会自动加载并循环播放；缺失时降级为 SwiftUI 矢量宠物。

## 快速导入（推荐）

1. 把原始视频放在项目根目录的 `vido/` 文件夹（支持中文文件名，如 `猫视频.mov`、`狗视频.mov`）
2. 运行同步脚本：

```bash
bash Scripts/sync_pet_videos.sh
```

3. Xcode → Clean Build → 运行

也可以**直接把 .mov / .mp4 拖进** `App/EmoPet/PetVideos/cat/` 或 `dog/`，**文件名不必规范**——App 会自动扫描目录内任意视频。

## 规范命名（可选，便于多状态切换）

```
PetVideos/
  cat/
    Idle_Normal.mov          # 正常呼吸循环
    Idle_Hungry.mov
    Action_Feed.mov          # 喂食一次性动作
  dog/
    （同上）
```

## 导出要求

- 推荐：H.265 (HEVC) + Alpha 透明通道
- 也支持：H.264 .mov / .mp4（当前用户素材格式）
- 循环片段首尾帧尽量一致

## 背景图

Assets.xcassets：`tuscany_living_room_bg` / `tuscany_day` / `tuscany_dusk` / `tuscany_night`
