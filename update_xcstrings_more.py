import json

path = "/Users/nosaywanan/VSCode Projects/boring.notch/boringNotch/Localizable.xcstrings"

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

translations = {
    "Copy": "复制",
    "Remove": "移除"
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
    
    if "en" not in data["strings"][key]["localizations"]:
        data["strings"][key]["localizations"]["en"] = {
            "stringUnit": {
                "state": "translated",
                "value": key
            }
        }

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("More translations added successfully!")
