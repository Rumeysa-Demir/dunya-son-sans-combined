class_name FateCardConditionManager
extends RefCounted

func is_available(card: Dictionary, stats: Dictionary) -> bool:
	for condition in card.get("conditions", []):
		if not condition is Dictionary:
			continue
		var stat := str(condition.get("stat", ""))
		var operator := str(condition.get("operator", ">="))
		var target: float = float(condition.get("value", 0))
		var current: float = float(stats.get(stat, 0))
		if not _compare(current, operator, target):
			return false
	return true

func describe(card: Dictionary) -> String:
	var conditions: Array = card.get("conditions", [])
	if conditions.is_empty():
		return "Her şehir durumunda kullanılabilir"
	var pieces: Array[String] = []
	for condition in conditions:
		pieces.append("%s %s %s" % [
			FateCardModels.STAT_NAMES.get(str(condition.get("stat", "")), str(condition.get("stat", ""))),
			str(condition.get("operator", ">=")),
			str(condition.get("value", 0))
		])
	return "Koşul: " + ", ".join(pieces)

func _compare(current: float, operator: String, target: float) -> bool:
	match operator:
		">": return current > target
		">=": return current >= target
		"<": return current < target
		"<=": return current <= target
		"==": return is_equal_approx(current, target)
	return false
