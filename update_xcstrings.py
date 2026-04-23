import json

path = "/Users/nosaywanan/VSCode Projects/boring.notch/boringNotch/Localizable.xcstrings"

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

translations = {
    "Clipboard": "剪贴板",
    "Clear all": "清除全部",
    "No clipboard history": "暂无剪贴板历史",
    "Copied text will appear here": "复制的内容将显示在这里",
    "Just now": "刚刚",
    "%.0fs ago": "%.0f秒前",
    "%dm ago": "%d分钟前",
    "%dh ago": "%d小时前",
    "Enable clipboard history": "启用剪贴板历史",
    "Monitors the system clipboard and keeps a history of copied items accessible from the notch.": "监控系统剪贴板，并在 Notch 中保留复制项目的历史记录。",
    "Show clipboard tab in notch": "在 Notch 中显示剪贴板选项卡",
    "Maximum history items": "最大历史记录条数",
    "Clipboard history is stored in memory and cleared when the app quits.": "剪贴板历史记录存储在内存中，并在退出应用时清空。",
    "Items in history": "历史记录条数",
    "Clear clipboard history": "清除剪贴板历史记录",
    "History": "历史记录"
}

for key, zh_trans in translations.items():
    if key not in data["strings"]:
        data["strings"][key] = {
            "localizations": {
                "en": {
                    "stringUnit": {
                        "state": "translated",
                        "value": key
                    }
                }
            }
        }
    
    if "localizations" not in data["strings"][key]:
        data["strings"][key]["localizations"] = {}
        
    data["strings"][key]["localizations"]["zh-Hans"] = {
        "stringUnit": {
            "state": "translated",
            "value": zh_trans
        }
    }
    
    # Also mark as translated for en if it's new or not translated
    if "en" not in data["strings"][key]["localizations"]:
        data["strings"][key]["localizations"]["en"] = {
            "stringUnit": {
                "state": "translated",
                "value": key
            }
        }

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Translation added successfully!")
