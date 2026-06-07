#!/bin/bash
# 将项目中的宠物视频同步到 App Bundle 目录
# 用法：在项目根目录执行  bash Scripts/sync_pet_videos.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$ROOT/vido"
CAT_DIR="$ROOT/App/EmoPet/PetVideos/cat"
DOG_DIR="$ROOT/App/EmoPet/PetVideos/dog"

mkdir -p "$CAT_DIR" "$DOG_DIR"

copy_if_exists() {
  local src="$1" dest="$2"
  if [[ -f "$src" ]]; then
    cp -f "$src" "$dest"
    echo "✓ $(basename "$dest") ← $(basename "$src")"
    return 0
  fi
  return 1
}

echo "=== EmoPet 视频同步 ==="
echo "源目录: $SRC_DIR"
echo ""

# 规范命名映射（优先）
copy_if_exists "$SRC_DIR/生成猫视频.mov" "$CAT_DIR/Idle_Normal.mov" || true
copy_if_exists "$SRC_DIR/猫视频.mov"       "$CAT_DIR/Idle_Happy.mov" || \
copy_if_exists "$SRC_DIR/猫视频.mov"       "$CAT_DIR/Idle_Normal.mov" || true
copy_if_exists "$SRC_DIR/狗视频.mov"       "$DOG_DIR/Idle_Normal.mov" || true
copy_if_exists "$SRC_DIR/生成2 (1).5D视频.mov" "$DOG_DIR/Idle_Happy.mov" || true

# 兜底：把 vido 里所有 mov/mp4 按文件名关键词分发
shopt -s nullglob
for f in "$SRC_DIR"/*.{mov,mp4,MOV,MP4}; do
  [[ -f "$f" ]] || continue
  base="$(basename "$f")"
  if [[ "$base" == *猫* ]]; then
    if [[ ! -f "$CAT_DIR/Idle_Normal.mov" ]]; then
      cp -f "$f" "$CAT_DIR/Idle_Normal.mov"
      echo "✓ cat/Idle_Normal.mov ← $base"
    elif [[ ! -f "$CAT_DIR/Idle_Happy.mov" ]]; then
      cp -f "$f" "$CAT_DIR/Idle_Happy.mov"
      echo "✓ cat/Idle_Happy.mov ← $base"
    else
      cp -f "$f" "$CAT_DIR/$base"
      echo "✓ cat/$base"
    fi
  elif [[ "$base" == *狗* ]]; then
    if [[ ! -f "$DOG_DIR/Idle_Normal.mov" ]]; then
      cp -f "$f" "$DOG_DIR/Idle_Normal.mov"
      echo "✓ dog/Idle_Normal.mov ← $base"
    else
      cp -f "$f" "$DOG_DIR/$base"
      echo "✓ dog/$base"
    fi
  fi
done

echo ""
echo "当前 Bundle 视频："
find "$CAT_DIR" "$DOG_DIR" -type f \( -iname '*.mov' -o -iname '*.mp4' \) -print 2>/dev/null || echo "(暂无视频文件)"
echo ""
echo "完成。请在 Xcode 中 Clean Build 后运行。"
