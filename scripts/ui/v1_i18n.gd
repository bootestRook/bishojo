extends RefCounted
class_name V1I18n

# 文件职责：
# - V1 UI 文案的最小多语言预留层。
# - 当前默认语言为简体中文；后续新增语言时只扩展 translations，不改页面流程代码。
# - 本文件只处理显示文案，不保存、不推进任何玩法状态。

var language_code: String = "zh_cn"
var translations: Dictionary = {
	"zh_cn": {
		"language_name": "简体中文",
	}
}


func text(key: String, fallback: String = "") -> String:
	var table: Dictionary = translations.get(language_code, {})
	return table.get(key, fallback)


func set_language(new_language_code: String) -> void:
	if translations.has(new_language_code):
		language_code = new_language_code
