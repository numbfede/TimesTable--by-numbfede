import json
from deep_translator import GoogleTranslator

# Target languages
languages = {
    "it": "it",
    "es": "es",
    "fr": "fr",
    "de": "de"
}

with open("TimesTable by numb/Localizable.xcstrings", "r") as f:
    data = json.load(f)

for key, item in data.get("strings", {}).items():
    if "localizations" not in item:
        item["localizations"] = {}
    
    for lang, code in languages.items():
        if lang not in item["localizations"]:
            try:
                translated = GoogleTranslator(source='auto', target=code).translate(key)
                item["localizations"][lang] = {
                    "stringUnit": {
                        "state": "translated",
                        "value": translated
                    }
                }
            except Exception as e:
                print(f"Failed {key} -> {lang}: {e}")

with open("TimesTable by numb/Localizable.xcstrings", "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Translations complete")
