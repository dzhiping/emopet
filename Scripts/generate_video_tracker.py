#!/usr/bin/env python3
"""生成 EmoPet 视频动画制作进度 Excel 表。"""

from __future__ import annotations

import os
from pathlib import Path

from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill, Border, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation

ROOT = Path(__file__).resolve().parents[1]
PET_VIDEOS = ROOT / "App/EmoPet/PetVideos"
OUTPUT = PET_VIDEOS / "VIDEO_ANIMATION_TRACKER.xlsx"

STATUS_OPTIONS = "待制作,制作中,已完成,已验收,跳过"
HEADER = [
    "序号",
    "优先级",
    "模块",
    "类别",
    "UI按钮/触发",
    "文件名",
    "播放类型",
    "建议时长",
    "动画描述",
    "解锁/触发条件",
    "猫-状态",
    "狗-状态",
    "负责人",
    "猫-完成日期",
    "狗-完成日期",
    "备注",
]

# (priority, module, category, ui, filename, loop_type, duration, desc, unlock, notes)
ROWS = [
    # —— P0 Idle ——
    ("P0", "自动/通用", "Idle循环", "数值驱动自动切换", "Idle_Normal.mov", "循环", "3-6秒", "正常呼吸、眨眼、轻微摇尾/竖耳", "默认健康状态", "最重要；缺省回退素材"),
    ("P0", "自动/通用", "Idle循环", "数值驱动", "Idle_Happy.mov", "循环", "3-6秒", "开心：猫踩奶/狗摇尾", "心情=开心", ""),
    ("P0", "生理", "Idle循环", "数值驱动", "Idle_Hungry.mov", "循环", "3-6秒", "饥饿趴下、望食盆", "饱腹<40", ""),
    ("P0", "生理", "Idle循环", "数值驱动", "Idle_Dirty.mov", "循环", "3-6秒", "脏、闻身上、嫌弃", "有粪便或清洁<40", ""),
    ("P0", "生理", "Idle循环", "数值驱动", "Idle_Sick.mov", "循环", "3-6秒", "生病虚弱、贴退热贴", "生病/治疗中", ""),
    ("P1", "生理", "Idle循环", "数值驱动", "Idle_Tired.mov", "循环", "3-6秒", "打盹、半闭眼", "略饿+委屈", ""),
    ("P1", "互动", "Idle循环", "数值驱动", "Idle_Angry.mov", "循环", "3-6秒", "背对、炸毛/低吼", "心情=生气", ""),
    ("P1", "互动", "Idle循环", "数值驱动", "Idle_Cold.mov", "循环", "3-6秒", "蜷缩、不理人", "心情=冷淡", ""),
    ("P1", "生理", "Idle循环", "数值驱动", "Idle_Sleeping.mov", "循环", "3-6秒", "闭眼睡觉、轻呼吸", "离线48h+睡眠模式", ""),
    ("P1", "互动", "Idle循环", "数值驱动", "Idle_Reunion.mov", "循环", "3-6秒", "久别后睁眼、靠近", "主人久未打开App", ""),
    ("P1", "互动", "Idle循环", "数值驱动", "Idle_Playing.mov", "循环", "3-6秒", "扑腾、叼玩具", "高亲密/玩耍后", ""),
    ("P2", "生理", "Idle循环", "数值驱动", "Idle_Eating.mov", "循环", "3-6秒", "低头咀嚼", "进食中(可选)", ""),
    # —— P0 Transition from Normal ——
    ("P0", "自动/通用", "状态过渡", "状态切换时", "Normal_To_Happy.mov", "单次", "0.4-0.8秒", "正常→开心", "有Happy Idle时", "首帧=Normal尾帧"),
    ("P0", "自动/通用", "状态过渡", "状态切换时", "Normal_To_Hungry.mov", "单次", "0.4-0.8秒", "正常→饥饿", "", ""),
    ("P0", "自动/通用", "状态过渡", "状态切换时", "Normal_To_Dirty.mov", "单次", "0.4-0.8秒", "正常→脏", "", ""),
    ("P0", "自动/通用", "状态过渡", "状态切换时", "Normal_To_Sick.mov", "单次", "0.4-0.8秒", "正常→生病", "", ""),
    ("P1", "自动/通用", "状态过渡", "状态切换时", "Normal_To_Tired.mov", "单次", "0.4-0.8秒", "正常→疲惫", "", ""),
    ("P1", "自动/通用", "状态过渡", "状态切换时", "Normal_To_Angry.mov", "单次", "0.4-0.8秒", "正常→生气", "", ""),
    ("P1", "自动/通用", "状态过渡", "状态切换时", "Normal_To_Cold.mov", "单次", "0.4-0.8秒", "正常→冷淡", "", ""),
    ("P1", "自动/通用", "状态过渡", "状态切换时", "Normal_To_Sleeping.mov", "单次", "0.4-0.8秒", "正常→睡眠", "", ""),
    ("P1", "自动/通用", "状态过渡", "状态切换时", "Normal_To_Reunion.mov", "单次", "0.4-0.8秒", "正常→重逢", "", ""),
    ("P1", "自动/通用", "状态过渡", "状态切换时", "Normal_To_Playing.mov", "单次", "0.4-0.8秒", "正常→玩耍", "", ""),
    ("P2", "自动/通用", "状态过渡", "状态切换时", "Normal_To_Eating.mov", "单次", "0.4-0.8秒", "正常→进食", "", ""),
    # —— P0 Actions 生理+互动 ——
    ("P0", "生理", "点击动作", "🍴 正餐/喂食", "Action_Feed.mov", "单次", "1.5-3秒", "凑近食盆、大口吃", "Tab生理", "代码已接入"),
    ("P0", "生理", "点击动作", "🥕 零食", "Action_Snack.mov", "单次", "1.5-3秒", "小口快吃", "Tab生理", "代码已接入"),
    ("P0", "生理", "点击动作", "🚿 洗澡", "Action_Bath.mov", "单次", "1.5-3秒", "淋水、甩水、泡沫", "Tab生理", "代码已接入"),
    ("P0", "生理", "点击动作", "🗑️ 清理粪便", "Action_Clean.mov", "单次", "1.5-3秒", "退后、清理后满意", "Tab生理", "代码已接入"),
    ("P0", "互动", "点击动作", "👋 抚摸", "Action_Pet.mov", "单次", "1.5-3秒", "蹭手、眯眼", "Tab互动", "代码已接入"),
    ("P0", "互动", "点击动作", "🎮 玩耍", "Action_Play.mov", "单次", "1.5-3秒", "追球、扑玩具", "Tab互动", "代码已接入"),
    ("P1", "生理", "点击动作", "💊 喂药", "Action_Medicine.mov", "单次", "1.5-3秒", "抗拒→吞药→苦脸", "生病时出现", "代码已接入"),
    ("P1", "互动", "点击动作", "❤️ 道歉", "Action_Apologize.mov", "单次", "1.5-3秒", "低头、蹭腿和解", "宠物生气时出现", "代码已接入"),
    ("P2", "生理", "点击动作", "吃完收尾", "Action_EatFinish.mov", "单次", "1.5-3秒", "舔嘴、拍肚", "喂食后(可选)", "代码已接入"),
    # —— P1 对话 ——
    ("P1", "对话", "点击动作", "💬 打招呼/🍃 安慰", "Action_Talk_Short.mov", "单次", "1.5-3秒", "词汇期说话嘴型", "亲密度≥60", "代码已接入"),
    ("P1", "对话", "点击动作", "💬 打招呼/🍃 安慰", "Action_Talk_Full.mov", "单次", "2-4秒", "完整句说话", "完整句对话期", "代码已接入"),
    ("P2", "对话", "点击动作", "🕐 回忆", "Action_Memory_Recall.mov", "单次", "2-3秒", "望天、开心回忆", "Tab对话", "代码已接入"),
    ("P2", "对话", "场景循环", "对话降级/倾听", "Idle_Listening.mov", "循环", "3-5秒", "歪头、专注倾听", "无Talk素材时", "代码已接入"),
    # —— P1 助手 ——
    ("P1", "助手", "点击动作", "⏰ 闹钟", "Action_Alarm_Wake.mov", "单次", "2-3秒", "扑向镜头叫醒", "成熟期+亲密度≥85", "代码已接入"),
    ("P1", "助手", "场景循环", "📖 自习", "Idle_Study_Companion.mov", "循环", "3-6秒", "趴桌、敲笔", "Tab助手", "代码已接入"),
    ("P2", "助手", "点击动作", "✅ 学习完成", "Action_Study_Cheer.mov", "单次", "1.5-3秒", "竖拇指鼓励", "Tab助手", "代码已接入"),
    ("P1", "助手", "场景循环", "🏃 运动", "Idle_Exercise_Companion.mov", "循环", "3-6秒", "原地跑、运动服", "Tab助手", "代码已接入"),
    ("P2", "助手", "点击动作", "运动打卡", "Action_Exercise_Cheer.mov", "单次", "1.5-3秒", "跳跃庆祝", "预留", "代码已接入"),
    ("P2", "助手", "点击动作", "日程提醒", "Action_Schedule_Nudge.mov", "单次", "1.5-3秒", "指日历、轻推", "预留", "代码已接入"),
    # —— P1 高频过渡 ——
    ("P1", "自动/通用", "状态过渡", "状态切换", "Hungry_To_Normal.mov", "单次", "0.4-0.8秒", "饥饿→正常", "喂食后", ""),
    ("P1", "自动/通用", "状态过渡", "状态切换", "Dirty_To_Normal.mov", "单次", "0.4-0.8秒", "脏→正常", "洗澡/清理后", ""),
    ("P1", "自动/通用", "状态过渡", "状态切换", "Sick_To_Normal.mov", "单次", "0.4-0.8秒", "生病→正常", "康复后", ""),
    ("P1", "自动/通用", "状态过渡", "状态切换", "Happy_To_Normal.mov", "单次", "0.4-0.8秒", "开心→正常", "", ""),
    ("P1", "自动/通用", "状态过渡", "状态切换", "Angry_To_Normal.mov", "单次", "0.4-0.8秒", "生气→正常", "道歉后", ""),
    ("P1", "自动/通用", "状态过渡", "状态切换", "Reunion_To_Happy.mov", "单次", "0.4-0.8秒", "重逢→开心", "点击重逢按钮后", ""),
    # —— 背景 ——
    ("P0", "场景", "背景图", "自动", "tuscany_living_room_bg", "静态", "-", "托斯卡纳客厅全屏背景", "Assets.xcassets", "PNG/WebP"),
    ("P1", "场景", "背景图", "时段切换", "tuscany_day", "静态", "-", "白天客厅", "6:00-17:00", "Assets.xcassets"),
    ("P1", "场景", "背景图", "时段切换", "tuscany_dusk", "静态", "-", "黄昏", "17:00-20:00", "Assets.xcassets"),
    ("P1", "场景", "背景图", "时段切换", "tuscany_night", "静态", "-", "夜晚", "20:00-6:00", "Assets.xcassets"),
]


def existing_files() -> dict[str, set[str]]:
    found: dict[str, set[str]] = {"cat": set(), "dog": set()}
    for species in ("cat", "dog"):
        folder = PET_VIDEOS / species
        if not folder.is_dir():
            continue
        for path in folder.iterdir():
            if path.suffix.lower() in {".mov", ".mp4"}:
                found[species].add(path.name)
    return found


def auto_status(filename: str, species: str, existing: dict[str, set[str]]) -> str:
    if filename.endswith((".png", ".webp")) or "tuscany" in filename:
        return "待制作"
    if filename in existing[species]:
        return "已完成"
    return "待制作"


def style_header(ws) -> None:
    header_fill = PatternFill("solid", fgColor="4A6741")
    header_font = Font(bold=True, color="FFFFFF", size=11)
    thin = Side(style="thin", color="CCCCCC")
    border = Border(left=thin, right=thin, top=thin, bottom=thin)
    for col, title in enumerate(HEADER, start=1):
        cell = ws.cell(row=1, column=col, value=title)
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        cell.border = border
    ws.row_dimensions[1].height = 32
    ws.freeze_panes = "A2"
    ws.auto_filter.ref = f"A1:{get_column_letter(len(HEADER))}1"


def build_main_sheet(wb: Workbook, existing: dict[str, set[str]]) -> None:
    ws = wb.active
    ws.title = "动画制作进度"
    style_header(ws)

    dv = DataValidation(type="list", formula1=f'"{STATUS_OPTIONS}"', allow_blank=True)
    ws.add_data_validation(dv)

    priority_fills = {
        "P0": PatternFill("solid", fgColor="FFE8CC"),
        "P1": PatternFill("solid", fgColor="E8F4FF"),
        "P2": PatternFill("solid", fgColor="F2F2F2"),
    }
    thin = Side(style="thin", color="E0E0E0")
    border = Border(left=thin, right=thin, top=thin, bottom=thin)

    for idx, row in enumerate(ROWS, start=1):
        r = idx + 1
        priority, module, category, ui, filename, loop_type, duration, desc, unlock, notes = row
        cat_status = auto_status(filename, "cat", existing)
        dog_status = auto_status(filename, "dog", existing)

        values = [
            idx,
            priority,
            module,
            category,
            ui,
            filename,
            loop_type,
            duration,
            desc,
            unlock,
            cat_status,
            dog_status,
            "",
            "",
            "",
            notes,
        ]
        for col, val in enumerate(values, start=1):
            cell = ws.cell(row=r, column=col, value=val)
            cell.border = border
            cell.alignment = Alignment(vertical="top", wrap_text=True)
            if col in (11, 12):
                dv.add(cell)
            if col == 2 and priority in priority_fills:
                cell.fill = priority_fills[priority]

    widths = [5, 6, 10, 10, 18, 28, 8, 10, 28, 18, 10, 10, 10, 12, 12, 24]
    for i, w in enumerate(widths, start=1):
        ws.column_dimensions[get_column_letter(i)].width = w


def build_summary_sheet(wb: Workbook) -> None:
    ws = wb.create_sheet("按优先级汇总")
    ws.append(["优先级", "说明", "条目数", "猫已完成", "狗已完成"])
    counts: dict[str, list[int]] = {}
    existing = existing_files()
    for row in ROWS:
        p = row[0]
        filename = row[5]
        counts.setdefault(p, [0, 0, 0])
        counts[p][0] += 1
        if auto_status(filename, "cat", existing) == "已完成":
            counts[p][1] += 1
        if auto_status(filename, "dog", existing) == "已完成":
            counts[p][2] += 1

    desc = {
        "P0": "MVP必做：核心Idle+6动作+关键过渡",
        "P1": "体验完整：剩余Idle/过渡/对话助手",
        "P2": "锦上添花：可选动作与背景",
    }
    for p in ("P0", "P1", "P2"):
        c, cat_done, dog_done = counts.get(p, [0, 0, 0])
        ws.append([p, desc.get(p, ""), c, cat_done, dog_done])

    ws.append([])
    ws.append(["模块", "条目数"])
    module_counts: dict[str, int] = {}
    for row in ROWS:
        module_counts[row[1]] = module_counts.get(row[1], 0) + 1
    for mod, c in sorted(module_counts.items(), key=lambda x: -x[1]):
        ws.append([mod, c])

    ws.column_dimensions["A"].width = 14
    ws.column_dimensions["B"].width = 40
    ws.column_dimensions["C"].width = 10


def build_guide_sheet(wb: Workbook) -> None:
    ws = wb.create_sheet("使用说明")
    lines = [
        ["EmoPet 视频动画制作进度表"],
        [],
        ["状态字段", "说明"],
        ["待制作", "尚未开始"],
        ["制作中", "正在渲染/导出"],
        ["已完成", "文件已放入 PetVideos/cat 或 dog"],
        ["已验收", "已在 App 内测试通过"],
        ["跳过", "本期不做"],
        [],
        ["文件放置路径"],
        ["猫", "App/EmoPet/PetVideos/cat/文件名.mov"],
        ["狗", "App/EmoPet/PetVideos/dog/文件名.mov"],
        [],
        ["导入命令", "bash Scripts/sync_pet_videos.sh"],
        [],
        ["技术建议", "HEVC+Alpha .mov；Idle首尾帧一致；Action 1.5-3秒"],
        ["详细规范", "见 ASSET_MANIFEST.md"],
    ]
    for line in lines:
        ws.append(line)
    ws.column_dimensions["A"].width = 16
    ws.column_dimensions["B"].width = 60
    ws["A1"].font = Font(bold=True, size=14)


def main() -> None:
    existing = existing_files()
    wb = Workbook()
    build_main_sheet(wb, existing)
    build_summary_sheet(wb)
    build_guide_sheet(wb)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    wb.save(OUTPUT)
    print(f"Wrote {OUTPUT}")
    print(f"Existing cat: {sorted(existing['cat'])}")
    print(f"Existing dog: {sorted(existing['dog'])}")


if __name__ == "__main__":
    main()
